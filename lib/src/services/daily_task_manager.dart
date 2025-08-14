// lib/src/services/daily_task_manager.dart

import 'dart:async';
import 'package:cron/cron.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sync/sync_service.dart';
import '../providers/favorites_provider.dart';

/// Gestor central de tareas diarias automáticas
/// Maneja sync nocturno y scheduling de notificaciones mediante cron + fallback
class DailyTaskManager {
  static final DailyTaskManager _instance = DailyTaskManager._internal();
  factory DailyTaskManager() => _instance;
  DailyTaskManager._internal();

  // ========== CORE STATE ==========
  Timer? _dailyTimer;
  bool _isInitialized = false;
  final Cron _cron = Cron();

  // ========== TASK STATES ==========
  bool _syncCompleted = false;
  int _syncRetries = 0;
  bool _isFirstInstallation = false;
  bool _notificationsCompleted = false;

  // ========== CONSTANTS ==========
  static const String _taskDateKey = 'daily_tasks_date';
  static const String _syncCompletedKey = 'sync_completed';
  static const int _maxSyncRetries = 6; // 1 hora de reintentos (6 × 10min)
  static const String _notifCompletedKey = 'notifications_completed';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  static const String _lastNotifTimestampKey = 'last_notification_timestamp';

  /// Inicializar sistema de tareas diarias
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🚀 Inicializando DailyTaskManager con Cron...');

