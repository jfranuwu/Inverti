// Archivo: lib/widgets/auth_wrapper.dart
// Wrapper centralizado para manejar estados de autenticación

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/home/investor_home_screen.dart';
import '../screens/home/entrepreneur_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        debugPrint('🔄 AuthWrapper - Estado: autenticado=${authProvider.isAuthenticated}, loading=${authProvider.isLoading}');
        
        // Mostrar splash mientras está cargando
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Cargando...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // Si no está autenticado, mostrar login
        if (!authProvider.isAuthenticated) {
          debugPrint('📱 AuthWrapper - Mostrando LoginScreen');
          return const LoginScreen();
        }

        // Si está autenticado pero no tiene rol, mostrar selección de rol
        final userType = authProvider.userModel?.userType ?? '';
        if (userType.isEmpty) {
          debugPrint('🎯 AuthWrapper - Mostrando RoleSelectionScreen');
          return const RoleSelectionScreen();
        }

        // Navegar según el tipo de usuario
        if (userType == 'investor') {
          debugPrint('💼 AuthWrapper - Mostrando InvestorHomeScreen');
          return const InvestorHomeScreen();
        } else {
          debugPrint('🚀 AuthWrapper - Mostrando EntrepreneurHomeScreen');
          return const EntrepreneurHomeScreen();
        }
      },
    );
  }
}