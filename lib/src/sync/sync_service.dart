//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../data/repositories/event_repository.dart';
import '../data/database/database_helper.dart';
import '../mock/mock_events.dart';
import '../providers/notifications_provider.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // NUEVO: StreamController para notificar cuando termina sync
  static final StreamController<SyncResult> _syncCompleteController =
  StreamController<SyncResult>.broadcast();

  // NUEVO: Stream público para escuchar completions de sync
  static Stream<SyncResult> get onSyncComplete => _syncCompleteController.stream;
  final EventRepository _eventRepository = EventRepository();
  NotificationsProvider get _notificationsProvider => NotificationsProvider.instance;
  static const Duration _syncInterval = Duration(hours: 24);
  static const String _lastSyncKey = 'last_sync_timestamp';

  // NUEVO: Flag para evitar múltiples sincronizaciones
  bool _isSyncing = false;
  static bool _globalSyncInProgress = false;

  // ========== SYNC PRINCIPAL ==========

  /// Verificar si necesita sincronización
  Future<bool> shouldSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);

    final now = DateTime.now();

    // Si nunca sincronizó, sincronizar
    if (lastSyncString == null) {
      print('🔄 Primera sincronización');
      return true;
    }

    final lastSync = DateTime.parse(lastSyncString);

    // Verificar si ya sincronizó hoy
    final today = DateTime(now.year, now.month, now.day);
    final lastSyncDay = DateTime(lastSync.year, lastSync.month, lastSync.day);

    if (today.isAfter(lastSyncDay)) {
      // No sincronizó hoy, verificar condiciones
      if (now.hour >= 1) {
        print('🔄 Sincronización por horario (después de 01:00)');
        return true;
      } else {
        print('⏰ Esperando hasta la 1 AM para sincronizar');
        return false;
      }
    }

    // Ya sincronizó hoy
    print('✅ Ya sincronizó hoy, omitiendo');
    return false;
  }

  // ========== NUEVOS MÉTODOS PRINCIPALES ==========

  /// ✅ NUEVO: Primera instalación - Siempre 10 lotes
  Future<SyncResult> firstInstallSync() async {
    if (_isSyncing) {
      print('⏭️ Sincronización ya en progreso, omitiendo...');
      return SyncResult.notNeeded();
    }

    _isSyncing = true;
    _globalSyncInProgress = true;

    try {
      print('🚀 Iniciando primera instalación - 10 lotes...');

      // Descargar 10 lotes (sin verificar shouldSync)
      final events = await _downloadLatestBatch(isMultipleLots: true);

      if (events.isEmpty) {
        print('📭 No hay eventos disponibles para primera instalación');
        return SyncResult.noNewData();
      }

      await _processEvents(events);
      final cleanupResults = await _performCleanup();
      await _updateSyncTimestamp();
      await _maintainNotificationSchedules();

      // Notificar primera instalación completada
      _notificationsProvider.addNotification(
        title: '🎭 ¡App lista para usar!',
        message: 'Se descargaron ${events.length} eventos culturales de Córdoba',
        type: 'first_install_complete',
        icon: '🎉',
      );

      print('✅ Primera instalación completada: ${events.length} eventos');
      final result = SyncResult.success(
        eventsAdded: events.length,
        eventsRemoved: cleanupResults.eventsRemoved,
        favoritesRemoved: cleanupResults.favoritesRemoved,
      );
      _syncCompleteController.add(result);
      return result;

    } catch (e) {
      print('❌ Error en primera instalación: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
      _globalSyncInProgress = false;
    }
  }

  /// ✅ MODIFICADO: Sincronización automática - Solo 1 lote
  Future<SyncResult> performAutoSync() async {
    if (_isSyncing) {
      print('⏭️ Sincronización ya en progreso, omitiendo...');
      return SyncResult.notNeeded();
    }

    if (!await shouldSync()) {
      print('⏭️ Sincronización no necesaria aún');
      return SyncResult.notNeeded();
    }

    _isSyncing = true;
    _globalSyncInProgress = true;

    try {
      print('🔄 Iniciando sincronización automática - 1 lote...');

      // Descargar solo 1 lote (respeta shouldSync)
      final events = await _downloadLatestBatch(isMultipleLots: false);

      if (events.isEmpty) {
        print('📭 No hay eventos nuevos');

        _notificationsProvider.addNotification(
          title: '✅ Todo actualizado',
          message: 'No hay eventos nuevos en este momento',
          type: 'sync_no_new_data',
          icon: '📱',
        );

        return SyncResult.noNewData();
      }

      await _processEvents(events);
      final cleanupResults = await _performCleanup();
      await _updateSyncTimestamp();
      await _sendSyncNotifications(events.length, cleanupResults);
      await _maintainNotificationSchedules();

      print('✅ Sincronización automática completada');
      final result = SyncResult.success(
        eventsAdded: events.length,
        eventsRemoved: cleanupResults.eventsRemoved,
        favoritesRemoved: cleanupResults.favoritesRemoved,
      );
      _syncCompleteController.add(result);
      return result;

    } catch (e) {
      print('❌ Error en sincronización automática: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
      _globalSyncInProgress = false;
    }
  }

  /// ✅ MODIFICADO: Force sync para desarrollo - 10 lotes
  Future<SyncResult> forceSync() async {
    if (_isSyncing) {
      print('⏭️ Sincronización ya en progreso, omitiendo...');
      return SyncResult.notNeeded();
    }

    _isSyncing = true;
    _globalSyncInProgress = true;

    try {
      print('🔄 FORZANDO sincronización (dev) - 10 lotes...');

      // Descargar 10 lotes (forzado para desarrollo)
      final events = await _downloadLatestBatch(isMultipleLots: true);

      if (events.isEmpty) {
        print('📭 No hay eventos nuevos');
        return SyncResult.noNewData();
      }

      await _processEvents(events);
      final cleanupResults = await _performCleanup();
      await _updateSyncTimestamp();
      await _maintainNotificationSchedules();

      print('✅ Sincronización FORZADA completada');
      final result = SyncResult.success(
        eventsAdded: events.length,
        eventsRemoved: cleanupResults.eventsRemoved,
        favoritesRemoved: cleanupResults.favoritesRemoved,
      );
      _syncCompleteController.add(result);
      return result;

    } catch (e) {
      print('❌ Error en sincronización forzada: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
      _globalSyncInProgress = false;
    }
  }

  // ========== DESCARGA DE FIRESTORE ==========

  /// ✅ MODIFICADO: Descargar lotes con parámetro de múltiples lotes
  Future<List<Map<String, dynamic>>> _downloadLatestBatch({required bool isMultipleLots}) async {
    try {
      print('📥 Descargando lote desde mock (luego firestore)...');

      final batchData = MockEvents.mockBatch;
      print('🔍 Campos disponibles en batchData: ${batchData.keys.toList()}');
      print('🔍 Total eventos en metadata: ${batchData['metadata']?['total_eventos']}');

      // Verificar si es un lote nuevo (solo para 1 lote)
      if (!isMultipleLots) {
        final currentBatchVersion = await _getCurrentBatchVersion();
        final newBatchVersion = batchData['metadata']?['nombre_lote'] as String? ?? 'unknown';
        final totalEventsInDB = await _eventRepository.getTotalEvents();

        if (currentBatchVersion == newBatchVersion && totalEventsInDB > 0) {
          print('📄 Mismo lote, no hay actualizaciones');
          _notificationsProvider.addNotification(
            title: '✅ Todo actualizado',
            message: 'La app está al día, no hay eventos nuevos',
            type: 'sync_up_to_date',
            icon: '📱',
          );
          return [];
        }
      }

      // Extraer eventos del lote
      final baseEvents = (batchData['eventos'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [];

      // ✅ NUEVA LÓGICA: Múltiples lotes basado en parámetro
      final events = isMultipleLots
          ? List.generate(10, (i) => baseEvents).expand((x) => x).toList()
          : baseEvents;

      if (isMultipleLots) {
        print('📥 Descarga múltiple: simulando 10 lotes');
      }

      print('📦 Descargados ${events.length} eventos');

      // Actualizar versión del lote
      final newBatchVersion = batchData['metadata']?['nombre_lote'] as String? ?? 'unknown';
      await _eventRepository.updateSyncInfo(
        batchVersion: newBatchVersion,
        totalEvents: events.length,
      );

      return events;

    } catch (e) {
      print('❌ Error descargando de Firestore: $e');
      rethrow;
    }
  }

  /// Obtener versión actual del lote
  Future<String> _getCurrentBatchVersion() async {
    final syncInfo = await _eventRepository.getSyncInfo();
    return syncInfo?['batch_version'] as String? ?? '0.0.0';
  }

  Future<void> _processEvents(List<Map<String, dynamic>> events) async {
    print('⚙️ Agregando ${events.length} eventos nuevos...');
    await _eventRepository.insertEvents(events);
    print('✅ ${events.length} eventos agregados a SQLite');
  }

  /// Limpiar eventos actuales (no favoritos)
  Future<void> _clearCurrentEvents() async {
    final db = await DatabaseHelper.database;
    await db.delete('eventos', where: 'favorite = ?', whereArgs: [0]);
  }

  // ========== LIMPIEZA AUTOMÁTICA ==========
  /// Realizar limpieza automática completa
  Future<CleanupResult> _performCleanup() async {
    print('🧹 Realizando limpieza automática...');

    final cleanupStats = await _eventRepository.cleanOldEvents();
    final duplicatesRemoved = await _eventRepository.removeDuplicatesByCodes();

    print('🗑️ Limpieza completada: ${cleanupStats['normalEvents']} eventos normales, ${cleanupStats['favoriteEvents']} favoritos, $duplicatesRemoved duplicados');

    return CleanupResult(
      eventsRemoved: cleanupStats['normalEvents']! + duplicatesRemoved,
      favoritesRemoved: cleanupStats['favoriteEvents']!,
    );
  }

  // ========== UTILIDADES ==========

  /// Actualizar timestamp de última sincronización
  Future<void> _updateSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Obtener información de última sincronización para UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    final syncInfo = await _eventRepository.getSyncInfo();
    final totalEvents = await _eventRepository.getTotalEvents();
    final totalFavorites = await _eventRepository.getTotalFavorites();

    return {
      'lastSync': lastSyncString,
      'batchVersion': syncInfo?['batch_version'],
      'totalEvents': totalEvents,
      'totalFavorites': totalFavorites,
      'needsSync': await shouldSync(),
    };
  }

  /// Forzar limpieza manual (solo para debug/settings)
  Future<CleanupResult> forceCleanup() async {
    return await _performCleanup();
  }

  /// ❌ ELIMINADO: syncOnAppStart() - Ya no se usa

  /// Reset completo (solo para debug)
  Future<void> resetSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    await _eventRepository.clearAllData();
  }

  // ========== NOTIFICACIONES AUTOMÁTICAS ==========

  /// Enviar notificaciones automáticas post-sincronización
  Future<void> _sendSyncNotifications(int newEventsCount, CleanupResult cleanupResults) async {
    try {
      if (newEventsCount > 0) {
        final notificationsProvider = _notificationsProvider;

        notificationsProvider.addNotification(
          title: '🎭 ¡Eventos nuevos en Córdoba!',
          message: 'Se agregaron $newEventsCount eventos culturales',
          type: 'new_events',
          icon: '🎉',
        );

        if (newEventsCount >= 10) {
          notificationsProvider.addNotification(
            title: '🔥 ¡Semana cargada de cultura!',
            message: 'Más de $newEventsCount eventos esperándote',
            type: 'high_activity',
            icon: '🌟',
          );
        }

        if (cleanupResults.eventsRemoved > 5) {
          notificationsProvider.addNotification(
            title: '🧹 Base de datos optimizada',
            message: 'Se limpiaron ${cleanupResults.eventsRemoved} eventos pasados',
            type: 'cleanup',
            icon: '✨',
          );
        }

        print('📱 Notificaciones de sync enviadas: $newEventsCount eventos');
      }

    } catch (e) {
      print('⚠️ Error enviando notificaciones de sync: $e');
    }
  }

  // Mantenimiento automático de recordatorios programados
  Future<void> _maintainNotificationSchedules() async {
    try {
      print('🔔 Manteniendo recordatorios programados...');

      final pendingNotifications = await _eventRepository.getPendingScheduledNotifications();

      int updated = 0;
      int removed = 0;

      for (final notification in pendingNotifications) {
        final eventCode = notification['event_code'] as String?;

        if (eventCode == null) continue;

        final db = await DatabaseHelper.database;
        final eventResults = await db.query(
          'eventos',
          where: 'code = ?',
          whereArgs: [eventCode],
          limit: 1,
        );

        if (eventResults.isEmpty) {
          await _eventRepository.deleteNotification(notification['id'] as int);
          removed++;
          print('🗑️ Recordatorio cancelado: evento $eventCode ya no existe');
          continue;
        }

        final event = eventResults.first;
        final currentEventDate = event['date'] as String;
        final notificationScheduled = notification['scheduled_datetime'] as String?;

        if (notificationScheduled != null) {
          final newScheduledTime = _calculateScheduledTime(
              currentEventDate,
              notification['type'] as String
          );

          if (newScheduledTime != notificationScheduled) {
            await db.update(
              'notifications',
              {'scheduled_datetime': newScheduledTime},
              where: 'id = ?',
              whereArgs: [notification['id']],
            );
            updated++;
            print('📅 Recordatorio actualizado: $eventCode nueva fecha $newScheduledTime');
          }
        }
      }

      if (updated > 0 || removed > 0) {
        print('🔔 Mantenimiento completado: $updated actualizados, $removed removidos');
      }

    } catch (e) {
      print('⚠️ Error en mantenimiento de recordatorios: $e');
    }
  }

  // Calcular scheduled_datetime basado en fecha de evento y tipo
  String? _calculateScheduledTime(String eventDate, String notificationType) {
    try {
      final eventDateTime = DateTime.parse(eventDate);

      switch (notificationType) {
        case 'event_reminder_tomorrow':
          return eventDateTime.subtract(Duration(days: 1, hours: 6)).toIso8601String();
        case 'event_reminder_today':
          return DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day, 9).toIso8601String();
        case 'event_reminder_hour':
          return eventDateTime.subtract(Duration(hours: 1)).toIso8601String();
        default:
          return null;
      }
    } catch (e) {
      print('⚠️ Error calculando scheduled_time: $e');
      return null;
    }
  }
}

// ========== MODELOS DE RESULTADO ==========

class SyncResult {
  final bool success;
  final String? error;
  final int eventsAdded;
  final int eventsRemoved;
  final int favoritesRemoved;
  final SyncResultType type;

  SyncResult._({
    required this.success,
    this.error,
    this.eventsAdded = 0,
    this.eventsRemoved = 0,
    this.favoritesRemoved = 0,
    required this.type,
  });

  factory SyncResult.success({
    required int eventsAdded,
    required int eventsRemoved,
    required int favoritesRemoved,
  }) => SyncResult._(
    success: true,
    eventsAdded: eventsAdded,
    eventsRemoved: eventsRemoved,
    favoritesRemoved: favoritesRemoved,
    type: SyncResultType.success,
  );

  factory SyncResult.notNeeded() => SyncResult._(
    success: true,
    type: SyncResultType.notNeeded,
  );

  factory SyncResult.noNewData() => SyncResult._(
    success: true,
    type: SyncResultType.noNewData,
  );

  factory SyncResult.error(String error) => SyncResult._(
    success: false,
    error: error,
    type: SyncResultType.error,
  );
}

enum SyncResultType { success, notNeeded, noNewData, error }

class CleanupResult {
  final int eventsRemoved;
  final int favoritesRemoved;

  CleanupResult({
    required this.eventsRemoved,
    required this.favoritesRemoved,
  });
}