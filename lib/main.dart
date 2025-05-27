// Archivo: lib/main.dart
// Punto de entrada principal de la aplicación Inverti

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones de configuración
import 'config/theme.dart';
import 'config/firebase_config.dart';

// Importaciones de providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/project_provider.dart';

// Importaciones de servicios
import 'services/notification_service.dart';

// Importaciones de pantallas
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Verificar si Firebase ya está inicializado de manera más robusta
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );
  }
  
  // Resto del código...
  await NotificationService.initialize();
  
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
      ],
      child: const InvertiApp(),
    ),
  );
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
          
          // Pantalla inicial - Splash Screen
          home: const SplashScreen(),
        );
      },
    );
  }
}