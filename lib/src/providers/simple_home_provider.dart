// lib/src/providers/simple_home_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cache/event_cache_service.dart';
import '../cache/cache_models.dart';
import '../utils/colors.dart';
import '../sync/sync_service.dart';
import 'favorites_provider.dart';  // AGREGAR ESTE IMPORT
import '../data/repositories/event_repository.dart';

/// Provider SIMPLE que reemplaza HomeViewModel de 300 líneas
/// Responsabilidad única: manejar estado UI + filtros sobre cache
class SimpleHomeProvider with ChangeNotifier {
  final EventCacheService _cacheService = EventCacheService();

  // Estado simple
  bool _isLoading = false;
  String? _errorMessage;
  MemoryFilters _currentFilters = MemoryFilters.empty;
  FilteredEvents _filteredEvents = FilteredEvents.empty;

  // NUEVO: Propiedades para filtros de categorías
  Set<String> _selectedCategories = {}; // NUEVO: categorías habilitadas en Settings
  String _theme = 'normal'; // NUEVO: Tema actual de la app
  DateTime? _lastSelectedDate; // NUEVO: Para persistencia de Calendar
// NUEVO: Propiedades para limpieza automática
  int _eventCleanupDays = 3;
  int _favoriteCleanupDays = 7;
  // NUEVO: Constructor aquí
  SimpleHomeProvider() {
    _initializeAsync();
  }

  // NUEVO: Método async aquí
  void _initializeAsync() {
    initialize();
  }


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
  String get theme => _theme;
  DateTime? get lastSelectedDate => _lastSelectedDate;
  // NUEVO: Getters para limpieza automática
  int get eventCleanupDays => _eventCleanupDays;
  int get favoriteCleanupDays => _favoriteCleanupDays;

  /// Inicializar provider (cargar cache + preferencias + aplicar filtros) // CAMBIO: comentario actualizado
  Future<void> initialize() async {
    // NUEVO: Sync automático al startup (pobla la DB)
    //await SyncService().syncOnAppStart();

    // NUEVO: Cargar preferencias primero
    await _loadAllPreferences(); // NUEVO

    if (_cacheService.isLoaded) {
      print('✅ Cache ya cargado, aplicando filtros...');
      _applyCurrentFilters();
      return;
    }

    _setLoading(true);

    try {
      // Cargar cache desde mock data (después será SQLite)
      await _cacheService.loadCache(theme: _theme);

      // Aplicar filtros por defecto
      _applyCurrentFilters();

      _setLoading(false);
      print('✅ SimpleHomeProvider inicializado: ${_filteredEvents.totalCount} eventos');

    } catch (e) {
      _setError('Error cargando eventos: $e');
      print('❌ Error en SimpleHomeProvider.initialize(): $e');
    }
  }

  /// NUEVO: Registrar callback con FavoritesProvider (llamar después de initialize)
  void setupFavoritesSync(FavoritesProvider favoritesProvider) {
    favoritesProvider.setOnFavoriteChangedCallback((eventId, isFavorite) {
      syncFavoriteInCache(eventId, isFavorite);
    });
    print('🔗 Sync configurado entre FavoritesProvider y SimpleHomeProvider');
  }
  /// Obtener eventos con filtros de categoría y búsqueda, ignorando fecha
  List<EventCacheItem> getEventsWithoutDateFilter() {
    print('🐛 DEBUG - _currentFilters: ${_currentFilters.description}');
    print('🐛 DEBUG - _currentFilters.categories: ${_currentFilters.categories}');
    print('🐛 DEBUG - _currentFilters.searchQuery: "${_currentFilters.searchQuery}"');

    final filtersWithoutDate = _currentFilters.copyWith(
      selectedDate: null,
      clearDate: true,
    );

    final result = _cacheService.applyFilters(filtersWithoutDate).events;
    print('🐛 DEBUG - Eventos devueltos: ${result.length}');

    return result;
  }

