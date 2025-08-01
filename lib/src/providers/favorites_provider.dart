import 'package:flutter/foundation.dart';
import '../data/repositories/event_repository.dart';
import 'notifications_provider.dart';
import '../services/notification_service.dart';

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

  Future<void> toggleFavorite(String eventId) async {
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

      // Sync con SimpleHomeProvider
      _syncWithSimpleHomeProvider(numericId, wasAdded);

      // Enviar notificación de favorito
      await _sendFavoriteNotification(eventId, wasAdded);

      notifyListeners();

    } catch (e) {
      print('❌ Error toggle favorito $eventId: $e');
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

  /// NUEVO: Enviar notificaciones relacionadas con favoritos + scheduling
  Future<void> _sendFavoriteNotification(String eventId, bool isAdded) async {
    try {
      final notificationsProvider = NotificationsProvider.instance;
      final eventDetails = await _getEventDetails(eventId);

      if (isAdded) {
        // Notificación en el badge
        await notificationsProvider.addNotification(
          title: '❤️ Evento guardado en favoritos',
          message: '${eventDetails?['title'] ?? 'Evento'} - ${eventDetails?['date'] ?? 'Sin fecha'}',
          type: 'favorite_added',
          icon: '⭐',
          eventCode: eventId,
        );

        // Programar recordatorios automáticos
        if (eventDetails != null) {
          await NotificationService.scheduleFavoriteReminders(
            eventId: eventId,
            eventDetails: eventDetails,
          );
        }
      } else {
        // Notificación en el badge
        await notificationsProvider.addNotification(
          title: '💔 Favorito removido',
          message: '${eventDetails?['title'] ?? 'Evento'} removido de favoritos',
          type: 'favorite_removed',
          icon: '🗑️',
          eventCode: eventId,
        );

        // Cancelar recordatorios programados
        await NotificationService.cancelFavoriteReminders(eventId);
      }
    } catch (e) {
      print('⚠️ Error enviando notificación de favorito: $e');
    }
  }
  /// NUEVO: Obtener detalles de un evento específico
  Future<Map<String, dynamic>?> _getEventDetails(String eventId) async {
    try {
      final numericId = int.parse(eventId);
      return await _repository.getEventById(numericId);
    } catch (e) {
      print('⚠️ Error obteniendo detalles del evento $eventId: $e');
      return null;
    }
  }
  List<Map<String, dynamic>> filterFavoriteEvents(List<Map<String, dynamic>> allEvents) { // MANTENER: sin cambios
    return allEvents.where((event) => isFavorite(event['id']?.toString() ?? '')).toList();
  }
}