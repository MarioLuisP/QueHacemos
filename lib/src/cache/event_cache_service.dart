// lib/src/cache/event_cache_service.dart

import 'cache_models.dart';
import '../data/repositories/event_repository.dart';

/// Servicio de cache en memoria - Corazón del sistema

class EventCacheService {
  static final EventCacheService _instance = EventCacheService._internal();
  factory EventCacheService() => _instance;
  EventCacheService._internal();

  // Cache en memoria
  List<EventCacheItem> _cache = [];
  bool _isLoaded = false;
  DateTime? _lastLoadTime;

  // Estructuras auxiliares para lookup O(1)
  Map<String, List<EventCacheItem>> _eventsByDate = {};  // "2025-07-23" → [events]
  Map<String, int> _eventCountsByDate = {};              // "2025-07-23" → count

  // Getters públicos
  List<EventCacheItem> get allEvents => List.unmodifiable(_cache);
  bool get isLoaded => _isLoaded;
  int get eventCount => _cache.length;
  DateTime? get lastLoadTime => _lastLoadTime;

  /// Cargar cache desde fuente de datos (UNA vez al startup)
  Future<void> loadCache({String theme = 'normal'}) async {
    if (_isLoaded) {
      print('🔄 Cache ya cargado, omitiendo...');
      return;
    }

    try {
      print('📥 Cargando cache en memoria...');

      // TODO: En futuro será desde SQLite
      final repository = EventRepository();
      final mockData = await repository.getAllEvents();

      // Convertir a EventCacheItem
      _cache = mockData.map((map) => EventCacheItem.fromMap(map, theme: theme)).toList();

      // Ordenar por fecha (más recientes primero)
      _cache.sort((a, b) => a.date.compareTo(b.date));
      _precalculateGroups();

      _isLoaded = true;
      _lastLoadTime = DateTime.now();

      print('✅ Cache cargado: ${_cache.length} eventos en memoria');
      print('📊 Memoria usada: ~${_cache.length * 203} bytes');

    } catch (e) {
      print('❌ Error cargando cache: $e');
      _cache = [];
      _isLoaded = false;
      rethrow;
    }
  }

  /// Precalcular agrupaciones para lookup O(1)
  void _precalculateGroups() {
    print('🔢 Precalculando agrupaciones...');

    // Limpiar estructuras anteriores
    _eventsByDate.clear();
    _eventCountsByDate.clear();

    // Agrupar eventos por fecha
    for (final event in _cache) {
      final dateKey = event.date.length >= 10
          ? event.date.substring(0, 10)  // Extraer yyyy-MM-dd
          : event.date;

      _eventsByDate.putIfAbsent(dateKey, () => []).add(event);
    }

    // Precalcular counts
    _eventCountsByDate = _eventsByDate.map((date, events) =>
        MapEntry(date, events.length));

    print('✅ Agrupaciones precalculadas: ${_eventsByDate.keys.length} fechas');
  }

