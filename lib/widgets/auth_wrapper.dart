
// Archivo: lib/widgets/auth_wrapper.dart
// Wrapper mejorado que maneja onboarding + autenticación

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/project_provider.dart';
import '../services/notification_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/home/investor_home_screen.dart';
import '../screens/home/entrepreneur_home_screen.dart';
import '../screens/onboarding_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitializedProviders = false;
  String? _lastInitializedUserId;
  bool _hasCheckedOnboarding = false;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  // Verificar si el usuario ha visto el onboarding
  Future<void> _checkOnboardingStatus() async {
    if (_hasCheckedOnboarding) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = hasSeenOnboarding;
          _hasCheckedOnboarding = true;
        });
      }
    } catch (e) {
      debugPrint('Error verificando onboarding: $e');
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = false;
          _hasCheckedOnboarding = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si aún no hemos verificado el onboarding, mostrar loading
    if (!_hasCheckedOnboarding) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si no ha visto onboarding, mostrarlo
    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    // Si ya vio onboarding, manejar autenticación
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Consumer<ChatProvider>(
          builder: (context, chatProvider, chatChild) {
            debugPrint('🔄 AuthWrapper - Estado: autenticado=${authProvider.isAuthenticated}, loading=${authProvider.isLoading}, signingOut=${authProvider.isSigningOut}');
            
            // Registrar providers para limpieza si aún no se ha hecho
            if (!_hasInitializedProviders) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _registerProvidersForCleanup(authProvider, chatProvider);
              });
            }

            // Mostrar loading mientras está cargando o haciendo logout
            if (authProvider.isLoading || authProvider.isSigningOut) {
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
              _resetState();
              return const LoginScreen();
            }

            // Si está autenticado pero email no verificado
            final user = authProvider.user;
            final isEmailUser = user?.providerData.any((info) => info.providerId == 'password') ?? false;
            
            if (isEmailUser && !authProvider.isEmailVerified) {
              debugPrint('📧 AuthWrapper - Email no verificado');
              return const EmailVerificationScreen();
            }

            // Si no tiene rol, mostrar selección de rol
            final userType = authProvider.userModel?.userType ?? '';
            if (userType.isEmpty) {
              debugPrint('🎯 AuthWrapper - Mostrando RoleSelectionScreen');
              return const RoleSelectionScreen();
            }

            // Inicializar providers si es necesario
            final currentUserId = user?.uid;
            if (currentUserId != null && 
                currentUserId != _lastInitializedUserId && 
                !authProvider.isSigningOut && 
                !chatProvider.isClearing) {
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializeUserProviders(currentUserId, chatProvider, authProvider);
              });
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
      },
    );
  }

  void _registerProvidersForCleanup(AuthProvider authProvider, ChatProvider chatProvider) {
    if (_hasInitializedProviders) return;
    
    debugPrint('🔗 AuthWrapper - Registrando providers para limpieza');
    
    final notificationService = _tryGetNotificationService();
    final projectProvider = _tryGetProjectProvider();
    
    authProvider.registerProvidersForCleanup(
      chatProvider: chatProvider,
      projectProvider: projectProvider,
      notificationService: notificationService,
    );
    
    _hasInitializedProviders = true;
  }

  void _initializeUserProviders(String userId, ChatProvider chatProvider, AuthProvider authProvider) {
    if (_lastInitializedUserId == userId || 
        authProvider.isSigningOut || 
        chatProvider.isClearing) {
      return;
    }
    
    debugPrint('🚀 AuthWrapper - Inicializando providers para usuario: $userId');
    
    if (!chatProvider.isClearing && mounted) {
      chatProvider.initializeUserChats(userId);
      _lastInitializedUserId = userId;
      
      final projectProvider = _tryGetProjectProvider();
      if (projectProvider != null) {
        projectProvider.loadMyProjects(userId);
        projectProvider.loadAllProjects();
      }
    }
  }

  void _resetState() {
    _lastInitializedUserId = null;
  }

  dynamic _tryGetNotificationService() {
    try {
      return NotificationService();
    } catch (e) {
      debugPrint('NotificationService no disponible: $e');
      return null;
    }
  }

  dynamic _tryGetProjectProvider() {
    try {
      return context.read<ProjectProvider>();
    } catch (e) {
      debugPrint('ProjectProvider no disponible: $e');
      return null;
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 AuthWrapper dispose() llamado');
    super.dispose();
  }
}