// lib/src/cache/memory_filter_service.dart

import 'cache_models.dart';
import 'event_cache_service.dart';

/// Servicio de filtros en memoria pura
/// Zero queries, zero async - solo operaciones sobre arrays
class MemoryFilterService {
  static final MemoryFilterService _instance = MemoryFilterService._internal();
  factory MemoryFilterService() => _instance;
  MemoryFilterService._internal();

  final EventCacheService _cacheService = EventCacheService();

  /// Aplicar filtros y retornar resultado estructurado
  FilteredEvents applyFilters(MemoryFilters filters) {
    // Obtener eventos desde cache
    final allEvents = _cacheService.allEvents;

    if (allEvents.isEmpty) {
      print('⚠️ Cache vacío, retornando resultado vacío');
      return FilteredEvents.empty;
    }

    // Aplicar filtros en memoria
    List<EventCacheItem> filtered = allEvents;

    // 1. Filtro por categorías
    if (filters.categories.isNotEmpty) {
      filtered = _filterByCategories(filtered, filters.categories);
    }

    // 2. Filtro por búsqueda
    if (filters.searchQuery.isNotEmpty) {
      filtered = _filterBySearch(filtered, filters.searchQuery);
    }

    // 3. Filtro por fecha
    if (filters.selectedDate != null) {
      filtered = _filterByDate(filtered, filters.selectedDate!);
    }

    // Agrupar por fecha
    final groupedByDate = _groupEventsByDate(filtered);

    return FilteredEvents(
      events: filtered,
      groupedByDate: groupedByDate,
      totalCount: filtered.length,
      appliedFilters: filters.description,
    );
  }

  /// Filtro por categorías (en memoria)
  List<EventCacheItem> _filterByCategories(
      List<EventCacheItem> events,
      Set<String> categories,
      ) {
    // Normalizar categorías a lowercase para comparación
    final normalizedCategories = categories.map((c) => c.toLowerCase()).toSet();

    return events.where((event) {
      return normalizedCategories.contains(event.type.toLowerCase());
    }).toList();
  }

  /// Filtro por búsqueda (título, location, district)
  List<EventCacheItem> _filterBySearch(
      List<EventCacheItem> events,
      String searchQuery,
      ) {
    final query = searchQuery.toLowerCase().trim();

    if (query.isEmpty) return events;

    return events.where((event) {
      return event.title.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.district.toLowerCase().contains(query);
    }).toList();
  }

  /// Filtro por fecha específica
  List<EventCacheItem> _filterByDate(
      List<EventCacheItem> events,
      DateTime selectedDate,
      ) {
    final dateString = selectedDate.toIso8601String().substring(0, 10); // yyyy-MM-dd

    return events.where((event) {
      return event.date.startsWith(dateString);
    }).toList();
  }

  /// Agrupar eventos por fecha
  Map<String, List<EventCacheItem>> _groupEventsByDate(List<EventCacheItem> events) {
    final grouped = <String, List<EventCacheItem>>{};

    for (final event in events) {
      final dateKey = _extractDateKey(event.date);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(event);
    }

    // Ordenar eventos dentro de cada fecha por hora
    for (final dateEvents in grouped.values) {
      dateEvents.sort((a, b) => a.date.compareTo(b.date));
    }

    return grouped;
  }

  /// Extraer clave de fecha del string ISO
  String _extractDateKey(String dateString) {
    if (dateString.length >= 10) {
      return dateString.substring(0, 10); // yyyy-MM-dd
    }
    return dateString;
  }

  /// Obtener fechas ordenadas con prioridad para hoy/mañana
  List<String> getSortedDateKeys(Map<String, List<EventCacheItem>> grouped) {
    return _cacheService.getSortedDateKeys(grouped);
  }

  /// Filtros rápidos predefinidos

  /// Solo eventos de hoy
  FilteredEvents getTodayEvents() {
    final today = DateTime.now();
    final filters = MemoryFilters(selectedDate: today);
    return applyFilters(filters);
  }

  /// Solo eventos de mañana
  FilteredEvents getTomorrowEvents() {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final filters = MemoryFilters(selectedDate: tomorrow);
    return applyFilters(filters);
  }

  /// Solo favoritos
  FilteredEvents getFavoriteEvents() {
    final allEvents = _cacheService.allEvents;
    final favorites = allEvents.where((event) => event.favorite).toList();

    final groupedByDate = _groupEventsByDate(favorites);

    return FilteredEvents(
      events: favorites,
      groupedByDate: groupedByDate,
      totalCount: favorites.length,
      appliedFilters: 'Solo favoritos',
    );
  }

  /// Eventos por categoría específica
  FilteredEvents getEventsByCategory(String category) {
    final filters = MemoryFilters(categories: {category.toLowerCase()});
    return applyFilters(filters);
  }

  /// Búsqueda rápida
  FilteredEvents searchEvents(String query) {
    final filters = MemoryFilters(searchQuery: query);
    return applyFilters(filters);
  }

  /// Obtener títulos de sección formateados (para UI)
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

  /// Estadísticas de filtros (para debug)
  Map<String, dynamic> getFilterStats() {
    final allEvents = _cacheService.allEvents;

    if (allEvents.isEmpty) {
      return {'totalEvents': 0};
    }

    // Contar por categorías
    final categoryCount = <String, int>{};
    for (final event in allEvents) {
      categoryCount[event.type] = (categoryCount[event.type] ?? 0) + 1;
    }

    // Contar por fechas
    final dateCount = <String, int>{};
    for (final event in allEvents) {
      final dateKey = _extractDateKey(event.date);
      dateCount[dateKey] = (dateCount[dateKey] ?? 0) + 1;
    }

    // Otros stats
    final favoriteCount = allEvents.where((e) => e.favorite).length;
    final uniqueDates = dateCount.keys.length;
    final uniqueCategories = categoryCount.keys.length;

    return {
      'totalEvents': allEvents.length,
      'favoriteCount': favoriteCount,
      'uniqueDates': uniqueDates,
      'uniqueCategories': uniqueCategories,
      'categoryBreakdown': categoryCount,
      'dateBreakdown': dateCount,
    };
  }

  /// Debug: imprimir estadísticas
  void debugPrintStats() {
    final stats = getFilterStats();
    print('📊 Memory Filter Stats:');
    print('  Total eventos: ${stats['totalEvents']}');
    print('  Favoritos: ${stats['favoriteCount']}');
    print('  Fechas únicas: ${stats['uniqueDates']}');
    print('  Categorías únicas: ${stats['uniqueCategories']}');
    print('  Por categoría: ${stats['categoryBreakdown']}');
  }
}