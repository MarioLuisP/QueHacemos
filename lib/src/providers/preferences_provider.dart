import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/models/user_preferences.dart';

class PreferencesProvider with ChangeNotifier {
  String _theme = 'normal';
  Set<String> _selectedCategories = {};
  Set<String> _activeFilterCategories = {};
  int _eventCleanupDays = 3;        // NUEVO: días limpieza eventos
  int _favoriteCleanupDays = 7;     // NUEVO: días limpieza favoritos
  PreferencesProvider();

  Future<void> init() async {
    await _loadPreferences();
  }

  String get theme => _theme;
  Set<String> get selectedCategories => _selectedCategories;
  Set<String> get activeFilterCategories => _activeFilterCategories;
  int get eventCleanupDays => _eventCleanupDays;      // NUEVO: getter eventos
  int get favoriteCleanupDays => _favoriteCleanupDays;

  Future<void> _loadPreferences() async {
    _theme = await UserPreferences.getTheme();
    _selectedCategories = await UserPreferences.getCategories();
    _eventCleanupDays = await UserPreferences.getEventCleanupDays();
    _favoriteCleanupDays = await UserPreferences.getFavoriteCleanupDays();
    // Si no hay nada guardado, activar todas por defecto
    if (_selectedCategories.isEmpty) {
      _selectedCategories = {
        'Música',
        'Teatro',
        'StandUp',
        'Arte',
        'Cine',
        'Mic',
        'Cursos',
        'Ferias',
        'Calle',
        'Redes',
        'Niños',
        'Danza',
      };
    }

    _activeFilterCategories = await UserPreferences.getActiveFilterCategories();
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _theme = theme;
    await UserPreferences.setTheme(theme);
    notifyListeners();
  }

  Future<void> toggleCategory(String category) async {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
      _activeFilterCategories.remove(category);
      await UserPreferences.setActiveFilterCategories(_activeFilterCategories);
    } else {
      _selectedCategories.add(category);
    }

    await UserPreferences.setCategories(_selectedCategories);
    notifyListeners();
  }

  Future<void> resetCategories() async {
    _selectedCategories = {
      'Música',
      'Teatro',
      'StandUp',
      'Arte',
      'Cine',
      'Mic',
      'Cursos',
      'Ferias',
      'Calle',
      'Redes',
      'Niños',
      'Danza',
    };
    _activeFilterCategories.clear();
    await UserPreferences.setCategories(_selectedCategories);
    await UserPreferences.setActiveFilterCategories(_activeFilterCategories);
    notifyListeners();
  }

  Future<void> toggleFilterCategory(String category) async {
    if (_activeFilterCategories.contains(category)) {
      _activeFilterCategories.remove(category);
    } else {
      _activeFilterCategories.add(category);
    }
    await UserPreferences.setActiveFilterCategories(_activeFilterCategories);
    notifyListeners();
  }
  Future<void> clearActiveFilterCategories() async {
    _activeFilterCategories.clear();
    await UserPreferences.setActiveFilterCategories(_activeFilterCategories);
    notifyListeners();
  }
  Future<void> setEventCleanupDays(int days) async {        // NUEVO: método completo
    _eventCleanupDays = days;                               // NUEVO: actualizar estado local
    await UserPreferences.setEventCleanupDays(days);        // NUEVO: persistir en SharedPrefs
    notifyListeners();                                      // NUEVO: notificar cambios UI
  }

  Future<void> setFavoriteCleanupDays(int days) async {     // NUEVO: método completo
    _favoriteCleanupDays = days;                            // NUEVO: actualizar estado local
    await UserPreferences.setFavoriteCleanupDays(days);     // NUEVO: persistir en SharedPrefs
    notifyListeners();                                      // NUEVO: notificar cambios UI
  }

}
