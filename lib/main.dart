// Archivo: lib/main.dart
// Punto de entrada principal - CON REGISTRO DE PROVIDERS PARA LIMPIEZA

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones de configuración
import 'config/theme.dart';
import 'config/firebase_config.dart';

// Importaciones de providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/project_provider.dart';
import 'providers/subscription_provider.dart'; 
import 'providers/chat_provider.dart'; // NUEVO

// Importaciones de servicios
import 'services/notification_service.dart';
import 'services/fcm_service.dart';

// Importaciones de pantallas
import 'screens/splash_screen.dart';
import 'widgets/auth_wrapper.dart';

// Handler para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Verificar si Firebase ya está inicializado de manera más robusta
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );
  }
  debugPrint('🔔 Mensaje FCM recibido en segundo plano: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Verificar si Firebase ya está inicializado de manera más robusta
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatform,
      );
    }
    
    // Configurar handler de mensajes en segundo plano para FCM
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Inicializar servicios (con manejo de errores)
    await _initializeServices();
    
    // Configurar SharedPreferences para el tema
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(isDarkMode),
          ),
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()), 
          ChangeNotifierProvider(create: (_) => ChatProvider()), // NUEVO
        ],
        child: const InvertiApp(),
      ),
    );
  } catch (e) {
    debugPrint('❌ Error crítico en main: $e');
    
    // En caso de error crítico, ejecutar app con funcionalidad mínima
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider(false)),
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()), 
          ChangeNotifierProvider(create: (_) => ChatProvider()), // NUEVO
        ],
        child: const InvertiApp(),
      ),
    );
  }
}

// Función auxiliar para inicializar servicios con manejo de errores
Future<void> _initializeServices() async {
  try {
    // Inicializar servicios de notificación (método de instancia)
    await NotificationService().initialize();
    debugPrint('✅ NotificationService inicializado');
  } catch (e) {
    debugPrint('⚠️ Error inicializando NotificationService: $e');
    // NotificationService no es crítico, la app puede funcionar sin él
  }
  
  try {
    // Inicializar FCM
    await FCMService().initialize();
    debugPrint('✅ FCMService inicializado');
  } catch (e) {
    debugPrint('⚠️ Error inicializando FCMService: $e');
    // FCM no es crítico, la app puede funcionar sin él
  }
}

class InvertiApp extends StatelessWidget {
  const InvertiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Inverti',
          debugShowCheckedModeBanner: false,
          
          // Tema claro personalizado
          theme: AppThemes.lightTheme,
          
          // Tema oscuro personalizado
          darkTheme: AppThemes.darkTheme,
          
          // Modo de tema basado en el provider
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // Pantalla inicial - SplashScreen (para manejar onboarding)
          home: const AppWithProviderRegistration(),
        );
      },
    );
  }
}

// NUEVO: Widget que registra providers para limpieza automática
class AppWithProviderRegistration extends StatefulWidget {
  const AppWithProviderRegistration({super.key});

  @override
  State<AppWithProviderRegistration> createState() => _AppWithProviderRegistrationState();
}

class _AppWithProviderRegistrationState extends State<AppWithProviderRegistration> {
  @override
  void initState() {
    super.initState();
    
    // Registrar providers para limpieza después del primer build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerProvidersForCleanup();
    });
  }

  void _registerProvidersForCleanup() {
    try {
      final authProvider = context.read<AuthProvider>();
      final chatProvider = context.read<ChatProvider>();
      final projectProvider = context.read<ProjectProvider>();
      final notificationService = NotificationService(); // Singleton
      
      // Registrar providers en AuthProvider para limpieza automática
      authProvider.registerProvidersForCleanup(
        chatProvider: chatProvider,
        projectProvider: projectProvider,
        notificationService: notificationService,
      );
      
      debugPrint('✅ Providers registrados para limpieza automática en logout');
      
    } catch (e) {
      debugPrint('⚠️ Error registrando providers para limpieza: $e');
      // No es crítico, la app puede funcionar sin esto
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

// Clase auxiliar para manejo de errores de Firebase (opcional)
class FirebaseErrorHandler {
  static void handleFirebaseError(dynamic error) {
    debugPrint('🔥 Firebase Error: $error');
    
    // Aquí puedes agregar lógica adicional como:
    // - Enviar errores a analytics
    // - Mostrar mensajes específicos al usuario
    // - Reintentar operaciones
  }
  
  static Future<bool> isFirebaseAvailable() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseConfig.currentPlatform,
        );
      }
      return true;
    } catch (e) {
      debugPrint('❌ Firebase no disponible: $e');
      return false;
    }
  }
}