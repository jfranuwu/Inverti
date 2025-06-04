//lib\providers\auth_provider.dart
// Provider para gestión de autenticación con limpieza mejorada de otros providers

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../config/firebase_config.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  bool _mounted = true;
  bool _isSigningOut = false;
  
  // Referencias a otros providers para limpieza
  dynamic _chatProvider;
  dynamic _projectProvider;
  dynamic _notificationService;
  
  StreamSubscription<User?>? _authStateSubscription;
  
  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && !_isSigningOut;
  bool get mounted => _mounted;
  bool get isSigningOut => _isSigningOut;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  
  AuthProvider() {
    _initializeAuthListener();
  }
  
  // Registrar otros providers para limpieza en logout
  void registerProvidersForCleanup({
    dynamic chatProvider,
    dynamic projectProvider,
    dynamic notificationService,
  }) {
    _chatProvider = chatProvider;
    _projectProvider = projectProvider;
    _notificationService = notificationService;
    debugPrint('✅ Providers registrados para limpieza en logout');
  }
  
  // Inicializar listener de autenticación
  void _initializeAuthListener() {
    _authStateSubscription?.cancel();
    
    debugPrint('🎧 Inicializando auth state listener...');
    
    _authStateSubscription = _auth.authStateChanges().listen(
      _onAuthStateChanged,
      onError: (error) {
        debugPrint('❌ Error en auth state listener: $error');
        
        if (!_isSigningOut) {
          _error = 'Error de autenticación: $error';
          if (_mounted) {
            notifyListeners();
          }
        }
      },
    );
  }
  
  @override
  void dispose() {
    debugPrint('🧹 AuthProvider dispose() llamado');
    _mounted = false;
    _authStateSubscription?.cancel();
    super.dispose();
  }
  
  // Manejar cambios de estado de autenticación
  Future<void> _onAuthStateChanged(User? user) async {
    if (_isSigningOut || !_mounted || _authStateSubscription == null) {
      debugPrint('🚫 Saltando auth state change: isSigningOut=$_isSigningOut, mounted=$_mounted, hasListener=${_authStateSubscription != null}');
      return;
    }
    
    debugPrint('🔄 Auth state changed: ${user?.uid}, emailVerified: ${user?.emailVerified}');
    
    if (_user?.uid != user?.uid) {
      _user = user;
      
      if (user != null) {
        try {
          await _loadUserData(user.uid);
          
          if (!_isSigningOut && _mounted) {
            await _setupFCMForUser(user.uid);
          }
        } catch (e) {
          debugPrint('❌ Error cargando datos en auth change: $e');
          
          if (!_isSigningOut) {
            _error = 'Error al cargar datos del usuario: $e';
          }
        }
      } else {
        _userModel = null;
      }
      
      if (_mounted && !_isSigningOut) {
        notifyListeners();
      }
    }
  }
  
  // Cargar datos del usuario desde Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      debugPrint('📖 Cargando datos de usuario: $uid');
      final doc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(uid)
          .get();
      
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
        debugPrint('✅ UserModel cargado: ${_userModel?.name}, tipo: ${_userModel?.userType}');
      } else {
        debugPrint('⚠️ Documento de usuario no encontrado');
      }
    } catch (e) {
      debugPrint('❌ Error cargando datos de usuario: $e');
      _error = 'Error al cargar datos del usuario: $e';
    }
    
    if (_mounted && !_isSigningOut) {
      notifyListeners();
    }
  }
  
  // Configurar FCM para el usuario
  Future<void> _setupFCMForUser(String userId) async {
    if (_isSigningOut || !_mounted) return;
    
    try {
      debugPrint('🔔 Configurando FCM para usuario: $userId');
      
      if (!FCMService().isInitialized) {
        debugPrint('⚠️ FCM Service no está inicializado, saltando configuración');
        return;
      }
      
      await FCMService().saveTokenAfterLogin(userId);
      
      if (_userModel?.userType == 'investor') {
        await FCMService().subscribeToTopic('new_projects');
        await FCMService().unsubscribeFromTopic('investor_interest');
        debugPrint('✅ Inversor suscrito a nuevos proyectos');
      } else if (_userModel?.userType == 'entrepreneur') {
        await FCMService().subscribeToTopic('investor_interest');
        await FCMService().unsubscribeFromTopic('new_projects');
        debugPrint('✅ Emprendedor suscrito a interés de inversores');
      }
    } catch (e) {
      debugPrint('❌ Error configurando FCM: $e');
    }
  }
  
  // Registro con email y contraseña
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    if (_isSigningOut) return false;
    
    try {
      _isLoading = true;
      _error = null;
      if (_mounted) notifyListeners();
      
      debugPrint('Starting registration for: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        debugPrint('User created with UID: ${credential.user!.uid}');
        
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          name: name.trim(),
          userType: userType,
          createdAt: DateTime.now(),
        );
        
        await _firestore
            .collection(FirebaseConfig.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());
        
        debugPrint('User saved to Firestore');
        
        if (_mounted && !_isSigningOut) {
          await _setupFCMForUser(credential.user!.uid);
        }
        
        try {
          await credential.user!.sendEmailVerification();
          debugPrint('Verification email sent');
        } catch (e) {
          debugPrint('Error sending verification email: $e');
        }
        
        _userModel = userModel;
        _isLoading = false;
        if (_mounted) notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      _error = _handleAuthError(e);
    } catch (e) {
      debugPrint('General error during registration: $e');
      _error = 'Error en el registro: $e';
    }
    
    _isLoading = false;
    if (_mounted) notifyListeners();
    return false;
  }
  
  // Inicio de sesión con email y contraseña
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isSigningOut) return 'error';
    
    try {
      _isLoading = true;
      _error = null;
      if (_mounted) notifyListeners();
      
      debugPrint('Signing in with email: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        debugPrint('Sign in successful: ${credential.user!.uid}');
        debugPrint('Email verified: ${credential.user!.emailVerified}');
        
        _isLoading = false;
        if (_mounted) notifyListeners();
        
        if (!credential.user!.emailVerified) {
          debugPrint('⚠️ Email no verificado, requiere verificación');
          return 'email_not_verified';
        }
        
        return 'success';
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      _error = _handleAuthError(e);
    } catch (e) {
      debugPrint('General error during sign in: $e');
      _error = 'Error en el inicio de sesión: $e';
    }
    
    _isLoading = false;
    if (_mounted) notifyListeners();
    return 'error';
  }
  
  // Inicio de sesión con Google
  Future<bool> signInWithGoogle() async {
    if (_isSigningOut) return false;
    
    try {
      _isLoading = true;
      _error = null;
      if (_mounted) notifyListeners();
      
      debugPrint('Starting Google Sign In...');
      
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign In cancelled by user');
        _isLoading = false;
        if (_mounted) notifyListeners();
        return false;
      }
      
      debugPrint('Google user: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        debugPrint('Firebase sign in successful: ${userCredential.user!.uid}');
        
        final doc = await _firestore
            .collection(FirebaseConfig.usersCollection)
            .doc(userCredential.user!.uid)
            .get();
        
        if (!doc.exists) {
          debugPrint('Creating new user document in Firestore');
          final userModel = UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? '',
            photoURL: userCredential.user!.photoURL,
            userType: '',
            createdAt: DateTime.now(),
          );
          
          await _firestore
              .collection(FirebaseConfig.usersCollection)
              .doc(userCredential.user!.uid)
              .set(userModel.toFirestore());
              
          _userModel = userModel;
          debugPrint('New user model created and loaded');
        } else {
          _userModel = UserModel.fromFirestore(doc);
          debugPrint('Existing user model loaded');
        }
        
        if (_mounted && !_isSigningOut) {
          await _setupFCMForUser(userCredential.user!.uid);
        }
        
        _isLoading = false;
        if (_mounted) notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error with Google Sign-In: $e');
      _error = 'Error con Google Sign-In: $e';
    }
    
    _isLoading = false;
    if (_mounted) notifyListeners();
    return false;
  }
  
  // Actualizar tipo de usuario (rol)
  Future<bool> updateUserType(String userType) async {
    if (_user == null || _isSigningOut) {
      debugPrint('Error: No hay usuario autenticado o estamos en logout');
      _error = 'No hay usuario autenticado';
      return false;
    }
    
    if (_userModel == null) {
      debugPrint('UserModel es null, intentando cargar...');
      await _loadUserData(_user!.uid);
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_userModel == null) {
        debugPrint('No se pudo cargar el modelo de usuario');
        _error = 'No se pudo cargar la información del usuario';
        return false;
      }
    }
    
    try {
      _isLoading = true;
      if (_mounted) notifyListeners();
      
      debugPrint('Updating user type to: $userType for user: ${_user!.uid}');
      
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(_user!.uid)
          .update({'userType': userType});
      
      _userModel = _userModel!.copyWith(userType: userType);
      
      debugPrint('User type updated successfully in both Firestore and local model');
      
      if (_mounted && !_isSigningOut) {
        await _setupFCMForUser(_user!.uid);
      }
      
      _isLoading = false;
      if (_mounted) notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user type: $e');
      _error = 'Error al actualizar el tipo de usuario: $e';
      _isLoading = false;
      if (_mounted) notifyListeners();
      return false;
    }
  }
  
  // Limpiar otros providers de manera robusta
  Future<void> _clearOtherProviders() async {
    try {
      debugPrint('🧹 Limpiando otros providers...');
      
      final List<Future<void>> cleanupTasks = [];
      
      if (_chatProvider != null && _chatProvider.clearUserData != null) {
        cleanupTasks.add(
          Future(() => _chatProvider.clearUserData())
            .timeout(const Duration(seconds: 3))
            .catchError((e) {
              debugPrint('⚠️ Error limpiando ChatProvider: $e');
              return null;
            })
        );
      }
      
      if (_projectProvider != null && _projectProvider.clearOnLogout != null) {
        cleanupTasks.add(
          Future(() => _projectProvider.clearOnLogout())
            .timeout(const Duration(seconds: 2))
            .catchError((e) {
              debugPrint('⚠️ Error limpiando ProjectProvider: $e');
              return null;
            })
        );
      }
      
      if (_notificationService != null && _notificationService.clearOnLogout != null) {
        cleanupTasks.add(
          Future(() => _notificationService.clearOnLogout())
            .timeout(const Duration(seconds: 2))
            .catchError((e) {
              debugPrint('⚠️ Error limpiando NotificationService: $e');
              return null;
            })
        );
      }
      
      if (cleanupTasks.isNotEmpty) {
        await Future.wait(cleanupTasks).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⚠️ Timeout en limpieza de providers - continuando logout');
            return [];
          },
        );
      }
      
      debugPrint('✅ Limpieza de providers completada');
      
    } catch (e) {
      debugPrint('⚠️ Error limpiando providers (no crítico): $e');
    }
  }
  
  // Logout con secuencia corregida
  Future<void> signOut() async {
    if (_isSigningOut) {
      debugPrint('⚠️ Logout ya en progreso, ignorando...');
      return;
    }
    
    _isSigningOut = true;

    try {
      debugPrint('🚪 Iniciando logout seguro...');
      
      // Cancelar listener inmediatamente
      await _authStateSubscription?.cancel();
      _authStateSubscription = null;
      
      // Limpiar otros providers antes del auth logout
      await _clearOtherProviders();
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Limpiar FCM de forma segura
      await _safeFCMCleanup();
      
      // Limpiar estado local antes del logout de Firebase
      _user = null;
      _userModel = null;
      _error = null;
      _isLoading = false;
      
      // Hacer logout de servicios
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      debugPrint('✅ Logout completado exitosamente');
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (_mounted) {
        _initializeAuthListener();
      }
      
    } catch (e) {
      debugPrint('❌ Error durante logout: $e');
      _error = 'Error al cerrar sesión: $e';
      
      if (_mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        _initializeAuthListener();
      }
    } finally {
      _isSigningOut = false;
      
      if (_mounted) {
        notifyListeners();
      }
    }
  }
  
  // Limpieza segura de FCM durante logout
  Future<void> _safeFCMCleanup() async {
    try {
      debugPrint('🧹 Iniciando limpieza segura de FCM...');
      
      if (!FCMService().isInitialized) {
        debugPrint('⚠️ FCM Service no inicializado, saltando limpieza');
        return;
      }
      
      await Future.wait([
        FCMService().clearTokenOnLogout(),
        FCMService().unsubscribeFromTopic('new_projects'),
        FCMService().unsubscribeFromTopic('investor_interest'),
      ]).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⚠️ Timeout en limpieza FCM - continuando logout');
          return [];
        },
      );
      
      debugPrint('✅ Limpieza FCM completada');
      
    } catch (e) {
      debugPrint('⚠️ Error en limpieza FCM (no crítico): $e');
    }
  }
  
  // Enviar email de recuperación de contraseña
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _error = null;
      if (_mounted) notifyListeners();
      
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      _isLoading = false;
      if (_mounted) notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
    } catch (e) {
      _error = 'Error al enviar email: $e';
    }
    
    _isLoading = false;
    if (_mounted) notifyListeners();
    return false;
  }
  
  // Reenviar email de verificación
  Future<bool> resendVerificationEmail() async {
    try {
      if (_user != null && !_user!.emailVerified) {
        await _user!.sendEmailVerification();
        debugPrint('✅ Email de verificación reenviado');
        return true;
      } else {
        debugPrint('⚠️ Usuario no disponible o ya verificado');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error al reenviar email de verificación: $e');
      _error = 'Error al reenviar email de verificación: $e';
      if (_mounted) notifyListeners();
    }
    return false;
  }
  
  // Actualizar foto de perfil
  Future<bool> updateProfilePhoto(String photoURL) async {
    if (_user == null || _isSigningOut) return false;
    
    try {
      _isLoading = true;
      if (_mounted) notifyListeners();
      
      if (_user!.providerData.any((info) => info.providerId == 'password')) {
        await _user!.updatePhotoURL(photoURL);
      }
      
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(_user!.uid)
          .update({'photoURL': photoURL});
      
      _userModel = _userModel?.copyWith(photoURL: photoURL);
      
      _isLoading = false;
      if (_mounted) notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar foto: $e';
      _isLoading = false;
      if (_mounted) notifyListeners();
      return false;
    }
  }
  
  // Manejar errores de autenticación
  String _handleAuthError(FirebaseAuthException e) {
    debugPrint('Handling auth error: ${e.code}');
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'El email ya está registrado';
      case 'invalid-email':
        return 'El email no es válido';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
  
  // Limpiar error
  void clearError() {
    _error = null;
    if (_mounted) notifyListeners();
  }
  
  // Obtener token FCM del usuario actual
  Future<String?> getCurrentUserFCMToken() async {
    if (_user != null && !_isSigningOut) {
      try {
        final doc = await _firestore
            .collection(FirebaseConfig.usersCollection)
            .doc(_user!.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          return data['fcmToken'] as String?;
        }
      } catch (e) {
        debugPrint('Error obteniendo token FCM: $e');
      }
    }
    return null;
  }
  
  // Actualizar información del usuario
  Future<bool> updateUserInfo({
    String? name,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_user == null || _isSigningOut) return false;
    
    try {
      _isLoading = true;
      if (_mounted) notifyListeners();
      
      final updateData = <String, dynamic>{};
      
      if (name != null) {
        updateData['name'] = name;
        await _user!.updateDisplayName(name);
      }
      
      if (photoURL != null) {
        updateData['photoURL'] = photoURL;
        if (_user!.providerData.any((info) => info.providerId == 'password')) {
          await _user!.updatePhotoURL(photoURL);
        }
      }
      
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(_user!.uid)
          .update(updateData);
      
      await _loadUserData(_user!.uid);
      
      _isLoading = false;
      if (_mounted) notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error actualizando información del usuario: $e');
      _error = 'Error al actualizar información: $e';
      _isLoading = false;
      if (_mounted) notifyListeners();
      return false;
    }
  }
  
  // Verificar estado de verificación de email
  Future<void> refreshUser() async {
    if (_isSigningOut) return;
    
    try {
      await _user?.reload();
      _user = _auth.currentUser;
      debugPrint('🔄 Usuario refrescado - Email verificado: ${_user?.emailVerified}');
      if (_mounted) notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }
}