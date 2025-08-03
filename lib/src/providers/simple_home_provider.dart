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
  bool _isInitializing = false; // NUEVO: Flag para evitar doble inicialización
  bool _isInitialized = false;
// ✅ SIMPLIFICADO: Solo filtros que realmente se usan globalmente
  String _currentSearchQuery = '';
  DateTime? _currentSelectedDate;
  // NUEVO: Propiedades para filtros de categorías
  Set<String> _selectedCategories = {}; // NUEVO: categorías habilitadas en Settings
  String _theme = 'normal'; // NUEVO: Tema actual de la app
  DateTime? _lastSelectedDate; // NUEVO: Para persistencia de Calendar

  // Getters para filtros actuales
  String get currentSearchQuery => _currentSearchQuery;
  DateTime? get currentSelectedDate => _currentSelectedDate;

// Getters para datos del cache
  List<EventCacheItem> get events => _cacheService.allEvents;
  Map<String, List<EventCacheItem>> get groupedEvents => _cacheService.getGroupedByDate(_cacheService.allEvents);
  int get eventCount => _cacheService.eventCount;
// NUEVO: Propiedades para limpieza automática
  int _eventCleanupDays = 3;
  int _favoriteCleanupDays = 7;

  SimpleHomeProvider(); // CAMBIO: Constructor limpio sin llamadas async

  // Getters públicos
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // NUEVO: Getters para filtros de categorías
  Set<String> get selectedCategories => _selectedCategories; // NUEVO
  String get theme => _theme;
  DateTime? get lastSelectedDate => _lastSelectedDate;
  // NUEVO: Getters para limpieza automática
  int get eventCleanupDays => _eventCleanupDays;
  int get favoriteCleanupDays => _favoriteCleanupDays;

  /// Inicializar provider (cargar cache + preferencias)
  Future<void> initialize() async {
    // NUEVO: Protección contra doble ejecución
    if (_isInitializing || _isInitialized) {
      print('⏭️ Initialize ya ejecutado/ejecutándose');
      return;
    }

    _isInitializing = true; // NUEVO: Marcar como iniciando

    try { // NUEVO: Error handling robusto
      // Cargar preferencias primero
      await _loadAllPreferences();

      if (_cacheService.isLoaded) {
        print('✅ Cache ya cargado');
        _isInitialized = true; // NUEVO: Marcar como inicializado
        return; // CAMBIO: Salir aquí, el finally limpiará _isInitializing
      }

      _setLoading(true);

      // Cargar cache desde SQLite
      await _cacheService.loadCache(theme: _theme);

      _setLoading(false);
      _isInitialized = true; // NUEVO: Marcar como inicializado exitosamente
      print('✅ SimpleHomeProvider inicializado: ${_cacheService.eventCount} eventos');

    } catch (e) {
      _setError('Error cargando eventos: $e');
      print('❌ Error en SimpleHomeProvider.initialize(): $e');
      rethrow; // CAMBIO: usar rethrow en lugar de throw;
    } finally {
      _isInitializing = false; // NUEVO: Limpiar flag independientemente del resultado
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
    return _cacheService.filter(
      searchQuery: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
    ).events;
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
  }

  /// NUEVO: Toggle categoría seleccionada (para Settings)
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

    await _saveAllPreferences(); // NUEVO
    notifyListeners(); // NUEVO
    print('🔄 Categorías restablecidas a default'); // NUEVO
  } // NUEVO

  /// Cambiar búsqueda
  void setSearchQuery(String query) {
    print('🔍 Cambiando búsqueda: "$query"');

    _currentSearchQuery = query;
    notifyListeners();
  }
  /// NUEVO: Cambiar tema y recalcular colores
  Future<void> setTheme(String theme) async {
    if (_theme != theme) {
      _theme = theme;

      // Recalcular colores del cache
      _cacheService.recalculateColorsForTheme(theme);

      // Guardar preferencias
      await _saveAllPreferences();

      notifyListeners();

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

    _currentSelectedDate = date;
    notifyListeners();
  }

  /// Limpiar todos los filtros
  void clearAllFilters() {
    print('🧹 Limpiando todos los filtros');

    _currentSearchQuery = '';
    _currentSelectedDate = null;
    notifyListeners();
  }


  /// NUEVO: Sincronizar favorito en cache (llamado por FavoritesProvider)
  void syncFavoriteInCache(int eventId, bool isFavorite) {
    final updated = _cacheService.updateFavoriteInCache(eventId, isFavorite);
    if (updated) {
      notifyListeners(); // Refresh UI para consistencia
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
    final grouped = _cacheService.getGroupedByDate(_cacheService.allEvents);
    return _cacheService.getSortedDateKeys(grouped);
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
  /*Future<List<EventCacheItem>> getEventsForDate(DateTime date) async {
    if (!_cacheService.isLoaded) {
      await initialize();
    }

    final dateString = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return _cacheService.getEventsForDate(dateString);
  }🔥🔥🔥*/

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
  /*List<EventCacheItem> getEventsForDateDirect(String dateKey) {
    if (!_cacheService.isLoaded) {
      return [];
    }

    return _cacheService.getEventsForDate(dateKey);
  }🔥🔥🔥*/

  /// Verificar si hay eventos para una fecha específica - O(1)
  bool hasEventsForDate(String dateKey) {
    return _cacheService.getEventCountForDate(dateKey) > 0;
  }
  // === MÉTODOS PRIVADOS ===


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
    notifyListeners();
  }
  // === DEBUG ===

  /// Estadísticas para debug
  Map<String, dynamic> getDebugStats() {
    return {
      'cacheLoaded': _cacheService.isLoaded,
      'cacheEventCount': _cacheService.eventCount,
      'currentSearchQuery': _currentSearchQuery,
      'currentSelectedDate': _currentSelectedDate?.toString(),
      'isLoading': _isLoading,
      'hasError': _errorMessage != null,
      'selectedCategoriesCount': _selectedCategories.length,
      'selectedCategories': _selectedCategories.toList(),
    };
  }
  /// Imprimir debug
  void debugPrint() {
    final stats = getDebugStats();
    print('🏠 SimpleHomeProvider Debug:');
    print('  Cache cargado: ${stats['cacheLoaded']}');
    print('  Eventos en cache: ${stats['cacheEventCount']}');
    print('  Búsqueda actual: "${stats['currentSearchQuery']}"');
    print('  Fecha seleccionada: ${stats['currentSelectedDate']}');
    print('  Categorías seleccionadas: ${stats['selectedCategoriesCount']} ${stats['selectedCategories']}');
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