import 'dart:async';
import 'notification_service.dart';
import '../providers/favorites_provider.dart';
import '../models/user_preferences.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  bool _isInitialized = false;

  /// Inicializa el NotificationManager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicialización si es necesaria en el futuro
    _isInitialized = true;
  }

  /// Ejecuta el recovery de notificaciones
  /// Extraído de DailyTaskManager case TaskType.notifications
  Future<bool> executeRecovery() async {
    try {
      // Verificar si las notificaciones están habilitadas
      final ready = await UserPreferences.getNotificationsReady();
      if (!ready) {
        return true; // No es error, simplemente no están habilitadas
      }

      // Esperar a que NotificationService esté inicializado
      await NotificationService.waitForInitialization();

      final now = DateTime.now();
      final favoritesProvider = FavoritesProvider();

      // Lógica de horarios: después de las 11 AM = inmediato, antes = programado
      if (now.hour >= 11) {
        await favoritesProvider.sendImmediateNotificationForToday();
      } else {
        await favoritesProvider.scheduleNotificationsForToday();
      }

      return true;

    } catch (e) {
      // Log del error si es necesario
      print('❌ Error en NotificationManager.executeRecovery: $e');
      return false;
    }
  }

  /// Método de testing para forzar ejecución
  Future<void> testExecuteRecovery() async {
    await executeRecovery();
  }

  /// Estado de debug para monitoreo
  Map<String, dynamic> getDebugState() {
    return {
      'initialized': _isInitialized,
      'current_time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'notifications_ready': 'check_user_preferences',
    };
  }

  /// Limpieza al cerrar la app
  void dispose() {
    // Cleanup si es necesario en el futuro
  }
}