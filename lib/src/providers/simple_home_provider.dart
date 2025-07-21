// lib/src/providers/simple_home_provider.dart

import 'package:flutter/material.dart';
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

  // Getters públicos
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MemoryFilters get currentFilters => _currentFilters;
  List<EventCacheItem> get events => _filteredEvents.events;
  Map<String, List<EventCacheItem>> get groupedEvents => _filteredEvents.groupedByDate;
  int get eventCount => _filteredEvents.totalCount;
  String get appliedFiltersText => _filteredEvents.appliedFilters;

  /// Inicializar provider (cargar cache + aplicar filtros)
  Future<void> initialize() async {
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

  /// Cambiar filtros de categorías
  void setCategories(Set<String> categories) {
    print('🏷️ Cambiando categorías: $categories');

    _currentFilters = _currentFilters.copyWith(categories: categories);
    _applyCurrentFilters();
  }

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
  Map<String, dynamic> getDebugStats() {
    return {
      'cacheLoaded': _cacheService.isLoaded,
      'cacheEventCount': _cacheService.eventCount,
      'filteredEventCount': _filteredEvents.totalCount,
      'currentFilters': _currentFilters.description,
      'groupedDates': _filteredEvents.groupedByDate.keys.length,
      'isLoading': _isLoading,
      'hasError': _errorMessage != null,
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
  }
}