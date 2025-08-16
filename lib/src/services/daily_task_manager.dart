// lib/src/services/daily_task_manager.dart

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../sync/sync_service.dart';
import '../providers/favorites_provider.dart';

/// Callback dispatcher para WorkManager
/// Debe estar fuera de la clase y marcado con @pragma
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 WorkManager ejecutando task: $task');

    switch (task) {
      case 'daily-sync':
        return await _executeWorkManagerSync();
      case 'daily-notifications':
        return await _executeWorkManagerNotifications();
      default:
        print('⚠️ Task desconocido: $task');
        return false;
    }
  });
}

/// Ejecutar sync desde WorkManager
Future<bool> _executeWorkManagerSync() async {
  try {
    final today = _getTodayString();
    final lastSync = await _getLastSyncTimestamp();

    // Verificar si ya hay sync hoy
    if (lastSync != null) {
      final lastSyncDate = DateTime.parse(lastSync);
      final lastSyncDay = _getTodayString(lastSyncDate);

      if (lastSyncDay == today) {
        print('✅ Sync ya completado hoy');
        return true;
      }
    }

    print('🔄 Ejecutando sync desde WorkManager...');
    final syncResult = await SyncService().performAutoSync();

    if (syncResult.success) {
      await _saveSuccessfulSyncTimestamp();
      print('✅ WorkManager sync exitoso');
      return true;
    } else {
      print('❌ WorkManager sync falló: ${syncResult.error}');
      return false;
    }

  } catch (e) {
    print('❌ Error en WorkManager sync: $e');
    return false;
  }
}

/// Ejecutar notificaciones desde WorkManager
Future<bool> _executeWorkManagerNotifications() async {
  try {
    final today = _getTodayString();
    final lastNotif = await _getLastNotificationTimestamp();

    // Verificar si ya hay notificaciones hoy
    if (lastNotif != null) {
      final lastNotifDate = DateTime.parse(lastNotif);
      final lastNotifDay = _getTodayString(lastNotifDate);

      if (lastNotifDay == today) {
        print('✅ Notificaciones ya completadas hoy');
        return true;
      }
    }

    print('🔔 Ejecutando notificaciones desde WorkManager...');
    final favoritesProvider = FavoritesProvider();
    await favoritesProvider.scheduleNotificationsForToday();

    await _saveSuccessfulNotificationTimestamp();
    print('✅ WorkManager notificaciones exitosas');
    return true;

  } catch (e) {
    print('❌ Error en WorkManager notificaciones: $e');
    return false;
  }
}

/// Gestor central de tareas diarias con WorkManager
class DailyTaskManager {
  static final DailyTaskManager _instance = DailyTaskManager._internal();
  factory DailyTaskManager() => _instance;
  DailyTaskManager._internal();

  // ========== CORE STATE ==========
  bool _isInitialized = false;
  bool _isFirstInstallation = false;

  // ========== CONSTANTS ==========
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  static const String _lastNotifTimestampKey = 'last_notification_timestamp';

  /// Inicializar sistema de tareas diarias con WorkManager
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🚀 Inicializando DailyTaskManager con WorkManager...');

