// File: lib/main.dart
// Punto de entrada con background handler para notificaciones de chat

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/theme.dart';
import 'config/firebase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/project_provider.dart';
import 'providers/subscription_provider.dart'; 
import 'providers/chat_provider.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'screens/splash_screen.dart';
import 'widgets/auth_wrapper.dart';

// Background handler para notificaciones - maneja mensajes cuando la app está cerrada
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );
  }
  
  debugPrint('🔔 Mensaje FCM recibido en segundo plano: ${message.messageId}');
  debugPrint('🔔 Tipo: ${message.data['type']}');
  
  // Manejar diferentes tipos de notificaciones
  final messageType = message.data['type'];
  
  switch (messageType) {
    case 'chat_message':
      debugPrint('💬 Mensaje de chat recibido en background');
      debugPrint('💬 De: ${message.data['senderName']}');
      debugPrint('💬 Chat ID: ${message.data['chatId']}');
      break;
    case 'investor_interest':
      debugPrint('🎯 Notificación de interés de inversor en background');
      break;
    case 'project_funded':
      debugPrint('🎉 Notificación de proyecto financiado en background');
      break;
    default:
      debugPrint('📢 Notificación general en background');
      break;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatform,
      );
    }
    
    // Configurar background handler para notificaciones
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initializeServices();
    
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider(isDarkMode)),
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()), 
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: const InvertiApp(),
      ),
    );
  } catch (e) {
    debugPrint('❌ Error crítico en main: $e');
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider(false)),
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()), 
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: const InvertiApp(),
      ),
    );
  }
}

// Inicializar servicios de notificaciones
Future<void> _initializeServices() async {
  try {
    await NotificationService().initialize();
    debugPrint('✅ NotificationService inicializado');
  } catch (e) {
    debugPrint('⚠️ Error inicializando NotificationService: $e');
  }
  
  try {
    await FCMService().initialize();
    debugPrint('✅ FCMService inicializado');
  } catch (e) {
    debugPrint('⚠️ Error inicializando FCMService: $e');
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
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AppInitializer(),
        );
      },
    );
  }
}

// Widget que maneja la inicialización y navegación inicial
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Inicializar app y registrar providers para limpieza automática
  Future<void> _initializeApp() async {
    try {
      // Registrar providers para limpieza
      final authProvider = context.read<AuthProvider>();
      final chatProvider = context.read<ChatProvider>();
      final projectProvider = context.read<ProjectProvider>();
      final notificationService = NotificationService();
      
      authProvider.registerProvidersForCleanup(
        chatProvider: chatProvider,
        projectProvider: projectProvider,
        notificationService: notificationService,
      );
      
      debugPrint('✅ Providers registrados para limpieza automática');
      
      // Mostrar splash por 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      
    } catch (e) {
      debugPrint('⚠️ Error inicializando app: $e');
      
      // En caso de error, continuar después de 3 segundos
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashScreen();
    }
    
    // Una vez inicializado, AuthWrapper maneja toda la navegación
    return const AuthWrapper();
  }
}