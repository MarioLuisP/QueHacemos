// lib/src/providers/preferences_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider LIMPIO solo para temas
/// Usa SharedPreferences directo (nueva arquitectura)
class PreferencesProvider with ChangeNotifier {
  String _theme = 'normal'; // Default tema normal

  // Getter público
  String get theme => _theme;

  /// Inicializar: cargar tema guardado
  Future<void> initialize() async {
    await _loadTheme();
    print('🎨 PreferencesProvider inicializado con tema: $_theme');
  }

  /// Cambiar tema y persistir
  Future<void> setTheme(String theme) async {
    if (_theme != theme) {
      _theme = theme;
      await _saveTheme();
      notifyListeners();
      print('🎨 Tema cambiado a: $theme');
    }
  }

  /// Cargar tema desde SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _theme = prefs.getString('app_theme') ?? 'normal';
      print('📂 Tema cargado: $_theme');
    } catch (e) {
      print('❌ Error cargando tema: $e');
      _theme = 'normal'; // Fallback
    }
  }

  /// Guardar tema en SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', _theme);
      print('💾 Tema guardado: $_theme');
    } catch (e) {
      print('❌ Error guardando tema: $e');
    }
  }

  /// Debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentTheme': _theme,
      'availableThemes': ['normal', 'dark', 'fluor', 'harmony', 'sepia', 'pastel'],
    };
  }
}