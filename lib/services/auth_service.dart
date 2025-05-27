// Archivo: lib/services/auth_service.dart
// Servicio para autenticación con Firebase

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Obtener usuario actual
  static User? get currentUser => _auth.currentUser;
  
  // Stream de cambios de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Verificar si el email está verificado
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;
  
  // Cerrar sesión
  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
  
  // Eliminar cuenta
  static Future<bool> deleteAccount() async {
    try {
      await currentUser?.delete();
      return true;
    } catch (e) {
      print('Error al eliminar cuenta: $e');
      return false;
    }
  }
  
  // Reautenticar usuario (necesario para operaciones sensibles)
  static Future<bool> reauthenticate(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) return false;
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('Error en reautenticación: $e');
      return false;
    }
  }
}