// lib/src/services/daily_task_manager.dart

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../sync/sync_service.dart';
import '../providers/favorites_provider.dart';

// ========== TASK TYPES ENUM ==========
enum TaskType {
  sync('daily-sync', 'last_sync_timestamp', 1, 0, 6),           // 1:00 AM, recovery después 6:00 AM
  notifications('daily-notifications', 'last_notification_timestamp', 11, 0, 11); // 11:00 AM, recovery después 11:00 AM

  const TaskType(this.workManagerId, this.timestampKey, this.scheduleHour, this.scheduleMinute, this.recoveryMinHour);

  final String workManagerId;
  final String timestampKey;
  final int scheduleHour;
  final int scheduleMinute;
  final int recoveryMinHour;
}

/// 🚀 Callback dispatcher para WorkManager - LIMPIO
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 WorkManager ejecutando task: $task');

    // Mapear task string a TaskType
    final taskType = TaskType.values.firstWhere(
          (t) => t.workManagerId == task,
      orElse: () => throw Exception('Task desconocido: $task'),
    );

    return await _executeWorkManagerTask(taskType);
  });
}

/// 🎯 Ejecutar task genérico desde WorkManager
Future<bool> _executeWorkManagerTask(TaskType taskType) async {
  try {
    // Verificar si ya se ejecutó hoy
    if (await _wasExecutedTodayGlobal(taskType)) {
      print('✅ ${taskType.workManagerId} ya completado hoy');
      return true;
    }

    print('🔄 Ejecutando ${taskType.workManagerId} desde WorkManager...');

    // Ejecutar task específico
    final success = await _performTask(taskType);

    if (success) {
      await _saveSuccessfulExecutionGlobal(taskType);
      print('✅ WorkManager ${taskType.workManagerId} exitoso');
    } else {
      print('❌ WorkManager ${taskType.workManagerId} falló');
    }

    return success;

  } catch (e) {
    print('❌ Error en WorkManager ${taskType.workManagerId}: $e');
    return false;
  }
}

/// ⚡ Ejecutar task específico según tipo
Future<bool> _performTask(TaskType taskType) async {
  switch (taskType) {
    case TaskType.sync:
      final syncResult = await SyncService().performAutoSync();
      return syncResult.success;

    case TaskType.notifications:
      final favoritesProvider = FavoritesProvider();
      await favoritesProvider.scheduleNotificationsForToday();
      return true;
  }
}

/// 🧠 GESTOR CENTRAL DE TAREAS DIARIAS - ARQUITECTURA LIMPIA
class DailyTaskManager {
  static final DailyTaskManager _instance = DailyTaskManager._internal();
  factory DailyTaskManager() => _instance;
  DailyTaskManager._internal();

  // ========== CORE STATE ==========
  bool _isInitialized = false;
  static const String _workManagerCheckKey = 'workmanager_daily_check';

  /// 🚀 Inicializar sistema de tareas diarias
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🚀 Inicializando DailyTaskManager con WorkManager...');

