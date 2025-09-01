import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import '../sync/sync_service.dart';
import 'dart:async';
import '../providers/favorites_provider.dart';
import '../models/user_preferences.dart';

enum TaskType {
  sync('daily-sync', 'last_sync_timestamp', 1, 0, 2),
  notifications('daily-notifications', 'last_notification_timestamp', 11, 0, 6);

  const TaskType(this.workManagerId, this.timestampKey, this.scheduleHour, this.scheduleMinute, this.recoveryMinHour);

  final String workManagerId;
  final String timestampKey;
  final int scheduleHour;
  final int scheduleMinute;
  final int recoveryMinHour;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final taskType = TaskType.values.firstWhere(
          (t) => t.workManagerId == task,
      orElse: () => throw Exception('Task desconocido: $task'),
    );

    return await _executeWorkManagerTask(taskType);
  });
}

Future<bool> _executeWorkManagerTask(TaskType taskType) async {
  try {
    if (await _wasExecutedTodayGlobal(taskType)) {
      return true;
    }

    final success = await _performTask(taskType);

    if (success) {
      await _saveSuccessfulExecutionGlobal(taskType);
    }

    return success;

  } catch (e) {
    return false;
  }
}

Future<bool> _performTask(TaskType taskType) async {
  switch (taskType) {
    case TaskType.sync:
      final syncResult = await SyncService().performAutoSync();
      return syncResult.success;

    case TaskType.notifications:
      final ready = await UserPreferences.getNotificationsReady();
      if (!ready) {
        return true;
      }

      // Esperar a que NotificationService termine de inicializarse
      await NotificationService.waitForInitialization();

      final now = DateTime.now();
      final favoritesProvider = FavoritesProvider();

      if (now.hour >= 11) {
        await favoritesProvider.sendImmediateNotificationForToday();
      } else {
        await favoritesProvider.scheduleNotificationsForToday();
      }
      return true;
  }
}

class DailyTaskManager {
  static final DailyTaskManager _instance = DailyTaskManager._internal();
  factory DailyTaskManager() => _instance;
  DailyTaskManager._internal();

  bool _isInitialized = false;
  static const String _workManagerCheckKey = 'workmanager_daily_check';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Skip WorkManager en simulador/debug para evitar crashes
    if (kDebugMode) {
      _isInitialized = true;
      return;
    }

    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
      await _scheduleAllTasks();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true; // Marcar como inicializado aunque falle
    }
  }

  Future<void> _scheduleAllTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_workManagerCheckKey);
      final today = _getTodayStringGlobal();

      if (lastCheck == today) {
        return;
      }
      await Workmanager().cancelAll();

      for (final taskType in TaskType.values) {
        await _scheduleTask(taskType, prefs);
      }

      await prefs.setString(_workManagerCheckKey, today);
    } catch (e) {}
  }

  Future<void> _scheduleTask(TaskType taskType, SharedPreferences prefs) async {
    final hour = taskType == TaskType.sync
        ? prefs.getInt('wm_sync_hour') ?? taskType.scheduleHour
        : taskType.scheduleHour;
    final minute = taskType == TaskType.sync
        ? prefs.getInt('wm_sync_min') ?? taskType.scheduleMinute
        : taskType.scheduleMinute;

    final delay = _calculateDelayTo(hour, minute);

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

  Duration _calculateDelayTo(int hour, int minute) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, hour, minute);

    final targetTime = target.isBefore(now)
        ? target.add(const Duration(days: 1))
        : target;

    return targetTime.difference(now);
  }

  Future<void> checkOnAppOpen() async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();

    try {
      if (now.hour >= 6) {
        await _performRecoveryCheck();
      }
    } catch (e) {}
  }

  Future<void> _performRecoveryCheck() async {
    final now = DateTime.now();

    for (final taskType in TaskType.values) {
      if (now.hour >= taskType.recoveryMinHour && await _needsExecutionToday(taskType)) {
        await _executeRecovery(taskType);
      }
    }
  }
  Future<void> _executeRecovery(TaskType taskType) async {
    try {
      final success = await _performTask(taskType);

      if (success) {
        await _saveSuccessfulExecutionGlobal(taskType);
      }
    } catch (e) {}
  }


  Future<bool> _needsExecutionToday(TaskType taskType) async {
    return !(await _wasExecutedTodayGlobal(taskType));
  }

  Future<void> markTaskAsExpired(TaskType taskType) async {
    final prefs = await SharedPreferences.getInstance();
    final expiredTime = DateTime.now().subtract(const Duration(hours: 25));
    await prefs.setString(taskType.timestampKey, expiredTime.toIso8601String());
  }

  Future<void> testRescheduleWorkManager() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workManagerCheckKey);
    await _scheduleAllTasks();
  }

  Future<void> testExecuteRecovery() async {
    await _performRecoveryCheck();
  }

  Map<String, dynamic> getDebugState() {
    return {
      'initialized': _isInitialized,
      'workmanager_active': true,
      'current_time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'today': _getTodayStringGlobal(),
    };
  }

  void dispose() {}
}

Future<bool> _wasExecutedTodayGlobal(TaskType taskType) async {
  final today = _getTodayStringGlobal();
  final lastExecution = await _getLastExecutionTimestampGlobal(taskType);

  if (lastExecution == null) return false;

  final lastExecutionDate = DateTime.parse(lastExecution);
  final lastExecutionDay = _getTodayStringGlobal(lastExecutionDate);

  return lastExecutionDay == today;
}

Future<String?> _getLastExecutionTimestampGlobal(TaskType taskType) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(taskType.timestampKey);
}

Future<void> _saveSuccessfulExecutionGlobal(TaskType taskType) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(taskType.timestampKey, DateTime.now().toIso8601String());
}

String _getTodayStringGlobal([DateTime? date]) {
  final target = date ?? DateTime.now();
  return '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
}