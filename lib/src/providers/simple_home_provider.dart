// lib/src/providers/simple_home_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cache/event_cache_service.dart';
import '../cache/memory_filter_service.dart';
import '../cache/cache_models.dart';
import 'category_constants.dart';

/// Provider SIMPLE que reemplaza HomeViewModel de 300 líneas
/// Responsabilidad única: manejar estado UI + filtros sobre cache
class SimpleHomeProvider with ChangeNotifier {
  final EventCacheService _cacheService = EventCacheService();
  final MemoryFilterService _filterService = MemoryFilterService();

  // Estado simple
  bool _isLoading = false;
  String? _errorMessage;
  MemoryFilters _currentFilters = MemoryFilters.empty;
  FilteredEvents _filteredEvents = FilteredEvents.empty;

  // NUEVO: Propiedades para filtros de categorías
  Set<String> _selectedCategories = {}; // NUEVO: categorías habilitadas en Settings
  Set<String> _activeFilterCategories = {};

  // NUEVO: Tema UI (3 líneas)
  String _theme = 'normal'; // NUEVO
  String get theme => _theme; // NUEVO
  void setTheme(String theme) { _theme = theme; notifyListeners(); } // NUEVO

  // Getters públicos
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MemoryFilters get currentFilters => _currentFilters;
  List<EventCacheItem> get events => _filteredEvents.events;
  Map<String, List<EventCacheItem>> get groupedEvents => _filteredEvents.groupedByDate;
  int get eventCount => _filteredEvents.totalCount;
  String get appliedFiltersText => _filteredEvents.appliedFilters;

  // NUEVO: Getters para filtros de categorías
  Set<String> get selectedCategories => _selectedCategories; // NUEVO
  Set<String> get activeFilterCategories => _activeFilterCategories; // NUEVO

  /// Inicializar provider (cargar cache + preferencias + aplicar filtros) // CAMBIO: comentario actualizado
  Future<void> initialize() async {
    // NUEVO: Cargar preferencias primero
    await _loadCategoryPreferences(); // NUEVO

    if (_cacheService.isLoaded) {
      print('✅ Cache ya cargado, aplicando filtros...');
      _applyCurrentFilters();
      return;
    }

    _setLoading(true);

    try {
      // Cargar cache desde mock data (después será SQLite)
      await _cacheService.loadCache();

      // Aplicar filtros por defecto
      _applyCurrentFilters();

      _setLoading(false);
      print('✅ SimpleHomeProvider inicializado: ${_filteredEvents.totalCount} eventos');

    } catch (e) {
      _setError('Error cargando eventos: $e');
      print('❌ Error en SimpleHomeProvider.initialize(): $e');
    }
  }

  /// NUEVO: Cargar preferencias de categorías desde SharedPreferences
  Future<void> _loadCategoryPreferences() async { // NUEVO
    final prefs = await SharedPreferences.getInstance(); // NUEVO

    // NUEVO: Cargar selectedCategories (default: todas)
    final selectedList = prefs.getStringList('selectedCategories') ?? [ // NUEVO
      'Música', 'Teatro', 'StandUp', 'Arte', 'Cine', 'Mic', // NUEVO
      'Cursos', 'Ferias', 'Calle', 'Redes', 'Niños', 'Danza' // NUEVO
    ]; // NUEVO
    _selectedCategories = selectedList.toSet(); // NUEVO

    // NUEVO: Cargar activeFilterCategories (default: vacío)
    final activeList = prefs.getStringList('activeFilterCategories') ?? []; // NUEVO
    _activeFilterCategories = activeList.toSet(); // NUEVO

    print('📂 Categorías cargadas: selected=${_selectedCategories.length}, active=${_activeFilterCategories.length}'); // NUEVO
  }

  /// NUEVO: Guardar preferencias de categorías en SharedPreferences
  Future<void> _saveCategoryPreferences() async { // NUEVO
    final prefs = await SharedPreferences.getInstance(); // NUEVO
    await prefs.setStringList('selectedCategories', _selectedCategories.toList()); // NUEVO
    await prefs.setStringList('activeFilterCategories', _activeFilterCategories.toList()); // NUEVO
    print('💾 Preferencias guardadas: selected=${_selectedCategories.length}, active=${_activeFilterCategories.length}'); // NUEVO
  } // NUEVO