    try {
      // 1. Inicializar WorkManager
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

      // 2. Verificar si es primera instalación
      _isFirstInstallation = await _checkFirstInstallation();

      if (_isFirstInstallation) {
        print('🆕 Primera instalación detectada - ejecutando sync inmediato');
        await _executeFirstInstallSync();
      }

      // 3. Programar tareas diarias con WorkManager
      await _scheduleWorkManagerTasks();

      _isInitialized = true;
      print('✅ DailyTaskManager inicializado correctamente');

    } catch (e) {
      print('❌ Error inicializando DailyTaskManager: $e');
    }
  }

  /// Programar tareas diarias con WorkManager
  Future<void> _scheduleWorkManagerTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString('workmanager_daily_check');
      final today = _getTodayString();

      if (lastCheck == today) {
        print('✅ WorkManager check ya hecho hoy - skip');
        return; // ← SALIR RÁPIDO
      }

      print('🔄 Daily WorkManager check...');

      // Cancelar tareas existentes
      await Workmanager().cancelAll();

      // DEBUG: Calcular delays y mostrar info
      // DEBUG: Calcular delays y mostrar info
      final syncHour = prefs.getInt('wm_sync_hour') ?? 1;
      final syncMin = prefs.getInt('wm_sync_min') ?? 0;
      final delaySync = _calculateDelayTo(syncHour, syncMin);
      final delayNotif = _calculateDelayTo(11, 0);
      print('🕐 Delay sync: ${delaySync.inMinutes} minutos');
      print('🕐 Delay notif: ${delayNotif.inMinutes} minutos');
      print('🕐 Hora actual: ${DateTime.now()}');

      // Programar sync diario a la 1:00 AM
      await Workmanager().registerPeriodicTask(
        'daily-sync',
        'daily-sync',
        frequency: const Duration(hours: 24),
        initialDelay: delaySync,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      // Programar notificaciones diarias a las 11:00 AM
      await Workmanager().registerPeriodicTask(
        'daily-notifications',
        'daily-notifications',
        frequency: const Duration(hours: 24),
        initialDelay: delayNotif,
      );

      // Marcar como verificado hoy
      await prefs.setString('workmanager_daily_check', today);
      print('✅ WorkManager reprogramado para hoy');

    } catch (e) {
      print('❌ Error programando WorkManager: $e');
    }
  }

  /// Calcular delay hasta hora específica
  Duration _calculateDelayTo(int hour, int minute) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, hour, minute);

    // Si ya pasó la hora hoy, programar para mañana
    final targetTime = target.isBefore(now)
        ? target.add(const Duration(days: 1))
        : target;

    return targetTime.difference(now);
  }

  /// Verificar tareas al abrir app (fallback + recovery)
  Future<void> checkOnAppOpen() async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    print('📱 App abierta a las ${now.hour}:${now.minute.toString().padLeft(2, '0')}');

    try {
      // ========== RECOVERY FALLBACK ==========

      // Solo intentar recovery si es después de las 6:00 AM
      if (now.hour >= 1) {

        // ========== DEBUGGING LOGS ==========
        print('🧪 === DEBUGGING RECOVERY ===');
        print('🧪 _isInitialized: $_isInitialized');
        print('🧪 Hora actual: ${now.hour}:${now.minute}');
        print('🧪 Es después de las 6? ${now.hour >= 6}');
        print('🧪 needsSyncToday: ${await _needsSyncToday()}');
        print('🧪 needsNotificationsToday: ${await _needsNotificationsToday()}');

        final lastSync = await _getLastSyncTimestamp();
        print('🧪 lastSync: $lastSync');
        print('🧪 today: ${_getTodayString()}');

        if (lastSync != null) {
          final lastSyncDate = DateTime.parse(lastSync);
          print('🧪 lastSyncDay: ${_getTodayString(lastSyncDate)}');
        }
        // ========== FIN DEBUGGING ==========
        // Verificar si falta sync hoy
        if (await _needsSyncToday()) {
          print('🔄 Recovery: Sync pendiente detectado');
          await _executeRecoverySync();
        }

        // Verificar si faltan notificaciones hoy
        if (await _needsNotificationsToday()) {
          print('🔔 Recovery: Notificaciones pendientes detectadas');
          await _executeRecoveryNotifications();
        }
      }

    } catch (e) {
      print('❌ Error en checkOnAppOpen: $e');
    }
  }

  /// Verificar si necesita sync hoy
  Future<bool> _needsSyncToday() async {
    final today = _getTodayString();
    final lastSync = await _getLastSyncTimestamp();

    if (lastSync == null) return true; // Primera vez

    final lastSyncDate = DateTime.parse(lastSync);
    final lastSyncDay = _getTodayString(lastSyncDate);

    return lastSyncDay != today; // No hay sync hoy
  }

  /// Verificar si necesita notificaciones hoy, respetando el horario programado
  Future<bool> _needsNotificationsToday() async {
    final now = DateTime.now();

    // Solo ejecutar notificaciones después de las 11 AM
    if (now.hour < 11) {
      print('⏰ Notificaciones programadas para las 11 AM - esperando');
      return false; // Todavía no es hora
    }

    final today = _getTodayString();
    final lastNotif = await _getLastNotificationTimestamp();

    if (lastNotif == null) return true; // Primera vez

    final lastNotifDate = DateTime.parse(lastNotif);
    final lastNotifDay = _getTodayString(lastNotifDate);

    return lastNotifDay != today; // No hay notificaciones hoy
  }

  /// Ejecutar sync de recovery
  Future<void> _executeRecoverySync() async {
    try {
      print('🔄 Ejecutando recovery sync...');
      final syncResult = await SyncService().performAutoSync();

      if (syncResult.success) {
        await _saveSuccessfulSyncTimestamp();
        print('✅ Recovery sync exitoso');
      } else {
        print('❌ Recovery sync falló: ${syncResult.error}');
      }

    } catch (e) {
      print('❌ Error en recovery sync: $e');
    }
  }

  /// Ejecutar notificaciones de recovery
  /// Ejecutar notificaciones de recovery
  Future<void> _executeRecoveryNotifications() async {
    try {
      print('🔔 Ejecutando recovery notificaciones...');
      // ✅ CAMBIAR: Usar singleton pattern o injection
      final favoritesProvider = FavoritesProvider();
      await favoritesProvider.init(); // ← AGREGAR: Asegurar inicialización
      await favoritesProvider.scheduleNotificationsForToday();

      await _saveSuccessfulNotificationTimestamp();
      print('✅ Recovery notificaciones exitosas');
    } catch (e) {
      print('❌ Error en recovery notificaciones: $e');
    }
  }

  /// Ejecutar sync de primera instalación (inmediato)
  Future<void> _executeFirstInstallSync() async {
    try {
      print('🚀 Ejecutando firstInstallSync...');
      final syncResult = await SyncService().firstInstallSync();

      if (syncResult.success) {
        _isFirstInstallation = false;
        await _saveSuccessfulSyncTimestamp();

        // Marcar app como inicializada
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('app_initialized', true);

        print('✅ Primera instalación completada exitosamente');
      } else {
        print('⚠️ Primera instalación falló: ${syncResult.error}');
      }

    } catch (e) {
      print('❌ Error en primera instalación: $e');
    }
  }

  // ========== TIMESTAMP MANAGEMENT ==========

  /// Obtener timestamp de último sync
  Future<String?> _getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncTimestampKey);
  }

  /// Obtener timestamp de última notificación
  Future<String?> _getLastNotificationTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastNotifTimestampKey);
  }

  /// Guardar timestamp de sync exitoso
  Future<void> _saveSuccessfulSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncTimestampKey, DateTime.now().toIso8601String());
  }

  /// Guardar timestamp de notificación exitosa
  Future<void> _saveSuccessfulNotificationTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNotifTimestampKey, DateTime.now().toIso8601String());
  }

  // ========== STATE MANAGEMENT ==========

  /// Verificar si es primera instalación
  Future<bool> _checkFirstInstallation() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('app_initialized') ?? false);
  }

  /// Obtener string de fecha (YYYY-MM-DD)
  String _getTodayString([DateTime? date]) {
    final target = date ?? DateTime.now();
    return '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
  }

  // ========== DEBUG & TESTING ==========

  /// Obtener estado actual para debugging
  Map<String, dynamic> getDebugState() {
    return {
      'initialized': _isInitialized,
      'is_first_installation': _isFirstInstallation,
      'workmanager_active': true,
      'current_time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'today': _getTodayString(),
    };
  }

  /// Método para testing - forzar ejecución de recovery
  Future<void> testExecuteRecovery() async {
    print('🧪 TEST: Ejecutando recovery manualmente...');
    await checkOnAppOpen();
  }

  /// Método para testing - reprogramar WorkManager
  Future<void> testRescheduleWorkManager() async {
    print('🧪 TEST: Reprogramando WorkManager...');
    await _scheduleWorkManagerTasks();
  }

  /// Cleanup al cerrar app
  void dispose() {
    print('🧹 DailyTaskManager disposed');
  }
}

// ========== HELPER FUNCTIONS ==========

/// Obtener timestamp de último sync (función helper)
Future<String?> _getLastSyncTimestamp() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('last_sync_timestamp');
}

/// Obtener timestamp de última notificación (función helper)
Future<String?> _getLastNotificationTimestamp() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('last_notification_timestamp');
}

/// Guardar timestamp de sync exitoso (función helper)
Future<void> _saveSuccessfulSyncTimestamp() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_sync_timestamp', DateTime.now().toIso8601String());
}

/// Guardar timestamp de notificación exitosa (función helper)
Future<void> _saveSuccessfulNotificationTimestamp() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_notification_timestamp', DateTime.now().toIso8601String());
}

/// Obtener string de fecha (función helper)
String _getTodayString([DateTime? date]) {
  final target = date ?? DateTime.now();
  return '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
}