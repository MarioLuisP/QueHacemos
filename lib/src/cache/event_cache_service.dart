// lib/src/cache/event_cache_service.dart

import 'cache_models.dart';
import '../mock/mock_events.dart';

/// Servicio de cache en memoria - Corazón del sistema
/// Maneja 203KB de eventos para scroll 90Hz
class EventCacheService {
  static final EventCacheService _instance = EventCacheService._internal();
  factory EventCacheService() => _instance;
  EventCacheService._internal();

  // Cache en memoria (203KB max)
  List<EventCacheItem> _cache = [];
  bool _isLoaded = false;
  DateTime? _lastLoadTime;

  // Getters públicos
  List<EventCacheItem> get allEvents => List.unmodifiable(_cache);
  bool get isLoaded => _isLoaded;
  int get eventCount => _cache.length;
  DateTime? get lastLoadTime => _lastLoadTime;

  /// Cargar cache desde fuente de datos (UNA vez al startup)
  Future<void> loadCache() async {
    if (_isLoaded) {
      print('🔄 Cache ya cargado, omitiendo...');
      return;
    }

    try {
      print('📥 Cargando cache en memoria...');

      // TODO: En futuro será desde SQLite
      // final repository = CacheRepository();
      // final data = await repository.getCacheData();

      // Por ahora: mock data
      final mockData = MockEvents.cacheEvents;

      // Convertir a EventCacheItem
      _cache = mockData.map((map) => EventCacheItem.fromMap(map)).toList();

      // Ordenar por fecha (más recientes primero)
      _cache.sort((a, b) => a.date.compareTo(b.date));

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

  /// Filtrar eventos en memoria pura (microsegundos)
  List<EventCacheItem> filter({
    Set<String>? categories,
    String? searchQuery,
    DateTime? selectedDate,
  }) {
    if (!_isLoaded) {
      print('⚠️ Cache no cargado, retornando lista vacía');
      return [];
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

    return filtered;
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

  /// Toggle favorito en cache (update inmediato)
  bool toggleFavorite(int eventId) {
    if (!_isLoaded) return false;

    final index = _cache.indexWhere((event) => event.id == eventId);
    if (index == -1) return false;

    final currentEvent = _cache[index];
    final newFavoriteState = !currentEvent.isFavorite;

    // Update inmediato en cache
    _cache[index] = currentEvent.copyWith(isFavorite: newFavoriteState);

    print('💖 Favorito toggled en cache: $eventId = $newFavoriteState');

    // TODO: Async update a SQLite
    // _updateFavoriteInDatabase(eventId, newFavoriteState);

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

    return grouped;
  }

  /// Obtener fechas ordenadas (hoy primero, luego futuras)
  List<String> getSortedDateKeys(Map<String, List<EventCacheItem>> grouped) {
    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final tomorrowString = today.add(Duration(days: 1)).toIso8601String().substring(0, 10);

    final dates = grouped.keys.toList();

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

  /// Recargar cache (para testing o refresh manual)
  Future<void> reloadCache() async {
    print('🔄 Forzando recarga de cache...');
    _isLoaded = false;
    _cache.clear();
    await loadCache();
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
      'favoriteCount': _cache.where((e) => e.isFavorite).length,
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