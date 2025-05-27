// Archivo: lib/providers/auth_provider.dart
// Provider para gestión de autenticación con Firebase

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/firebase_config.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  // Constructor - Escuchar cambios de autenticación
  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  // Manejar cambios de estado de autenticación
  Future<void> _onAuthStateChanged(User? user) async {
    print('Auth state changed: ${user?.uid}');
    _user = user;
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
      
      print('Starting registration for: $email');
      
      // Crear usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        print('User created with UID: ${credential.user!.uid}');
        
        // Crear modelo de usuario
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          name: name.trim(),
          userType: userType,
          createdAt: DateTime.now(),
        );
        
        // Guardar en Firestore
        print('Saving user to Firestore...');
        await _firestore
            .collection(FirebaseConfig.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());
        
        print('User saved to Firestore');
        
        // Enviar email de verificación
        try {
          await credential.user!.sendEmailVerification();
          print('Verification email sent');
        } catch (e) {
          print('Error sending verification email: $e');
        }
        
        _userModel = userModel;
        _isLoading = false;
        notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
      
      print('Signing in with email: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        print('Sign in successful: ${credential.user!.uid}');
        // Los datos del usuario se cargarán automáticamente en _onAuthStateChanged
        _isLoading = false;
        notifyListeners();
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
    notifyListeners();
    return false;
  }
  
  // Inicio de sesión con Google - ACTUALIZADO
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      print('Starting Google Sign In...');
      
      // Cancelar cualquier proceso anterior
      await _googleSignIn.signOut();
      
      // Proceso de autenticación con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign In cancelled by user');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      print('Google user: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Iniciar sesión en Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        print('Firebase sign in successful: ${userCredential.user!.uid}');
        
        // Verificar si el usuario ya existe en Firestore
        final doc = await _firestore
            .collection(FirebaseConfig.usersCollection)
            .doc(userCredential.user!.uid)
            .get();
        
        if (!doc.exists) {
          print('Creating new user document in Firestore');
          // Crear nuevo usuario
          final userModel = UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? '',
            photoURL: userCredential.user!.photoURL,
            userType: '', // Se establecerá en la pantalla de selección de rol
            createdAt: DateTime.now(),
          );
          
          await _firestore
              .collection(FirebaseConfig.usersCollection)
              .doc(userCredential.user!.uid)
              .set(userModel.toFirestore());
              
          // IMPORTANTE: Cargar el modelo inmediatamente después de crearlo
          _userModel = userModel;
          print('New user model created and loaded');
        } else {
          // Si ya existe, cargar el modelo
          _userModel = UserModel.fromFirestore(doc);
          print('Existing user model loaded');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error with Google Sign-In: $e');
      _error = 'Error con Google Sign-In: $e';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // Actualizar tipo de usuario (rol) - ACTUALIZADO
  Future<bool> updateUserType(String userType) async {
    if (_user == null) {
      print('Error: No hay usuario autenticado');
      _error = 'No hay usuario autenticado';
      return false;
    }
    
    // Si no hay userModel, intentar cargarlo
    if (_userModel == null) {
      print('UserModel es null, intentando cargar...');
      await _loadUserData(_user!.uid);
      
      // Esperar un momento para asegurar que se cargue
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Si aún es null después de intentar cargar
      if (_userModel == null) {
        print('No se pudo cargar el modelo de usuario');
        _error = 'No se pudo cargar la información del usuario';
        return false;
      }
    }
    
    try {
      _isLoading = true;
      notifyListeners();
      
      print('Updating user type to: $userType for user: ${_user!.uid}');
      
      // Actualizar en Firestore
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(_user!.uid)
          .update({'userType': userType});
      
      // Actualizar modelo local
      _userModel = _userModel!.copyWith(userType: userType);
      
      print('User type updated successfully in both Firestore and local model');
      
      // Suscribir a temas de notificaciones según el rol (opcional)
      try {
        if (userType == 'investor') {
          // Los inversores reciben notificaciones de nuevos proyectos
          await _subscribeToTopic(FirebaseConfig.newProjectsTopic);
        } else {
          // Los emprendedores reciben notificaciones de interés de inversores
          await _subscribeToTopic(FirebaseConfig.investorInterestTopic);
        }
      } catch (e) {
        print('Error al suscribir a temas: $e');
        // No fallar la operación por esto
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user type: $e');
      _error = 'Error al actualizar el tipo de usuario: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    try {
      print('Signing out...');
      await _auth.signOut();
      await _googleSignIn.signOut();
      _user = null;
      _userModel = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      _error = 'Error al cerrar sesión: $e';
      notifyListeners();
    }
  }
  
  // Enviar email de recuperación de contraseña
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _handleAuthError(e);
    } catch (e) {
      _error = 'Error al enviar email: $e';
    }
    
    _isLoading = false;
    notifyListeners();
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
      notifyListeners();
      
      // Actualizar en Firebase Auth solo si es autenticación por email
      if (_user!.providerData.any((info) => info.providerId == 'password')) {
        await _user!.updatePhotoURL(photoURL);
      }
      
      // Actualizar en Firestore
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(_user!.uid)
          .update({'photoURL': photoURL});
      
      // Actualizar modelo local
      _userModel = _userModel?.copyWith(photoURL: photoURL);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar foto: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Suscribir a tema de notificaciones
  Future<void> _subscribeToTopic(String topic) async {
    try {
      // Implementar con Firebase Cloud Messaging
      // await FirebaseMessaging.instance.subscribeToTopic(topic);
      print('Suscrito al tema: $topic');
    } catch (e) {
      print('Error al suscribir a tema: $e');
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
    notifyListeners();
  }
}