  /// NUEVO: Cargar preferencias de categorías desde SharedPreferences
  Future<void> _loadAllPreferences() async { // NUEVO
    final prefs = await SharedPreferences.getInstance(); // NUEVO

    // NUEVO: Cargar selectedCategories (default: todas)
    final selectedList = prefs.getStringList('selectedCategories') ?? [
      'musica', 'teatro', 'standup', 'arte', 'cine', 'mic',
      'cursos', 'ferias', 'calle', 'redes', 'ninos', 'danza'
    ];
    _selectedCategories = selectedList.toSet(); // NUEVO

    // ELIMINADO: Cargar activeFilterCategories - ya no filtros globales
    _theme = prefs.getString('app_theme') ?? 'normal';
    print('📂 Preferencias cargadas: tema=$_theme, selected=${_selectedCategories.length}'); // CAMBIO: removido active
// NUEVO: Cargar configuración de limpieza desde EventRepository
    final repository = EventRepository();
    _eventCleanupDays = await repository.getCleanupDays('cleanup_events_days');
    _favoriteCleanupDays = await repository.getCleanupDays('cleanup_favorites_days');
  }

  /// NUEVO: Guardar preferencias de categorías en SharedPreferences
  Future<void> _saveAllPreferences() async { // NUEVO
    final prefs = await SharedPreferences.getInstance(); // NUEVO
    await prefs.setStringList('selectedCategories', _selectedCategories.toList()); // NUEVO
    // ELIMINADO: Guardar activeFilterCategories - ya no filtros globales
    await prefs.setString('app_theme', _theme); // NUEVO: Guardar tema
    print('💾 Preferencias guardadas: tema=$_theme, selected=${_selectedCategories.length}'); // CAMBIO: removido active
  }/// NUEVO: Toggle categoría seleccionada (para Settings)
  Future<void> toggleCategory(String category) async { // NUEVO
    if (_selectedCategories.contains(category)) { // NUEVO
      _selectedCategories.remove(category); // NUEVO
      // ELIMINADO: Ya no hay filtros activos globales para limpiar
    } else { // NUEVO
      _selectedCategories.add(category); // NUEVO
    } // NUEVO

    // NUEVO: Guardar en SharedPreferences
    await _saveAllPreferences(); // NUEVO
    notifyListeners(); // NUEVO
    print('🏷️ Toggle categoría: $category, activas: ${_selectedCategories.length}'); // NUEVO
  } // NUEVO