    try {
      // Inicializar WorkManager
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
      await Future.delayed(Duration(milliseconds: 500));

      // Programar tareas
      await _scheduleAllTasks();

      _isInitialized = true;
      print('✅ DailyTaskManager inicializado correctamente');

    } catch (e) {
      print('❌ Error inicializando DailyTaskManager: $e');
    }
  }

  /// ⏰ Programar todas las tareas con WorkManager
  Future<void> _scheduleAllTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_workManagerCheckKey);
      final today = _getTodayString();

      if (lastCheck == today) {
        print('✅ WorkManager check ya hecho hoy - skip');
        return;
      }

      print('🔄 Daily WorkManager check...');

      // Cancelar tareas existentes
      await Workmanager().cancelAll();

      // Programar cada tipo de task
      for (final taskType in TaskType.values) {
        await _scheduleTask(taskType, prefs);
      }

      // Marcar como verificado hoy
      await prefs.setString(_workManagerCheckKey, today);
      print('✅ WorkManager reprogramado para hoy');

    } catch (e) {
      print('❌ Error programando WorkManager: $e');
    }
  }

  /// 📅 Programar task específico
  Future<void> _scheduleTask(TaskType taskType, SharedPreferences prefs) async {
    // Obtener hora configurada (sync puede ser personalizada)
    final hour = taskType == TaskType.sync
        ? prefs.getInt('wm_sync_hour') ?? taskType.scheduleHour
        : taskType.scheduleHour;
    final minute = taskType == TaskType.sync
        ? prefs.getInt('wm_sync_min') ?? taskType.scheduleMinute
        : taskType.scheduleMinute;

    final delay = _calculateDelayTo(hour, minute);

    print('🕐 ${taskType.workManagerId} programado para ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (delay: ${delay.inMinutes}min)');

    await Workmanager().registerPeriodicTask(
      taskType.workManagerId,
      taskType.workManagerId,
      frequency: const Duration(hours: 24),
      initialDelay: delay,
      constraints: taskType == TaskType.sync ? Constraints(
        networkType: NetworkType.connected,
      ) : null,
    );
  }

  /// ⏰ Calcular delay hasta hora específica
  Duration _calculateDelayTo(int hour, int minute) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, hour, minute);

    final targetTime = target.isBefore(now)
        ? target.add(const Duration(days: 1))
        : target;

    return targetTime.difference(now);
  }

  /// 🏥 Verificar tareas al abrir app (recovery + fallback)
  Future<void> checkOnAppOpen() async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    print('📱 App abierta a las ${now.hour}:${now.minute.toString().padLeft(2, '0')}');

    try {
      // Recovery solo después de las 6:00 AM
      if (now.hour >= 6) {
        await _performRecoveryCheck();
      }
    } catch (e) {
      print('❌ Error en checkOnAppOpen: $e');
    }
  }

  /// 🔄 Verificar y ejecutar recovery para todas las tareas
  Future<void> _performRecoveryCheck() async {
    final now = DateTime.now();

    for (final taskType in TaskType.values) {
      // Solo recovery si ya pasó la hora mínima
      if (now.hour >= taskType.recoveryMinHour && await _needsExecutionToday(taskType)) {
        print('🔄 Recovery: ${taskType.workManagerId} pendiente detectado');
        await _executeRecovery(taskType);
      }
    }
  }

  /// 🎯 Ejecutar recovery genérico
  Future<void> _executeRecovery(TaskType taskType) async {
    try {
      print('🔄 Ejecutando recovery ${taskType.workManagerId}...');

      final success = await _performTask(taskType);

      if (success) {
        await _saveSuccessfulExecution(taskType);
        print('✅ Recovery ${taskType.workManagerId} exitoso');
      } else {
        print('❌ Recovery ${taskType.workManagerId} falló');
      }

    } catch (e) {
      print('❌ Error en recovery ${taskType.workManagerId}: $e');
    }
  }

  // ========== TIMESTAMP MANAGEMENT GENÉRICO ==========

  /// ✅ Verificar si task fue ejecutado hoy
  Future<bool> _wasExecutedToday(TaskType taskType) async {
    final today = _getTodayString();
    final lastExecution = await _getLastExecutionTimestamp(taskType);

    if (lastExecution == null) return false;

    final lastExecutionDate = DateTime.parse(lastExecution);
    final lastExecutionDay = _getTodayString(lastExecutionDate);

    return lastExecutionDay == today;
  }

  /// 🔍 Verificar si task necesita ejecución hoy
  Future<bool> _needsExecutionToday(TaskType taskType) async {
    return !(await _wasExecutedToday(taskType));
  }

  /// 📝 Obtener timestamp de última ejecución
  Future<String?> _getLastExecutionTimestamp(TaskType taskType) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(taskType.timestampKey);
  }

  /// 💾 Guardar timestamp de ejecución exitosa
  Future<void> _saveSuccessfulExecution(TaskType taskType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(taskType.timestampKey, DateTime.now().toIso8601String());
  }

  /// 📅 Obtener string de fecha (YYYY-MM-DD)
  String _getTodayString([DateTime? date]) {
    final target = date ?? DateTime.now();
    return '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
  }

  // ========== TESTING & DEBUG METHODS ==========

  /// 🧪 Marcar task como vencida (para testing)
  Future<void> markTaskAsExpired(TaskType taskType) async {
    final prefs = await SharedPreferences.getInstance();
    final expiredTime = DateTime.now().subtract(const Duration(hours: 25));
    await prefs.setString(taskType.timestampKey, expiredTime.toIso8601String());
    print('🧪 ${taskType.workManagerId} marcado como vencido');
  }

  /// 🔄 Forzar reprogramación de WorkManager (para testing)
  Future<void> testRescheduleWorkManager() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workManagerCheckKey);
    await _scheduleAllTasks();
    print('🧪 WorkManager reprogramado forzosamente');
  }

  /// 🏥 Ejecutar recovery manualmente (para testing)
  Future<void> testExecuteRecovery() async {
    print('🧪 TEST: Ejecutando recovery manualmente...');
    await _performRecoveryCheck();
  }

  /// 📊 Obtener estado actual para debugging
  Map<String, dynamic> getDebugState() {
    return {
      'initialized': _isInitialized,
      'workmanager_active': true,
      'current_time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'today': _getTodayString(),
    };
  }

  /// 🧹 Cleanup al cerrar app
  void dispose() {
    print('🧹 DailyTaskManager disposed');
  }
}

// ========== HELPER FUNCTIONS GLOBALES ==========

/// ✅ Verificar si task fue ejecutado hoy (función global)
Future<bool> _wasExecutedTodayGlobal(TaskType taskType) async {
  final today = _getTodayStringGlobal();
  final lastExecution = await _getLastExecutionTimestampGlobal(taskType);

  if (lastExecution == null) return false;

  final lastExecutionDate = DateTime.parse(lastExecution);
  final lastExecutionDay = _getTodayStringGlobal(lastExecutionDate);

  return lastExecutionDay == today;
}

/// 📝 Obtener timestamp de última ejecución (función global)
Future<String?> _getLastExecutionTimestampGlobal(TaskType taskType) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(taskType.timestampKey);
}

/// 💾 Guardar timestamp de ejecución exitosa (función global)
Future<void> _saveSuccessfulExecutionGlobal(TaskType taskType) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(taskType.timestampKey, DateTime.now().toIso8601String());
}

/// 📅 Obtener string de fecha (función global)
String _getTodayStringGlobal([DateTime? date]) {
  final target = date ?? DateTime.now();
  return '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
}
//
// 🚀 HOOKS PREPARADOS PARA FUTURAS EXTENSIONES:
//
// Future<void> testNotificationsWorkManager() async {
//   await Workmanager().registerOneOffTask(
//     'test-notifications-wm',
//     TaskType.notifications.workManagerId,
//     initialDelay: const Duration(minutes: 2),
//   );
// }
//
// Future<void> markNotificationsAsExpired() async {
//   await markTaskAsExpired(TaskType.notifications);
// }
//
// Future<void> forceNotificationsExecution() async {
//   await _executeRecovery(TaskType.notifications);
// }