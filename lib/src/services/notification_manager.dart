import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../providers/favorites_provider.dart';
import '../models/user_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  bool _isInitialized = false;


  /// Inicializa el NotificationManager
  Future<void> initialize() async {
    if (_isInitialized) return;

// Verificar solo si las notificaciones están habilitadas
    final notificationsEnabled = await UserPreferences.getNotificationsReady();
    if (notificationsEnabled) {
      // Observar estado de OneSignal con API correcta
      OneSignal.User.pushSubscription.addObserver((state) {
        print("🔍 OBSERVER - Current ID: ${state.current.id}, Token: ${state.current.token}, OptedIn: ${state.current.optedIn}");

        if (state.current.id != null && state.current.optedIn) {
          // Registrar listeners solo cuando OneSignal esté listo
          OneSignal.Notifications.addForegroundWillDisplayListener((event) {
            print("📱 Push recibido - app en foreground");
            executeRecovery();
            event.preventDefault();
          });

          OneSignal.Notifications.addClickListener((event) async {
            print("👆 Usuario tocó notificación push");
            if (await _needsExecutionToday()) {
              print("🔄 Ejecutando recovery por click - primera vez hoy");
              await executeRecovery();
              await _markExecutedToday();
            }
          });

          print("✅ Listeners registrados con ID: ${state.current.id}");
        }
      });
    }

    _isInitialized = true;
  }

  /// Verificar recovery en startup de app
  Future<void> checkOnAppOpen() async {
    if (!_isInitialized) await initialize();
    // AGREGAR ESTAS LÍNEAS PARA HOT RELOAD
    final oneSignalReady = await UserPreferences.getOneSignalInitialized();
    if (oneSignalReady) {
      final userId = OneSignal.User.pushSubscription.id;
      final token = OneSignal.User.pushSubscription.token;
      print('🔑 HOT RELOAD - OneSignal User ID: $userId');
      print('🎯 HOT RELOAD - OneSignal Token: $token');
    }
    final now = DateTime.now();

    try {
      // Solo después de las 6 AM y si necesita ejecución hoy
      if (now.hour >= 6 && await _needsExecutionToday()) {
        print('🔔 Recovery automático necesario, ejecutando...');
        await executeRecovery();
        await _markExecutedToday();
      } else {
        print('🔔 Recovery no necesario o fuera de horario');
      }
    } catch (e) {
      print('❌ Error en recovery check de NotificationManager: $e');
    }
  }

  /// Ejecuta el recovery de notificaciones
  /// Extraído de DailyTaskManager case TaskType.notifications
  Future<bool> executeRecovery() async {
    try {
      // Verificar si las notificaciones están habilitadas
      final ready = await UserPreferences.getNotificationsReady();
      if (!ready) {
        print('🔔 Notificaciones no habilitadas, saltando recovery');
        return true; // No es error, simplemente no están habilitadas
      }

      // Esperar a que NotificationService esté inicializado
      await NotificationService.waitForInitialization();

      final now = DateTime.now();
      final favoritesProvider = FavoritesProvider();

      // Lógica de horarios: después de las 11 AM = inmediato, 💥💥💥💥💥💥
      if (now.hour >= 1) {
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

  /// Verificar si necesita ejecución hoy
  Future<bool> _needsExecutionToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastExecution = prefs.getString('last_notification_recovery');

      if (lastExecution == null) return true;

      final lastDate = DateTime.parse(lastExecution);
      final today = DateTime.now();

      return !_isSameDay(lastDate, today);
    } catch (e) {
      print('❌ Error verificando timestamp de recovery: $e');
      return true; // En caso de error, ejecutar por seguridad
    }
  }

  /// Marcar como ejecutado hoy
  Future<void> _markExecutedToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notification_recovery', DateTime.now().toIso8601String());
      print('✅ Recovery de notificaciones marcado como ejecutado hoy');
    } catch (e) {
      print('❌ Error guardando timestamp de recovery: $e');
    }
  }

  /// Verificar si dos fechas son el mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Método de testing para forzar ejecución
  Future<void> testExecuteRecovery() async {
    await executeRecovery();
  }

  /// Reset timestamp para testing
  Future<void> resetRecoveryTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_notification_recovery');
    print('🔄 Timestamp de recovery reseteado para testing');
  }

  /// Estado de debug para monitoreo
  Future<Map<String, dynamic>> getDebugState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastExecution = prefs.getString('last_notification_recovery');
    final needsExecution = await _needsExecutionToday();

    return {
      'initialized': _isInitialized,
      'current_time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'notifications_ready': await UserPreferences.getNotificationsReady(),
      'last_recovery': lastExecution ?? 'never',
      'needs_execution': needsExecution,
      'hour_check': DateTime.now().hour >= 6,
    };
  }

  /// Limpieza al cerrar la app
  void dispose() {
    // Cleanup si es necesario en el futuro
  }
}