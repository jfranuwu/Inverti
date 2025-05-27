// Archivo: lib/providers/theme_provider.dart
// Provider para gestión de temas claro/oscuro

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  // Constructor con valor inicial
  ThemeProvider(bool initialDarkMode) {
    _isDarkMode = initialDarkMode;
  }
  
  // Getter
  bool get isDarkMode => _isDarkMode;
  
  // Cambiar tema
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    // Guardar preferencia en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    
    notifyListeners();
  }
  
  // Establecer tema específico
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      
      // Guardar preferencia
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      
      notifyListeners();
    }
  }
}