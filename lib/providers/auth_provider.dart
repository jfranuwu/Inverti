// Archivo: lib/providers/auth_provider.dart
// Provider para gestión de autenticación con Firebase - CON NOTIFICACIONES FCM

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get mounted => _mounted;
  
  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
  
  // Manejar cambios de estado de autenticación
  Future<void> _onAuthStateChanged(User? user) async {
    print('Auth state changed: ${user?.uid}');
    _user = user;
    if (user != null) {
      await _loadUserData(user.uid);
      // Configurar FCM después del login
      await _setupFCMForUser(user.uid);
    } else {
      _userModel = null;
      // Limpiar FCM al hacer logout
      await _cleanupFCMOnLogout();
    }
    
    if (_mounted) {
      notifyListeners();
    }
  }
  
  // Cargar datos del usuario desde Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      print('Loading user data for: $uid');
      final doc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(uid)
          .get();
      
      if (doc.exists) {
        print('User document found');
        _userModel = UserModel.fromFirestore(doc);
        print('UserModel loaded: ${_userModel?.name}, userType: ${_userModel?.userType}');
      } else {
        print('User document not found');
      }
    } catch (e) {
      print('Error loading user data: $e');
      _error = 'Error al cargar datos del usuario: $e';
    }
    
    if (_mounted) {
      notifyListeners();
    }
  }
  
  // Configurar FCM para el usuario
  Future<void> _setupFCMForUser(String userId) async {
    try {
      print('🔔 Configurando FCM para usuario: $userId');
      
      // Guardar token FCM después del login
      await FCMService().saveTokenAfterLogin(userId);
      
      // Suscribir a temas según el tipo de usuario
      if (_userModel?.userType == 'investor') {
        await FCMService().subscribeToTopic('new_projects');
        await FCMService().unsubscribeFromTopic('investor_interest');
        print('✅ Inversor suscrito a nuevos proyectos');
      } else if (_userModel?.userType == 'entrepreneur') {
        await FCMService().subscribeToTopic('investor_interest');
        await FCMService().unsubscribeFromTopic('new_projects');
        print('✅ Emprendedor suscrito a interés de inversores');
      }
    } catch (e) {
      print('❌ Error configurando FCM: $e');
    }
  }
  
  // Limpiar FCM al cerrar sesión
  Future<void> _cleanupFCMOnLogout() async {
    try {
      print('🧹 Limpiando FCM al cerrar sesión');
      await FCMService().clearTokenOnLogout();
      await FCMService().unsubscribeFromTopic('new_projects');
      await FCMService().unsubscribeFromTopic('investor_interest');
    } catch (e) {
      print('❌ Error limpiando FCM: $e');
    }
  }
  
  // Registro con email y contraseña
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      if (_mounted) notifyListeners();
      
      print('Starting registration for: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        print('User created with UID: ${credential.user!.uid}');
        
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
        
        print('User saved to Firestore');
        
        // Configurar FCM para nuevo usuario
        await _setupFCMForUser(credential.user!.uid);
        
        try {
          await credential.user!.sendEmailVerification();
          print('Verification email sent');
        } catch (e) {
          print('Error sending verification email: $e');
        }
        
        _userModel = userModel;
        _isLoading = false;
        if (_mounted) notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      _error = _handleAuthError(e);
    } catch (e) {
      print('General error during registration: $e');
      _error = 'Error en el registro: $e';
    }
    
    _isLoading = false;
    if (_mounted) notifyListeners();
    return false;
  }
  
  // Inicio de sesión con email y contraseña
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      if (_mounted) notifyListeners();
      
      print('Signing in with email: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        print('Sign in successful: ${credential.user!.uid}');
        _isLoading = false;
        if (_mounted) notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      _error = _handleAuthError(e);
    } catch (e) {
      print('General error during sign in: $e');
      _error = 'Error en el inicio de sesión: $e';
    }
    
    _isLoading = false;
    if (_mounted) notifyListeners();
    return false;
  }
  
  // Inicio de sesión con Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      if (_mounted) notifyListeners();
      
      print('Starting Google Sign In...');
      
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign In cancelled by user');
        _isLoading = false;
        if (_mounted) notifyListeners();
        return false;
      }
      
      print('Google user: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        print('Firebase sign in successful: ${userCredential.user!.uid}');
        
        final doc = await _firestore
            .collection(FirebaseConfig.usersCollection)
            .doc(userCredential.user!.uid)
            .get();
        
        if (!doc.exists) {
          print('Creating new user document in Firestore');
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
          print('New user model created and loaded');
        } else {
          _userModel = UserModel.fromFirestore(doc);
          print('Existing user model loaded');
        }
        
        // Configurar FCM para usuario existente o nuevo
        await _setupFCMForUser(userCredential.user!.uid);
        
        _isLoading = false;
        if (_mounted) notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error with Google Sign-In: $e');
      _error = 'Error con Google Sign-In: $e';
    }
    
    _isLoading = false;
    if (_mounted) notifyListeners();
    return false;
  }
  
  // Actualizar tipo de usuario (rol)
  Future<bool> updateUserType(String userType) async {
    if (_user == null) {
      print('Error: No hay usuario autenticado');
      _error = 'No hay usuario autenticado';
      return false;
    }
    
    if (_userModel == null) {
      print('UserModel es null, intentando cargar...');
      await _loadUserData(_user!.uid);
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_userModel == null) {
        print('No se pudo cargar el modelo de usuario');
        _error = 'No se pudo cargar la información del usuario';
        return false;
      }
    }
    
    try {
      _isLoading = true;
      if (_mounted) notifyListeners();
      
      print('Updating user type to: $userType for user: ${_user!.uid}');
      
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(_user!.uid)
          .update({'userType': userType});
      
      _userModel = _userModel!.copyWith(userType: userType);
      
      print('User type updated successfully in both Firestore and local model');
      
      // Reconfigurar FCM con el nuevo rol
      await _setupFCMForUser(_user!.uid);
      
      _isLoading = false;
      if (_mounted) notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user type: $e');
      _error = 'Error al actualizar el tipo de usuario: $e';
      _isLoading = false;
      if (_mounted) notifyListeners();
      return false;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    try {
      print('Signing out...');
      
      // Limpiar FCM antes de cerrar sesión
      await _cleanupFCMOnLogout();
      
      await _auth.signOut();
      await _googleSignIn.signOut();
      _user = null;
      _userModel = null;
      
      if (_mounted) {
        notifyListeners();
      }
    } catch (e) {
      print('Error signing out: $e');
      _error = 'Error al cerrar sesión: $e';
      if (_mounted) {
        notifyListeners();
      }
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
        return true;
      }
    } catch (e) {
      _error = 'Error al reenviar email de verificación: $e';
    }
    return false;
  }
  
  // Actualizar foto de perfil
  Future<bool> updateProfilePhoto(String photoURL) async {
    if (_user == null) return false;
    
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
    print('Handling auth error: ${e.code}');
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
    if (_user != null) {
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
        print('Error obteniendo token FCM: $e');
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
    if (_user == null) return false;
    
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
      print('Error actualizando información del usuario: $e');
      _error = 'Error al actualizar información: $e';
      _isLoading = false;
      if (_mounted) notifyListeners();
      return false;
    }
  }
  
  // Verificar estado de verificación de email
  Future<void> refreshUser() async {
    try {
      await _user?.reload();
      _user = _auth.currentUser;
      if (_mounted) notifyListeners();
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }
}