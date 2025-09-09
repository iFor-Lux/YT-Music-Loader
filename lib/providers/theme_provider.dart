import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String? _customBackgroundPath;
  bool _useCustomBackground = false;

  // Getters optimizados
  bool get isDarkMode => _isDarkMode;
  String? get customBackgroundPath => _customBackgroundPath;
  bool get useCustomBackground => _useCustomBackground;

  // Constructor
  ThemeProvider() {
    _loadThemeSettings();
  }

  // Cargar configuración guardada
  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      _customBackgroundPath = prefs.getString('custom_background_path');
      _useCustomBackground = prefs.getBool('use_custom_background') ?? false;
      notifyListeners();
    } catch (e) {
      // print('Error loading theme settings: $e');
    }
  }

  // Cambiar tema
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Alias para toggleTheme (para compatibilidad)
  Future<void> toggleDarkMode() async {
    await toggleTheme();
  }

  // Establecer tema específico
  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Cambiar background personalizado
  Future<void> setCustomBackground(String? imagePath) async {
    _customBackgroundPath = imagePath;
    _useCustomBackground = imagePath != null;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Remover background personalizado
  Future<void> removeCustomBackground() async {
    _customBackgroundPath = null;
    _useCustomBackground = false;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Alias para removeCustomBackground (para compatibilidad)
  Future<void> clearBackgroundImage() async {
    await removeCustomBackground();
  }

  // Alias para setCustomBackground (para compatibilidad)
  Future<void> setBackgroundImage(File imageFile) async {
    await setCustomBackground(imageFile.path);
  }

  // Guardar configuración
  Future<void> _saveThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _isDarkMode);
      await prefs.setString('custom_background_path', _customBackgroundPath ?? '');
      await prefs.setBool('use_custom_background', _useCustomBackground);
    } catch (e) {
      // print('Error saving theme settings: $e');
    }
  }

  // Obtener tema de la app
  ThemeData getTheme() {
    if (_isDarkMode) {
      return _darkTheme;
    } else {
      return _lightTheme;
    }
  }

  // Tema claro
  static final _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
      titleSmall: TextStyle(color: Colors.black87),
    ),
  );

  // Tema oscuro - SIMPLIFICADO Y FUNCIONAL
  static final _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    // FORZAR COLORES DE FONDO EN TODA LA APP
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    cardColor: const Color(0xFF1A1A1A),
    dialogBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A1A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerTheme: const DividerThemeData(color: Colors.white24),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.white70,
    ),
  );

  // Verificar si la imagen de background existe
  bool get hasValidBackground {
    if (_customBackgroundPath == null) return false;
    return File(_customBackgroundPath!).existsSync();
  }

  // Obtener imagen de background
  ImageProvider? get backgroundImage {
    if (!_useCustomBackground || _customBackgroundPath == null) {
      return null;
    }
    
    try {
      if (File(_customBackgroundPath!).existsSync()) {
        return FileImage(File(_customBackgroundPath!));
      } else {
      }
    } catch (e) {
      // print('Error loading background image: $e');
    }
    return null;
  }
}
