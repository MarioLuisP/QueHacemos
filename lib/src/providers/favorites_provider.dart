import 'package:flutter/foundation.dart';
import '../data/repositories/event_repository.dart';
import 'notifications_provider.dart';
import '../services/notification_service.dart';
import '../models/user_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  final EventRepository _repository = EventRepository();
  Set<String> _favoriteIds = {};
  bool _isInitialized = false;
  Function(int eventId, bool isFavorite)? _onFavoriteChanged;

  FavoritesProvider() {
    _initializeAsync();
  }

  bool get isInitialized => _isInitialized;

  void _initializeAsync() {
    init();
  }

  Future<void> init() async {
    await _loadFavoritesFromRepository();
    _isInitialized = true;
    notifyListeners();
  }
  /// Programar notificaciones para hoy únicamente (llamado desde DailyTaskManager)
  Future<void> scheduleNotificationsForToday() async {
    try {
      final favorites = await _repository.getAllFavorites();

      if (favorites.isEmpty) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Formatear fecha de hoy
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

// 🐛 DEBUG TEMPORAL - AGREGAR ESTAS LÍNEAS:
      print('🐛 DEBUG: Sistema hoy = $todayStr');
      print('🐛 DEBUG: Total favoritos = ${favorites.length}');
      // Filtrar solo favoritos de hoy
      final List<Map<String, dynamic>> todayFavorites = [];

      for (final favorite in favorites) {
        final dateStr = favorite['date']?.toString().split('T')[0];

        // 🐛 DEBUG TEMPORAL - AGREGAR ESTA LÍNEA:
        print('🐛 DEBUG: Favorito ${favorite['title']} fecha = $dateStr, comparando con $todayStr');

        if (dateStr != null && dateStr == todayStr) {
          todayFavorites.add(favorite);
        }
      }

      // Programar notificaciones solo para hoy
      if (todayFavorites.isNotEmpty) {
        await NotificationService.scheduleDailyNotification(todayStr, todayFavorites);

        // Badge si hay favoritos hoy
        await NotificationService.setBadge();

        print('✅ Notificaciones programadas para hoy (${todayFavorites.length} eventos)');
      } else {
        print('📅 No hay eventos favoritos para hoy');
      }

    } catch (e) {
      print('❌ Error programando notificaciones para hoy: $e');
    }
  }

  /// Enviar notificación inmediata para recovery (>11 AM)
  Future<void> sendImmediateNotificationForToday() async {
    try {
      final favorites = await _repository.getAllFavorites();
      if (favorites.isEmpty) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final List<Map<String, dynamic>> todayFavorites = [];
      for (final favorite in favorites) {
        final dateStr = favorite['date']?.toString().split('T')[0];
        if (dateStr != null && dateStr == todayStr) {
          todayFavorites.add(favorite);
        }
      }

      if (todayFavorites.isNotEmpty) {
        final message = NotificationService.generateDailyMessage(todayFavorites);
        await NotificationService.showNotification(
          id: "daily_$todayStr".hashCode,
          title: '❤️ Favoritos de hoy ⭐',
          message: message,
          payload: 'daily_reminder:$todayStr',
        );
        await NotificationService.setBadge();
        print('📨 Recovery: Notificación inmediata enviada (${todayFavorites.length} eventos)');
      }
    } catch (e) {
      print('❌ Error en recovery de notificaciones: $e');
    }
  }


  /// Cargar favoritos desde SQLite al startup
  Future<void> _loadFavoritesFromRepository() async {
    try {
      final favorites = await _repository.getAllFavorites();
      _favoriteIds = favorites.map((e) => e['id'].toString()).toSet();
      print('📋 Cargados ${_favoriteIds.length} favoritos desde SQLite');
    } catch (e) {
      print('❌ Error cargando favoritos: $e');
      _favoriteIds = {};
    }
  }

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String eventId) => _favoriteIds.contains(eventId);

  Future<void> toggleFavorite(String eventId, {String? eventTitle}) async {
    try {
      final numericId = int.parse(eventId);
      final wasAdded = await _repository.toggleFavorite(numericId);

      if (wasAdded) {
        _favoriteIds.add(eventId);
        print('❤️ Favorito agregado: $eventId');
      } else {
        _favoriteIds.remove(eventId);
        print('💔 Favorito removido: $eventId');
      }

      _syncWithSimpleHomeProvider(numericId, wasAdded);
      await _sendFavoriteNotification(eventId, wasAdded, eventTitle);

      // NUEVO: Actualizar flag si es para hoy
      await _updateTodayFavoritesFlag();

      notifyListeners();

    } catch (e) {
      print('⚠️ Error toggle favorito $eventId: $e');
    }
  }