  /// NUEVO: Toggle categoría seleccionada (para Settings)
  Future<void> toggleCategory(String category) async { // NUEVO
    if (_selectedCategories.contains(category)) { // NUEVO
      _selectedCategories.remove(category); // NUEVO
      // NUEVO: Si se desactiva una categoría, también quitarla de filtros activos
      _activeFilterCategories.remove(category); // NUEVO
    } else { // NUEVO
      _selectedCategories.add(category); // NUEVO
    } // NUEVO

    // NUEVO: Guardar en SharedPreferences
    await _saveCategoryPreferences(); // NUEVO
    notifyListeners(); // NUEVO
    print('🏷️ Toggle categoría: $category, activas: ${_selectedCategories.length}'); // NUEVO
  } // NUEVO

  /// NUEVO: Toggle filtro activo (para chips en Explore)
  Future<void> toggleFilterCategory(String category) async { // NUEVO
    if (_activeFilterCategories.contains(category)) { // NUEVO
      _activeFilterCategories.remove(category); // NUEVO
    } else { // NUEVO
      _activeFilterCategories.add(category); // NUEVO
    } // NUEVO

    // NUEVO: Aplicar filtros con las nuevas categorías
    _currentFilters = _currentFilters.copyWith(categories: _activeFilterCategories); // NUEVO
    _applyCurrentFilters(); // NUEVO

    // NUEVO: Guardar estado
    await _saveCategoryPreferences(); // NUEVO
    print('🔍 Toggle filtro: $category, filtros activos: ${_activeFilterCategories.length}'); // NUEVO
  } // NUEVO

  /// NUEVO: Limpiar filtros activos (botón refresh)
  Future<void> clearActiveFilterCategories() async { // NUEVO
    _activeFilterCategories.clear(); // NUEVO
    _currentFilters = _currentFilters.copyWith(categories: {}); // NUEVO
    _applyCurrentFilters(); // NUEVO
    await _saveCategoryPreferences(); // NUEVO
    print('🧹 Filtros de categoría limpiados'); // NUEVO
  } // NUEVO

  /// NUEVO: Resetear categorías seleccionadas (botón restablecer en Settings)
  Future<void> resetCategories() async { // NUEVO
    _selectedCategories = { // NUEVO
      'Música', 'Teatro', 'StandUp', 'Arte', 'Cine', 'Mic', // NUEVO
      'Cursos', 'Ferias', 'Calle', 'Redes', 'Niños', 'Danza' // NUEVO
    }; // NUEVO
    _activeFilterCategories.clear(); // NUEVO
    _currentFilters = _currentFilters.copyWith(categories: {}); // NUEVO
    _applyCurrentFilters(); // NUEVO
    await _saveCategoryPreferences(); // NUEVO
    notifyListeners(); // NUEVO
    print('🔄 Categorías restablecidas a default'); // NUEVO
  } // NUEVO

  /// Cambiar búsqueda
  void setSearchQuery(String query) {
    print('🔍 Cambiando búsqueda: "$query"');

    _currentFilters = _currentFilters.copyWith(searchQuery: query);
    _applyCurrentFilters();
  }

  /// Cambiar fecha seleccionada
  void setSelectedDate(DateTime? date) {
    print('📅 Cambiando fecha: $date');

    _currentFilters = _currentFilters.copyWith(
      selectedDate: date,
      clearDate: date == null,
    );
    _applyCurrentFilters();
  }

  /// Limpiar todos los filtros
  void clearAllFilters() {
    print('🧹 Limpiando todos los filtros');

    _currentFilters = MemoryFilters.empty;
    _applyCurrentFilters();
  }

  /// Toggle favorito (update cache + UI)
  void toggleFavorite(int eventId) {
    print('💖 Toggle favorito: $eventId');

    final newState = _cacheService.toggleFavorite(eventId);

    // Re-aplicar filtros para actualizar UI
    _applyCurrentFilters();

    print('✅ Favorito cambiado: $eventId = $newState');
  }

  /// Recargar datos (para pull-to-refresh)
  Future<void> refresh() async {
    print('🔄 Refrescando datos...');

    _setLoading(true);

    try {
      await _cacheService.reloadCache();
      _applyCurrentFilters();
      _setLoading(false);

      print('✅ Refresh completado');
    } catch (e) {
      _setError('Error refrescando: $e');
    }
  }

  /// Obtener título de sección para fecha
  String getSectionTitle(String dateKey) {
    return _filterService.getSectionTitle(dateKey);
  }