  /// Aplicar filtros y retornar resultado estructurado (CONSOLIDADO desde MemoryFilterService)
  FilteredEvents filter({
    Set<String>? categories,
    String? searchQuery,
    DateTime? selectedDate,
  }) {
    if (!_isLoaded) {
      print('⚠️ Cache no cargado, retornando resultado vacío');
      return FilteredEvents.empty;
    }

    List<EventCacheItem> filtered = _cache;

    // Filtro por categorías
    if (categories != null && categories.isNotEmpty) {
      filtered = filtered.where((event) {
        return categories.contains(event.type.toLowerCase());
      }).toList();
    }

    // Filtro por búsqueda
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(query) ||
            event.location.toLowerCase().contains(query) ||
            event.district.toLowerCase().contains(query);
      }).toList();
    }

    // Filtro por fecha
    if (selectedDate != null) {
      final dateString = selectedDate.toIso8601String().substring(0, 10);
      filtered = filtered.where((event) {
        return event.date.startsWith(dateString);
      }).toList();
    }
    filtered.sort((a, b) {
      // 1. Rating primero (mayor rating = sponsors primero)
      final ratingComparison = b.rating.compareTo(a.rating);
      if (ratingComparison != 0) return ratingComparison;

      // 2. Categoría alfabéticamente (organización visual)
      final categoryComparison = a.type.compareTo(b.type);
      if (categoryComparison != 0) return categoryComparison;

      // 3. Hora más temprana primero (practicidad del usuario)
      return a.date.compareTo(b.date); // date incluye hora completa
    });

    // Agrupar por fecha
    final groupedByDate = getGroupedByDate(filtered);

    // Crear descripción de filtros
    final filterParts = <String>[];
    if (categories != null && categories.isNotEmpty) {
      filterParts.add('${categories.length} categorías');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filterParts.add('Búsqueda: "$searchQuery"');
    }
    if (selectedDate != null) {
      filterParts.add('Fecha específica');
    }
    final description = filterParts.isEmpty ? 'Sin filtros' : filterParts.join(', ');

    return FilteredEvents(
      events: filtered,
      groupedByDate: groupedByDate,
      totalCount: filtered.length,
      appliedFilters: description,
    );
  }

  /// Aplicar filtros con modelo MemoryFilters (compatibilidad con provider)
  FilteredEvents applyFilters(MemoryFilters filters) {
    return filter(
      categories: filters.categories.isEmpty ? null : filters.categories,
      searchQuery: filters.searchQuery.isEmpty ? null : filters.searchQuery,
      selectedDate: filters.selectedDate,
    );
  }

  /// Obtener evento por ID (para verificar existencia)
  EventCacheItem? getEventById(int id) {
    if (!_isLoaded) return null;

    try {
      return _cache.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtener eventos para fecha específica - O(1)
  List<EventCacheItem> getEventsForDate(String dateString) {
    if (!_isLoaded) {
      print('⚠️ Cache no cargado para getEventsForDate');
      return [];
    }

    return _eventsByDate[dateString] ?? []; // Lookup O(1)
  }

  /// Obtener count de eventos para fecha específica - O(1)
  int getEventCountForDate(String dateString) {
    if (!_isLoaded) {
      return 0;
    }

    return _eventCountsByDate[dateString] ?? 0; // Lookup O(1)
  }

  /// Actualizar favorito en cache (llamado por FavoritesProvider)
  bool updateFavoriteInCache(int eventId, bool isFavorite) {
    if (!_isLoaded) return false;

    final index = _cache.indexWhere((event) => event.id == eventId);
    if (index == -1) return false;

    // Update inmediato en cache
    _cache[index] = _cache[index].copyWith(favorite: isFavorite);

    print('💖 Favorito actualizado en cache: $eventId = $isFavorite');

    return true;
  }
  /// Toggle favorito en cache (mantener por compatibilidad)
  bool toggleFavorite(int eventId) {
    if (!_isLoaded) return false;

    final index = _cache.indexWhere((event) => event.id == eventId);
    if (index == -1) return false;

    final currentEvent = _cache[index];
    final newFavoriteState = !currentEvent.favorite;

    // Update inmediato en cache
    _cache[index] = currentEvent.copyWith(favorite: newFavoriteState);

    print('💖 Favorito toggled en cache: $eventId = $newFavoriteState');

    return newFavoriteState;
  }

  /// Obtener eventos agrupados por fecha (para HomePage)
  Map<String, List<EventCacheItem>> getGroupedByDate(List<EventCacheItem> events) {
    final grouped = <String, List<EventCacheItem>>{};

    for (final event in events) {
      // Extraer solo fecha (yyyy-MM-dd)
      final dateKey = event.date.length >= 10
          ? event.date.substring(0, 10)
          : event.date;

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(event);
    }

// OPTIMIZADO: Triple ordenamiento dentro de cada fecha
    grouped.forEach((date, events) {
      events.sort((a, b) {
        // 1. Rating primero (mayor rating = sponsors primero)
        final ratingComparison = b.rating.compareTo(a.rating);
        if (ratingComparison != 0) return ratingComparison;

        // 2. Categoría alfabéticamente (organización visual)
        final categoryComparison = a.type.compareTo(b.type);
        if (categoryComparison != 0) return categoryComparison;

        // 3. Hora más temprana primero (practicidad del usuario)
        return a.date.compareTo(b.date); // date incluye hora completa
      });
    });

    return grouped;
  }
  /// Obtener fechas ordenadas (hoy primero, luego futuras)
  List<String> getSortedDateKeys(Map<String, List<EventCacheItem>> grouped) {
    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final tomorrowString = today.add(Duration(days: 1)).toIso8601String().substring(0, 10);
    final dates = grouped.keys.where((date) => date.compareTo(todayString) >= 0).toList();
    dates.sort((a, b) {
      // Hoy primero
      if (a == todayString) return -2;
      if (b == todayString) return 2;

      // Mañana segundo
      if (a == tomorrowString) return -1;
      if (b == tomorrowString) return 1;

      // Resto por orden cronológico
      return a.compareTo(b);
    });

    return dates;
  }

  /// Obtener títulos de sección formateados (para UI) - MIGRADO desde MemoryFilterService
  String getSectionTitle(String dateKey) {
    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final tomorrowString = today.add(Duration(days: 1)).toIso8601String().substring(0, 10);

    if (dateKey == todayString) {
      return 'Hoy';
    } else if (dateKey == tomorrowString) {
      return 'Mañana';
    } else {
      // Convertir yyyy-MM-dd a formato legible
      try {
        final date = DateTime.parse(dateKey);
        final weekdays = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
        final months = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
          'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

        final weekday = weekdays[date.weekday];
        final day = date.day;
        final month = months[date.month];

        return '$weekday, $day de $month';
      } catch (e) {
        return dateKey; // Fallback
      }
    }
  }

  /// Recargar cache (para testing o refresh manual)
  Future<void> reloadCache() async {
    print('🔄 Forzando recarga de cache...');
    _isLoaded = false;
    _cache.clear();
    _eventsByDate.clear();      // Limpiar lookup tables
    _eventCountsByDate.clear(); // Limpiar lookup tables
    await loadCache();
  }

  /// Recalcular colores de todos los eventos para nuevo tema
  void recalculateColorsForTheme(String theme) {
    if (!_isLoaded) {
      print('⚠️ Cache no cargado, no se pueden recalcular colores');
      return;
    }

    print('🎨 Recalculando colores para tema: $theme');

    for (int i = 0; i < _cache.length; i++) {
      _cache[i] = _cache[i].copyWith(theme: theme);
    }

    print('✅ Colores recalculados para ${_cache.length} eventos');
  }

  /// Limpiar cache (para testing)
  void clearCache() {
    print('🧹 Limpiando cache...');
    _cache.clear();
    _isLoaded = false;
    _lastLoadTime = null;
  }

  /// Estadísticas del cache (para debug)
  Map<String, dynamic> getStats() {
    if (!_isLoaded) {
      return {
        'loaded': false,
        'eventCount': 0,
        'memoryUsage': 0,
      };
    }

    final categoryCount = <String, int>{};
    for (final event in _cache) {
      categoryCount[event.type] = (categoryCount[event.type] ?? 0) + 1;
    }

    return {
      'loaded': true,
      'eventCount': _cache.length,
      'memoryUsage': '${_cache.length * 203} bytes',
      'lastLoadTime': _lastLoadTime?.toIso8601String(),
      'categories': categoryCount,
      'favoriteCount': _cache.where((e) => e.favorite).length,
    };
  }

  /// Debug: imprimir contenido del cache
  void debugPrintCache() {
    if (!_isLoaded) {
      print('❌ Cache no cargado');
      return;
    }

    print('📋 Cache Debug:');
    for (int i = 0; i < _cache.length; i++) {
      final event = _cache[i];
      print('  [$i] ${event.title} (${event.type}) - ${event.date}');
    }
  }
}