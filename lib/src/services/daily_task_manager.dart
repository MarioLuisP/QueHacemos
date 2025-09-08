import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../sync/sync_service.dart';

enum TaskType {
  sync('daily-sync', 'last_sync_timestamp', 1, 0, 2);

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
  }
}

class DailyTaskManager {
  static final DailyTaskManager _instance = DailyTaskManager._internal();
  factory DailyTaskManager() => _instance;
  DailyTaskManager._internal();

  bool _isInitialized = false;
  static const String _workManagerCheckKey = 'workmanager_daily_check';
  Timer? _retryTimer;
  StreamSubscription<SyncResult>? _syncSubscription;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Suscribirse al stream de sync para cancelar timer en caso de éxito
    _syncSubscription ??= SyncService.onSyncComplete.listen((result) {
      if (result.success) {
        _cancelRetryTimer();
      }
    });

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

      // Solo programar sync
      await _scheduleTask(TaskType.sync, prefs);

      await prefs.setString(_workManagerCheckKey, today);
    } catch (e) {}
  }

  Future<void> _scheduleTask(TaskType taskType, SharedPreferences prefs) async {
    final hour = prefs.getInt('wm_sync_hour') ?? taskType.scheduleHour;
    final minute = prefs.getInt('wm_sync_min') ?? taskType.scheduleMinute;

    final delay = _calculateDelayTo(hour, minute);

    await Workmanager().registerPeriodicTask(
      taskType.workManagerId,
      taskType.workManagerId,
      frequency: const Duration(hours: 24),
      initialDelay: delay,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiresCharging: false,
      ),
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
      if (now.hour >= 2) {
        await _performRecoveryCheck();
      }
    } catch (e) {}
  }

  Future<void> _performRecoveryCheck() async {
    final now = DateTime.now();

    // Solo verificar sync (TaskType.sync)
    if (now.hour >= TaskType.sync.recoveryMinHour && await _needsExecutionToday(TaskType.sync)) {
      await _executeRecovery(TaskType.sync);
    }
  }

  Future<void> _executeRecovery(TaskType taskType) async {
    try {
      final success = await _performTask(taskType);

      if (success) {
        await _saveSuccessfulExecutionGlobal(taskType);
        _cancelRetryTimer();
      } else {
        _startRetryTimer();
      }
    } catch (e) {
      _startRetryTimer();
    }
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
      'task_type': 'sync_only',
    };
  }

  void _startRetryTimer() {
    _cancelRetryTimer(); // Cancelar timer existente si hay uno

    _retryTimer = Timer.periodic(const Duration(minutes: 30), (timer) async {
      await _performRecoveryCheck();
    });
  }

  void _cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void dispose() {
    _cancelRetryTimer();
    _syncSubscription?.cancel();
    _syncSubscription = null;
  }
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