  /// Obtener fechas ordenadas (hoy primero)
  List<String> getSortedDateKeys() {
    return _filterService.getSortedDateKeys(_filteredEvents.groupedByDate);
  }

  /// Obtener categoría con emoji (para FastEventCard)
  String getCategoryWithEmoji(String type) {
    return CategoryDisplayNames.getCategoryWithEmoji(type);
  }

  /// Formatear fecha para eventos (para FastEventCard)
  String formatEventDate(String dateString, {String format = 'card'}) {
    try {
      final date = DateTime.parse(dateString);
      switch (format) {
        case 'card':
          return "${date.day} ${_getMonthAbbrev(date.month)}${_getTimeString(date)}";
        default:
          return dateString;
      }
    } catch (e) {
      return dateString;
    }
  }
  /// NUEVO: Obtener eventos para una fecha específica (para calendario)
  Future<List<EventCacheItem>> getEventsForDate(DateTime date) async {
    if (!_cacheService.isLoaded) {
      await initialize();
    }

    final dateString = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"; // NUEVO: Formato yyyy-MM-dd
    return _cacheService.getEventsForDate(dateString);
  }

  /// NUEVO: Obtener conteos de eventos por rango de fechas (para calendario)
  Map<DateTime, int> getEventCountsForDateRange(DateTime start, DateTime end) {
    if (!_cacheService.isLoaded) {
      return {};
    }

    final counts = <DateTime, int>{};

    // NUEVO: Iterar cada día del rango
    for (DateTime date = start; date.isBefore(end.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      final dateString = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"; // NUEVO: Formato yyyy-MM-dd
      final count = _cacheService.getEventCountForDate(dateString);
      if (count > 0) {
        final cacheKey = DateTime(date.year, date.month, date.day); // NUEVO: Key sin hora
        counts[cacheKey] = count;
      }
    }

    return counts;
  }
  /// Obtener abreviación del mes
  String _getMonthAbbrev(int month) {
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return months[month] ?? 'mes';
  }

  /// Formatear hora si está disponible
  String _getTimeString(DateTime date) {
    if (date.hour != 0 || date.minute != 0) {
      return " - ${date.hour}:${date.minute.toString().padLeft(2, '0')} hs";
    }
    return "";
  }

  // === MÉTODOS PRIVADOS ===

  /// Aplicar filtros actuales
  void _applyCurrentFilters() {
    _filteredEvents = _filterService.applyFilters(_currentFilters);
    notifyListeners();

    print('🔄 Filtros aplicados: ${_filteredEvents.totalCount} eventos');
  }

  /// Cambiar estado de loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Mostrar error
  void _setError(String error) {
    _isLoading = false;
    _errorMessage = error;
    _filteredEvents = FilteredEvents.empty;
    notifyListeners();
  }

  // === DEBUG ===

  /// Estadísticas para debug
  /// Estadísticas para debug
  Map<String, dynamic> getDebugStats() {
    return {
      'cacheLoaded': _cacheService.isLoaded,
      'cacheEventCount': _cacheService.eventCount,
      'filteredEventCount': _filteredEvents.totalCount,
      'currentFilters': _currentFilters.description,
      'groupedDates': _filteredEvents.groupedByDate.keys.length,
      'isLoading': _isLoading,
      'hasError': _errorMessage != null,
      // NUEVO: Estadísticas de categorías
      'selectedCategoriesCount': _selectedCategories.length, // NUEVO
      'activeCategoriesCount': _activeFilterCategories.length, // NUEVO
      'selectedCategories': _selectedCategories.toList(), // NUEVO
      'activeCategories': _activeFilterCategories.toList(), // NUEVO
    };
  }

  /// Imprimir debug
  void debugPrint() {
    final stats = getDebugStats();
    print('🏠 SimpleHomeProvider Debug:');
    print('  Cache cargado: ${stats['cacheLoaded']}');
    print('  Eventos en cache: ${stats['cacheEventCount']}');
    print('  Eventos filtrados: ${stats['filteredEventCount']}');
    print('  Filtros actuales: ${stats['currentFilters']}');
    print('  Fechas agrupadas: ${stats['groupedDates']}');
    // NUEVO: Debug de categorías
    print('  Categorías seleccionadas: ${stats['selectedCategoriesCount']} ${stats['selectedCategories']}'); // NUEVO
    print('  Filtros activos: ${stats['activeCategoriesCount']} ${stats['activeCategories']}'); // NUEVO
  }
}