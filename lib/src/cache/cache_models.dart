// lib/src/cache/cache_models.dart
// lib/src/cache/cache_models.dart
import 'package:flutter/material.dart'; // NUEVO: Para usar Color
import '../utils/colors.dart';           // NUEVO: Para EventCardColorPalette y CategoryDisplayNames
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
  final bool favorite;
  final String formattedDateForCard; // NUEVO: Fecha precalculada para tarjetas
  final String categoryWithEmoji;    // NUEVO: Categoría con emoji precalculada
  final Color baseColor;             // NUEVO: Color base precalculado
  final Color darkColor;             // NUEVO: Color oscuro precalculado
  final Color textColor;             // NUEVO: Color texto precalculado
  final Color textFaded90;           // NUEVO: Color texto 90% opacity
  final Color textFaded70;           // NUEVO: Color texto 70% opacity
  final Color textFaded30;
  final String premiumEmoji;

  const EventCacheItem({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.date,
    required this.price,
    required this.district,
    required this.rating,
    required this.favorite,
    required this.formattedDateForCard, // NUEVO
    required this.categoryWithEmoji,    // NUEVO
    required this.baseColor,            // NUEVO
    required this.darkColor,            // NUEVO
    required this.textColor,            // NUEVO
    required this.textFaded90,          // NUEVO
    required this.textFaded70,          // NUEVO
    required this.textFaded30,
    required this.premiumEmoji,// NUEVO
  });

  /// Crear desde Map (viene del JSON/SQLite)
  factory EventCacheItem.fromMap(Map<String, dynamic> map, {String theme = 'normal'}) {
    final String dateString = map['date'] as String? ?? '';
    final String typeString = map['type'] as String? ?? '';
    print('🔍 Type from map: "$typeString"');
    // NUEVO: Precalcular fecha formateada
    final String formattedDate = _formatDateForCard(dateString);

    // NUEVO: Precalcular categoría con emoji
    final String categoryEmoji = CategoryDisplayNames.getCategoryWithEmoji(typeString);
    final String premiumEmoji = _calculatePremiumEmoji(map['rating'] as int? ?? 0);
    // NUEVO: Precalcular colores (theme hardcodeado 'normal')
    final optimizedColors = EventCardColorPalette.getOptimizedColors(theme, typeString);
    print('🎨 Assigned color: ${optimizedColors.base}');
    return EventCacheItem(
      id: map['id'] as int,
      title: map['title'] as String? ?? '',
      type: typeString,
      location: map['location'] as String? ?? '',
      date: dateString,
      price: map['price'] as String? ?? '',
      district: map['district'] as String? ?? '',
      rating: map['rating'] as int? ?? 0,
      favorite: (map['favorite'] as int? ?? 0) == 1,  // ← Leer int, convertir a bool
      formattedDateForCard: formattedDate,    // NUEVO: Precalculado
      categoryWithEmoji: categoryEmoji,       // NUEVO: Precalculado
      baseColor: optimizedColors.base,        // NUEVO: Precalculado
      darkColor: optimizedColors.dark,        // NUEVO: Precalculado
      textColor: optimizedColors.text,        // NUEVO: Precalculado
      textFaded90: optimizedColors.textFaded90, // NUEVO: Precalculado
      textFaded70: optimizedColors.textFaded70, // NUEVO: Precalculado
      textFaded30: optimizedColors.textFaded30, // NUEVO: Precalculado
      premiumEmoji: premiumEmoji,
    );
  }

// NUEVO: Método helper para formatear fecha
  static String _formatDateForCard(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final monthAbbrev = _getMonthAbbrev(date.month);
      final timeString = _getTimeString(date);
      return "${date.day} $monthAbbrev$timeString";
    } catch (e) {
      return dateString;
    }
  }
// NUEVO: Helper para emoji premium
  static String _calculatePremiumEmoji(int rating) {
    if (rating >= 400) return ' 💎💎💎💎'; // Platinum 400+
    if (rating >= 300) return ' 💎💎💎';   // Gold 300-399
    if (rating >= 200) return ' 💎💎';     // Silver 200-299
    if (rating >= 100) return ' 💎';      // Bronze 100-199
    return '';                            // Normal 0-99 (string vacío)
  }

// NUEVO: Helper para mes abreviado
  static String _getMonthAbbrev(int month) {
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return months[month] ?? 'mes';
  }

// NUEVO: Helper para hora
  static String _getTimeString(DateTime date) {
    if (date.hour != 0 || date.minute != 0) {
      return " - ${date.hour}:${date.minute.toString().padLeft(2, '0')} hs";
    }
    return "";
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
      'favorite': favorite,
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
   bool? favorite,
    String? theme,
  }) {
    // CAMBIO: Si cambia type o date, recalcular campos dependientes
    final String newType = type ?? this.type;
    final String newDate = date ?? this.date;
    final bool needsRecalculation = (type != null || date != null || theme != null);

    if (needsRecalculation) {
      // NUEVO: Recalcular datos dependientes
      final String formattedDate = _formatDateForCard(newDate);
      final String categoryEmoji = CategoryDisplayNames.getCategoryWithEmoji(newType);
      final optimizedColors = EventCardColorPalette.getOptimizedColors(theme ?? 'normal', newType);

      return EventCacheItem(
        id: id ?? this.id,
        title: title ?? this.title,
        type: newType,
        location: location ?? this.location,
        date: newDate,
        price: price ?? this.price,
        district: district ?? this.district,
        rating: rating ?? this.rating,
        favorite: favorite ?? this.favorite,
        formattedDateForCard: formattedDate,          // NUEVO: Recalculado
        categoryWithEmoji: categoryEmoji,             // NUEVO: Recalculado
        baseColor: optimizedColors.base,              // NUEVO: Recalculado
        darkColor: optimizedColors.dark,              // NUEVO: Recalculado
        textColor: optimizedColors.text,              // NUEVO: Recalculado
        textFaded90: optimizedColors.textFaded90,     // NUEVO: Recalculado
        textFaded70: optimizedColors.textFaded70,     // NUEVO: Recalculado
        textFaded30: optimizedColors.textFaded30,
        premiumEmoji: this.premiumEmoji,// NUEVO: Recalculado
      );
    } else {
      // CAMBIO: Solo cambios simples, mantener campos precalculados
      return EventCacheItem(
        id: id ?? this.id,
        title: title ?? this.title,
        type: this.type,
        location: location ?? this.location,
        date: this.date,
        price: price ?? this.price,
        district: district ?? this.district,
        rating: rating ?? this.rating,
        favorite: favorite ?? this.favorite,
        formattedDateForCard: this.formattedDateForCard,    // CAMBIO: Mantener precalculado
        categoryWithEmoji: this.categoryWithEmoji,          // CAMBIO: Mantener precalculado
        baseColor: this.baseColor,                          // CAMBIO: Mantener precalculado
        darkColor: this.darkColor,                          // CAMBIO: Mantener precalculado
        textColor: this.textColor,                          // CAMBIO: Mantener precalculado
        textFaded90: this.textFaded90,                      // CAMBIO: Mantener precalculado
        textFaded70: this.textFaded70,                      // CAMBIO: Mantener precalculado
        textFaded30: this.textFaded30,
        premiumEmoji: this.premiumEmoji,// CAMBIO: Mantener precalculado
      );
    }
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