  /// NUEVO: Resetear categorías seleccionadas (botón restablecer en Settings)
  Future<void> resetCategories() async { // NUEVO
    _selectedCategories = {
      'musica', 'teatro', 'standup', 'arte', 'cine', 'mic',
      'cursos', 'ferias', 'calle', 'redes', 'ninos', 'danza'
    }; // NUEVO
    // ELIMINADO: _activeFilterCategories.clear() - ya no filtros globales
    // ELIMINADO: _currentFilters = _currentFilters.copyWith(categories: {}) - ya no categorías en filtros
    // ELIMINADO: _applyCurrentFilters() - no necesario recalcular filtros
    await _saveAllPreferences(); // NUEVO
    notifyListeners(); // NUEVO
    print('🔄 Categorías restablecidas a default'); // NUEVO
  } // NUEVO
  /// Cambiar búsqueda
  void setSearchQuery(String query) {
    print('🔍 Cambiando búsqueda: "$query"');

    _currentFilters = _currentFilters.copyWith(searchQuery: query);
    _applyCurrentFilters();
  }
  /// NUEVO: Cambiar tema y recalcular colores
  Future<void> setTheme(String theme) async {
    if (_theme != theme) {
      _theme = theme;

      // Recalcular colores del cache
      _cacheService.recalculateColorsForTheme(theme);

      // Re-aplicar filtros para actualizar UI
      _applyCurrentFilters();

      // Guardar preferencias
      await _saveAllPreferences();

      print('🎨 Tema cambiado a: $theme');
    }
  }
  /// NUEVO: Persistir día seleccionado para Calendar
  void setLastSelectedDate(DateTime date) {
    _lastSelectedDate = date;
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

  /// Toggle favorito (delegado a FavoritesProvider)
  void toggleFavorite(int eventId) {
    print('💖 Toggle favorito delegado a FavoritesProvider: $eventId');
    // TODO: Llamar a FavoritesProvider en siguiente paso
  }


  /// NUEVO: Sincronizar favorito en cache (llamado por FavoritesProvider)
  void syncFavoriteInCache(int eventId, bool isFavorite) {
    final updated = _cacheService.updateFavoriteInCache(eventId, isFavorite);
    if (updated) {
      _applyCurrentFilters(); // Refresh UI para consistencia
      print('🔄 Cache sincronizado: evento $eventId = $isFavorite');
    }
  }

  /// NUEVO: Para Selector eficiente (evitar rebuilds masivos)
  bool isEventFavorite(int eventId) {
    final event = _cacheService.getEventById(eventId);
    return event?.favorite ?? false;
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
  /// NUEVO: Obtener eventos favoritos desde cache (para FavoritePage)
  List<EventCacheItem> getFavoriteEvents() {
    if (!_cacheService.isLoaded) {
      return [];
    }

    // Filtrar solo eventos marcados como favoritos en cache
    final favoriteEvents = _cacheService.allEvents
        .where((event) => event.favorite)
        .toList();

    // Ordenar por fecha (más recientes primero) y luego por rating
    favoriteEvents.sort((a, b) {
      final dateComparison = a.date.compareTo(b.date);
      if (dateComparison != 0) return dateComparison;
      return b.rating.compareTo(a.rating); // Mayor rating primero
    });

    return favoriteEvents;
  }
  /// Obtener título de sección para fecha
  String getSectionTitle(String dateKey) {
    return _cacheService.getSectionTitle(dateKey);
  }

  /// Obtener fechas ordenadas (hoy primero)
  List<String> getSortedDateKeys() {
    return _cacheService.getSortedDateKeys(_filteredEvents.groupedByDate);  }

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
  Future<List<EventCacheItem>> getEventsForDate(DateTime date) async {
    if (!_cacheService.isLoaded) {
      await initialize();
    }

    final dateString = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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
  /// Obtener eventos para fecha específica - O(1) lookup sin re-procesamiento
  List<EventCacheItem> getEventsForDateDirect(String dateKey) {
    if (!_cacheService.isLoaded) {
      return [];
    }

    return _filteredEvents.groupedByDate[dateKey] ?? [];
  }

  /// Verificar si hay eventos para una fecha específica - O(1)
  bool hasEventsForDate(String dateKey) {
    return _filteredEvents.groupedByDate.containsKey(dateKey) &&
        _filteredEvents.groupedByDate[dateKey]!.isNotEmpty;
  }
  // === MÉTODOS PRIVADOS ===

  void _applyCurrentFilters() {
    print('🐛 ANTES - Cache loaded: ${_cacheService.isLoaded}');
    print('🐛 ANTES - Cache events: ${_cacheService.allEvents.length}');

    if (!_cacheService.isLoaded) {
      print('⚠️ Cache no cargado, saltando filtros');
      return;
    }

    final globalFilters = MemoryFilters.empty;

    print('🐛 ANTES FILTER - globalFilters: ${globalFilters.description}');

    _filteredEvents = _cacheService.applyFilters(globalFilters);

    print('🐛 DESPUÉS FILTER - _filteredEvents.totalCount: ${_filteredEvents.totalCount}');

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
      // NUEVO: Estadísticas de categorías
      'selectedCategoriesCount': _selectedCategories.length, // NUEVO
      // ELIMINADO: activeCategoriesCount - ya no filtros globales
      'selectedCategories': _selectedCategories.toList(), // NUEVO
      // ELIMINADO: activeCategories - ya no filtros globales
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
    // ELIMINADO: Filtros activos - ya no hay filtros globales
  }
  /// NUEVO: Cambiar días de limpieza para eventos
  Future<void> setEventCleanupDays(int days) async {
  if (_eventCleanupDays != days) {
  _eventCleanupDays = days;

  final repository = EventRepository();
  await repository.updateSetting('cleanup_events_days', days.toString());

  notifyListeners();
  print('🗑️ Días limpieza eventos: $days');
  }
  }

  /// NUEVO: Cambiar días de limpieza para favoritos
  Future<void> setFavoriteCleanupDays(int days) async {
  if (_favoriteCleanupDays != days) {
  _favoriteCleanupDays = days;

  final repository = EventRepository();
  await repository.updateSetting('cleanup_favorites_days', days.toString());

  notifyListeners();
  print('🗑️ Días limpieza favoritos: $days');
  }
  }
}