// NUEVO: Método para actualizar flag
  Future<void> _updateTodayFavoritesFlag() async {
    try {
      final favorites = await _repository.getAllFavorites();
      final today = DateTime.now().toIso8601String().split('T')[0];

      bool hasFavoritesToday = false;
      for (final favorite in favorites) {
        final dateStr = favorite['date']?.toString().split('T')[0];
        if (dateStr == today) {
          hasFavoritesToday = true;
          break;
        }
      }

      await UserPreferences.setHasFavoritesToday(hasFavoritesToday);
      print('🚩 Flag actualizada: has_favorites_today = $hasFavoritesToday');

    } catch (e) {
      print('⚠️ Error actualizando flag today: $e');
    }
  }

  Future<void> addFavorite(String eventId) async {
    if (!_favoriteIds.contains(eventId)) {
      await toggleFavorite(eventId);
    }
  }

  Future<void> removeFavorite(String eventId) async {
    if (_favoriteIds.contains(eventId)) {
      await toggleFavorite(eventId);
    }
  }

  Future<void> clearFavorites() async {
    try {
      for (final eventId in _favoriteIds.toList()) {
        await _repository.removeFromFavorites(int.parse(eventId));
      }

      _favoriteIds.clear();
      notifyListeners();
      print('🧹 Todos los favoritos eliminados');
    } catch (e) {
      print('❌ Error limpiando favoritos: $e');
    }
  }
  /// Registrar callback para sync con SimpleHomeProvider
  void setOnFavoriteChangedCallback(Function(int eventId, bool isFavorite) callback) {
    _onFavoriteChanged = callback;
  }

  /// Sincronizar cambio con SimpleHomeProvider
  void _syncWithSimpleHomeProvider(int eventId, bool isFavorite) {
    // Usar un callback o método estático para evitar dependencia circular
    // El SimpleHomeProvider se registrará a este callback
    _onFavoriteChanged?.call(eventId, isFavorite);
    print('🔄 Sync ejecutado: evento $eventId = $isFavorite');
  }


// ========== NOTIFICACIONES DE FAVORITOS ========== // NUEVO

  /// Enviar notificación inmediata de favorito (solo campanita)
  Future<void> _sendFavoriteNotification(String eventId, bool isAdded, String? eventTitle) async {
    try {
      final notificationsProvider = NotificationsProvider.instance;
      final title = eventTitle ?? 'Evento'; // Sin query extra

      if (isAdded) {
        await notificationsProvider.addNotification(
          title: '❤️ Evento guardado en favoritos',
          message: title,
          type: 'favorite_added',
          eventCode: eventId,
        );
      } else {
        await notificationsProvider.addNotification(
          title: '💔 Favorito removido',
          message: '$title removido de favoritos',
          type: 'favorite_removed',
          eventCode: eventId,
        );
      }

      print('✅ Notificación de favorito enviada - sin query extra');

    } catch (e) {
      print('⚠️ Error enviando notificación de favorito: $e');
    }
  }



  List<Map<String, dynamic>> filterFavoriteEvents(List<Map<String, dynamic>> allEvents) { // MANTENER: sin cambios
    return allEvents.where((event) => isFavorite(event['id']?.toString() ?? '')).toList();
  }
}