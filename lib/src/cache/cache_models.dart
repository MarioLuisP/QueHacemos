// lib/src/cache/cache_models.dart

/// Modelo optimizado para cache en memoria
/// Solo 9 campos esenciales para scroll rápido (203 bytes por evento)
class EventCacheItem {
  final int id;
  final String title;
  final String type;
  final String location;
  final String date;
  final String price;
  final String district;
  final int rating;
  final bool isFavorite;

  const EventCacheItem({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.date,
    required this.price,
    required this.district,
    required this.rating,
    required this.isFavorite,
  });

  /// Crear desde Map (viene del JSON/SQLite)
  factory EventCacheItem.fromMap(Map<String, dynamic> map) {
    return EventCacheItem(
      id: map['id'] as int,
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? '',
      location: map['location'] as String? ?? '',
      date: map['date'] as String? ?? '',
      price: map['price'] as String? ?? '',
      district: map['district'] as String? ?? '',
      rating: map['rating'] as int? ?? 0,
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  /// Convertir a Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'location': location,
      'date': date,
      'price': price,
      'district': district,
      'rating': rating,
      'isFavorite': isFavorite,
    };
  }

  /// Copy with para updates (favoritos)
  EventCacheItem copyWith({
    int? id,
    String? title,
    String? type,
    String? location,
    String? date,
    String? price,
    String? district,
    int? rating,
    bool? isFavorite,
  }) {
    return EventCacheItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      date: date ?? this.date,
      price: price ?? this.price,
      district: district ?? this.district,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Igualdad por ID
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventCacheItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Debug string
  @override
  String toString() {
    return 'EventCacheItem(id: $id, title: $title, type: $type)';
  }
}

/// Resultado de filtros para UI
class FilteredEvents {
  final List<EventCacheItem> events;
  final Map<String, List<EventCacheItem>> groupedByDate;
  final int totalCount;
  final String appliedFilters;

  const FilteredEvents({
    required this.events,
    required this.groupedByDate,
    required this.totalCount,
    required this.appliedFilters,
  });

  /// Resultado vacío
  static const FilteredEvents empty = FilteredEvents(
    events: [],
    groupedByDate: {},
    totalCount: 0,
    appliedFilters: 'Sin filtros',
  );
}

/// Filtros para memoria (súper livianos)
class MemoryFilters {
  final Set<String> categories;
  final String searchQuery;
  final DateTime? selectedDate;

  const MemoryFilters({
    this.categories = const {},
    this.searchQuery = '',
    this.selectedDate,
  });

  /// Sin filtros
  static const MemoryFilters empty = MemoryFilters();

  /// Copy with
  MemoryFilters copyWith({
    Set<String>? categories,
    String? searchQuery,
    DateTime? selectedDate,
    bool clearDate = false,
  }) {
    return MemoryFilters(
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
    );
  }

  /// Tiene filtros activos
  bool get hasActiveFilters {
    return categories.isNotEmpty ||
        searchQuery.isNotEmpty ||
        selectedDate != null;
  }

  /// Descripción para UI
  String get description {
    final parts = <String>[];

    if (categories.isNotEmpty) {
      parts.add('${categories.length} categorías');
    }

    if (searchQuery.isNotEmpty) {
      parts.add('Búsqueda: "$searchQuery"');
    }

    if (selectedDate != null) {
      parts.add('Fecha específica');
    }

    return parts.isEmpty ? 'Sin filtros' : parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoryFilters &&
        other.categories == categories &&
        other.searchQuery == searchQuery &&
        other.selectedDate == selectedDate;
  }

  @override
  int get hashCode {
    return Object.hash(categories, searchQuery, selectedDate);
  }
}