    try {
      // 1. Verificar si es primera instalación
      _isFirstInstallation = await _checkFirstInstallation();

      if (_isFirstInstallation) {
        print('🆕 Primera instalación detectada - ejecutando sync inmediato');
        await _executeFirstInstallSync();
        // No necesita timer para primera instalación
      } else {
        // 2. Cargar estado persistente para syncs diarios
        await _loadDailyState();

        // 3. Verificar si hay tareas pendientes
        if (_hasPendingTasks()) {
          print('📋 Hay tareas pendientes, activando timer...');
          _startDailyTimer();
        } else {
          print('✅ Todas las tareas completadas para hoy');
        }
      }

      // 4. Setup cron para timing exacto
      _setupCronSchedules();

      _isInitialized = true;
      print('✅ DailyTaskManager inicializado correctamente');

    } catch (e) {
      print('❌ Error inicializando DailyTaskManager: $e');
    }
  }

  /// Verificar tareas al abrir app (fallback robusto)
  Future<void> checkOnAppOpen() async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    print('📱 App abierta a las ${now.hour}:${now.minute.toString().padLeft(2, '0')}');

    // Verificación inteligente sin condiciones restrictivas
    bool shouldExecuteAnyTask = false;

    // Verificar sync
    if (await _shouldSyncNow()) {
      print('🔄 Sync pendiente detectado');
      await _executeSync();
      shouldExecuteAnyTask = true;
    }

    // Verificar notificaciones
    if (await _shouldScheduleNotificationsNow()) {
      print('🔔 Notificaciones pendientes detectadas');
      await _executeNotifications();
      shouldExecuteAnyTask = true;
    }

    // Si ejecutamos algo, verificar si necesitamos timer
    if (shouldExecuteAnyTask && _hasPendingTasks()) {
      _startDailyTimer();
    }
  }

  // ========== CRON SETUP ==========

  /// Configurar schedules de cron para timing exacto
  void _setupCronSchedules() {
    // Sync a las 1:00 AM exacto
    _cron.schedule(Schedule.parse('0 1 * * *'), () async {
      print('⏰ Cron ejecutando sync a la 1:00 AM');
      if (await _shouldSyncNow()) {
        await _executeSync();
      }
    });

    // Notificaciones a las 11:00 AM exacto
    _cron.schedule(Schedule.parse('0 11 * * *'), () async {
      print('⏰ Cron ejecutando notificaciones a las 11:00 AM');
      if (await _shouldScheduleNotificationsNow()) {
        await _executeNotifications();
      }
    });

    print('⏰ Cron schedules configurados (1:00 AM sync, 11:00 AM notificaciones)');
  }

  // ========== SMART CHECKS ==========

  /// Verificar si debería sincronizar ahora (lógica flexible)
  Future<bool> _shouldSyncNow() async {
    final now = DateTime.now();

    // Si es antes de la 1:00 AM, no sync
    if (now.hour < 1) return false;

    // Verificar si ya hay sync hoy usando timestamp real
    final lastSyncStr = await _getLastSyncTimestamp();
    if (lastSyncStr == null) return true; // Primera vez

    final lastSync = DateTime.parse(lastSyncStr);
    final today = DateTime(now.year, now.month, now.day);
    final lastSyncDay = DateTime(lastSync.year, lastSync.month, lastSync.day);

    // Solo sync si no hay sync hoy
    return !_isSameDay(today, lastSyncDay);
  }

  /// Verificar si debería programar notificaciones ahora
  Future<bool> _shouldScheduleNotificationsNow() async {
    final now = DateTime.now();

    // Si es antes de las 11:00 AM, no notificaciones
    if (now.hour < 11) return false;

    // Verificar si ya hay notificaciones hoy usando timestamp real
    final lastNotifStr = await _getLastNotificationTimestamp();
    if (lastNotifStr == null) return true; // Primera vez

    final lastNotif = DateTime.parse(lastNotifStr);
    final today = DateTime(now.year, now.month, now.day);
    final lastNotifDay = DateTime(lastNotif.year, lastNotif.month, lastNotif.day);

    // Solo notificaciones si no hay notificaciones hoy
    return !_isSameDay(today, lastNotifDay);
  }

  /// Verificar si dos fechas son el mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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

  // ========== TIMER MANAGEMENT ==========

  /// Iniciar timer de tareas diarias
  void _startDailyTimer() {
    if (_dailyTimer?.isActive == true) {
      print('⏰ Timer ya está activo');
      return;
    }

    _dailyTimer?.cancel();
    _dailyTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      await _processTasks();
    });

    print('⏰ Timer diario activado (cada 10 minutos)');

    // Ejecutar verificación inmediata
    _processTasks();
  }

  /// Detener timer de tareas diarias
  void _stopDailyTimer() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
    print('⏹️ Timer diario detenido');
  }

  /// Procesar tareas según horario y estado
  Future<void> _processTasks() async {
    final now = DateTime.now();

    print('🔄 Procesando tareas - ${now.hour}:${now.minute.toString().padLeft(2, '0')}');

    try {
      bool tasksExecuted = false;

      // ========== SYNC TASK ==========
      if (!_syncCompleted && _isAfterTime(1, 0)) {
        if (_syncRetries < _maxSyncRetries) {
          print('🔄 Ejecutando sync nocturno (intento ${_syncRetries + 1}/$_maxSyncRetries)...');
          await _executeSync();
          tasksExecuted = true;
        } else {
          print('❌ Sync agotó reintentos ($_maxSyncRetries), esperando mañana');
        }
      }

      // ========== NOTIFICATIONS TASK ==========
      if (!_notificationsCompleted && _isAfterTime(11, 0)) {
        print('🔔 Ejecutando scheduling de notificaciones...');
        await _executeNotifications();
        tasksExecuted = true;
      }

      // ========== AUTO-SHUTDOWN ==========
      if (_allTasksCompleted()) {
        print('✅ Todas las tareas diarias completadas');
        _stopDailyTimer();
        return;
      }

      // ========== STATUS LOG ==========
      if (!tasksExecuted) {
        final syncStatus = _syncCompleted ? "✅" :
        _syncRetries >= _maxSyncRetries ? "❌" : "⏰";
        final notifStatus = _notificationsCompleted ? "✅" : "⏰";
        print('⏳ Esperando horario - Sync: $syncStatus, Notif: $notifStatus | Timer activo');
      }

    } catch (e) {
      print('❌ Error procesando tareas: $e');
    }
  }

  // ========== TASK EXECUTION ==========

  /// Ejecutar sync de primera instalación (inmediato)
  Future<void> _executeFirstInstallSync() async {
    try {
      print('🚀 Ejecutando firstInstallSync...');
      final syncResult = await SyncService().firstInstallSync();

      if (syncResult.success) {
        _syncCompleted = true;
        _isFirstInstallation = false; // Ya no es primera instalación
        await _saveSuccessfulSyncTimestamp(); // Guardar timestamp real
        print('✅ Primera instalación completada exitosamente');
      } else {
        print('⚠️ Primera instalación falló: ${syncResult.error}');
      }

    } catch (e) {
      print('❌ Error en primera instalación: $e');
    }
  }

  /// Ejecutar sincronización nocturna (diaria)
  Future<void> _executeSync() async {
    try {
      final syncResult = await SyncService().performAutoSync();

      if (syncResult.success) {
        _syncCompleted = true;
        _syncRetries = 0; // Reset contador al éxito
        await _saveSyncState();
        await _saveSuccessfulSyncTimestamp(); // Solo guardar si exitoso
        print('✅ Sync nocturno completado exitosamente');
      } else {
        _syncRetries++;
        print('⚠️ Sync falló (intento $_syncRetries/$_maxSyncRetries): ${syncResult.error}');

        if (_syncRetries >= _maxSyncRetries) {
          print('❌ Sync agotó todos los reintentos, esperando hasta mañana');
        } else {
          print('🔄 Reintentará en 10 minutos...');
        }
      }

    } catch (e) {
      _syncRetries++;
      print('❌ Error ejecutando sync (intento $_syncRetries/$_maxSyncRetries): $e');
    }
  }

  /// Ejecutar scheduling de notificaciones de favoritos
  Future<void> _executeNotifications() async {
    try {
      final favoritesProvider = FavoritesProvider();
      await favoritesProvider.scheduleNotificationsForToday();

      _notificationsCompleted = true;
      await _saveNotificationState();
      await _saveSuccessfulNotificationTimestamp(); // Solo guardar si exitoso
      print('✅ Notificaciones programadas exitosamente');

    } catch (e) {
      print('❌ Error ejecutando notificaciones: $e');
    }
  }

  // ========== STATE MANAGEMENT ==========

  /// Verificar si es primera instalación
  Future<bool> _checkFirstInstallation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('app_initialized') ?? true;
  }

  /// Verificar si hay tareas pendientes
  bool _hasPendingTasks() {
    return !_syncCompleted || !_notificationsCompleted;
  }

  /// Verificar si todas las tareas están completadas
  bool _allTasksCompleted() {
    return _syncCompleted && _notificationsCompleted;
  }

  /// Cargar estado diario desde SharedPreferences
  Future<void> _loadDailyState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_taskDateKey);

    if (savedDate == today) {
      // Mismo día - cargar estados guardados
      _syncCompleted = prefs.getBool(_syncCompletedKey) ?? false;
      _notificationsCompleted = prefs.getBool(_notifCompletedKey) ?? false;

      print('📅 Estado cargado para hoy: Sync=${_syncCompleted ? "✅" : "❌"}, Notif=${_notificationsCompleted ? "✅" : "❌"}');
    } else {
      // Nuevo día - reset estado
      await _resetDailyState();
    }
  }

  /// Reset estado para nuevo día
  Future<void> _resetDailyState() async {
    _syncCompleted = false;
    _syncRetries = 0; // Reset contador de reintentos
    _notificationsCompleted = false;

    await _saveDailyState();
    print('🔄 Estado diario reseteado para nuevo día');
  }

  /// Guardar estado completo
  Future<void> _saveDailyState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_taskDateKey, _getTodayString());
    await prefs.setBool(_syncCompletedKey, _syncCompleted);
    await prefs.setBool(_notifCompletedKey, _notificationsCompleted);
  }

  /// Guardar solo estado de sync
  Future<void> _saveSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncCompletedKey, _syncCompleted);
  }

  /// Guardar solo estado de notificaciones
  Future<void> _saveNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifCompletedKey, _notificationsCompleted);
  }

  /// Verificar si es un nuevo día
  Future<bool> _isNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_taskDateKey);
    final today = _getTodayString();
    return savedDate != today;
  }

  /// Obtener string de fecha actual (YYYY-MM-DD)
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ========== TIME DETECTION ==========

  /// Verificar si hora actual es después del tiempo especificado
  bool _isAfterTime(int hour, int minute) {
    final now = DateTime.now();
    return now.hour > hour || (now.hour == hour && now.minute >= minute);
  }

  // ========== DEBUG & TESTING ==========

  /// Método para testing - simular cambio de día
  Future<void> testDayChange() async {
    print('🧪 TEST: Simulando cambio de día...');
    await _resetDailyState();
    _startDailyTimer();
  }

  /// Método para testing - forzar ejecución inmediata
  Future<void> testExecuteTasks() async {
    print('🧪 TEST: Ejecutando tareas inmediatamente...');
    await _processTasks();
  }

  /// Obtener estado actual para debugging
  Map<String, dynamic> getDebugState() {
    return {
      'initialized': _isInitialized,
      'is_first_installation': _isFirstInstallation,
      'timer_active': _dailyTimer?.isActive ?? false,
      'cron_active': _cron.toString().isNotEmpty,
      'sync_completed': _syncCompleted,
      'sync_retries': _syncRetries,
      'max_sync_retries': _maxSyncRetries,
      'notifications_completed': _notificationsCompleted,
      'current_time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'today': _getTodayString(),
    };
  }

  /// Cleanup al cerrar app
  void dispose() {
    _stopDailyTimer();
    _cron.close(); // Cleanup cron
    print('🧹 DailyTaskManager disposed');
  }
}