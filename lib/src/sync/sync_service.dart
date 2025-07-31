//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../data/repositories/event_repository.dart';
import '../data/database/database_helper.dart';
import '../mock/mock_events.dart';
import '../providers/mock_notifications_provider.dart';//import '../providers/notifications_provider.dart'; // CAMBIO: ruta corregida


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

  // ========== DESCARGA DE FIRESTORE ==========

  /// Descargar último lote de eventos de Firestore
  Future<List<Map<String, dynamic>>> _downloadLatestBatch() async {
    try {
      print('📥 Descargando lote desde mok(luego firestore...');

      /*final querySnapshot = await FirebaseFirestore.instance
       .collection('eventos_lotes')
       .orderBy('metadata.fecha_subida', descending: true)
       .limit(1)
       .get();

   if (querySnapshot.docs.isEmpty) {
     print('📭 No hay lotes disponibles en Firestore');
     return [];
   }

   final latestBatch = querySnapshot.docs.first;
   final batchData = latestBatch.data();
   */
      final batchData = MockEvents.mockBatch;
      print('🔍 Campos disponibles en batchData: ${batchData.keys.toList()}');
      print('🔍 Total eventos en metadata: ${batchData['metadata']?['total_eventos']}');

      // Verificar si es un lote nuevo
      final currentBatchVersion = await _getCurrentBatchVersion();
      final newBatchVersion = batchData['metadata']?['nombre_lote'] as String? ?? 'unknown';
      final totalEventsInDB = await _eventRepository.getTotalEvents();
      final isFirstTime = totalEventsInDB == 0;

      if (currentBatchVersion == newBatchVersion && totalEventsInDB > 0) {
        print('📄 Mismo lote, no hay actualizaciones');
        // NUEVO: Notificar que la app está actualizada
        _notificationsProvider.addNotification(
          title: '✅ Todo actualizado',
          message: 'La app está al día, no hay eventos nuevos',
          type: 'sync_up_to_date',
          icon: '📱',
        );
        return [];
      }

      // Extraer eventos del lote (datos completos)
      final baseEvents = (batchData['eventos'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [];

      // Para mock: simular múltiples lotes si es primera vez
      final events = isFirstTime
          ? List.generate(10, (i) => baseEvents).expand((x) => x).toList()
          : baseEvents;

      if (isFirstTime) {
        print('📥 Primera descarga: simulando 10 lotes');
      }

      print('📦 Descargados ${events.length} eventos - Versión: $newBatchVersion');

      // Actualizar versión del lote
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
    print('⚙️ Agregando ${events.length} eventos nuevos...'); // CAMBIO

    // BATCH INSERT súper rápido - NO borrar nada - NUEVO
    await _eventRepository.insertEvents(events);

    print('✅ ${events.length} eventos agregados a SQLite'); // CAMBIO
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
    final duplicatesRemoved = await _eventRepository.removeDuplicatesByCodes(); // NUEVO: limpieza duplicados

    print('🗑️ Limpieza completada: ${cleanupStats['normalEvents']} eventos normales, ${cleanupStats['favoriteEvents']} favoritos, $duplicatesRemoved duplicados'); // CAMBIO: agregar duplicados

    return CleanupResult(
      eventsRemoved: cleanupStats['normalEvents']! + duplicatesRemoved,        // CAMBIO: incluir duplicados
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

  /// Sincronización al abrir la app
  Future<void> syncOnAppStart() async {
    if (await shouldSync()) {
      await performAutoSync();
    }
  }
  /// Sincronización automática (respeta shouldSync)
  Future<SyncResult> performAutoSync() async {                    // NUEVO: método principal automático
    if (_isSyncing) {                                            // NUEVO: verificar flag
      print('⏭️ Sincronización ya en progreso, omitiendo...');
      return SyncResult.notNeeded();
    }

    if (!await shouldSync()) {                                   // NUEVO: respetar verificaciones
      print('⏭️ Sincronización no necesaria aún');
      return SyncResult.notNeeded();
    }

    _isSyncing = true;
    _globalSyncInProgress = true; // NUEVO: Activar flag global                                         // NUEVO: activar flag

    try {
      print('🔄 Iniciando sincronización automática...');

      final events = await _downloadLatestBatch();               // NUEVO: usar método existente

      if (events.isEmpty) {
        print('📭 No hay eventos nuevos');

        // NUEVO: Notificar que sync completó sin eventos nuevos
        _notificationsProvider.addNotification(
          title: '✅ Todo actualizado',
          message: 'No hay eventos nuevos en este momento',
          type: 'sync_no_new_data',
          icon: '📱',
        );

        return SyncResult.noNewData();
      }

      await _processEvents(events);                              // NUEVO: procesar eventos
      final cleanupResults = await _performCleanup();           // NUEVO: limpieza
      await _updateSyncTimestamp();                              // NUEVO: actualizar timestamp
      // NUEVO: Enviar notificaciones automáticas
      await _sendSyncNotifications(events.length, cleanupResults);

      await _maintainNotificationSchedules();

      print('✅ Sincronización automática completada');
      final result = SyncResult.success(                                     // NUEVO: resultado exitoso
        eventsAdded: events.length,
        eventsRemoved: cleanupResults.eventsRemoved,
        favoritesRemoved: cleanupResults.favoritesRemoved,
      );
      _syncCompleteController.add(result);                               // NUEVO: notificar completion
      return result;

    } catch (e) {
      print('❌ Error en sincronización automática: $e');
      return SyncResult.error(e.toString());                     // NUEVO: manejo de errores
    } finally {
      _isSyncing = false;                                        // NUEVO: desactivar flag
    }
  }

  /// Reset completo (solo para debug)
  Future<void> resetSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    await _eventRepository.clearAllData();
  }
  /// MÉTODO TEMPORAL PARA DEV - BORRAR EN PRODUCCIÓN 🔥
  Future<SyncResult> forceSync() async {
    if (_isSyncing) {
      print('⏭️ Sincronización ya en progreso, omitiendo...');
      return SyncResult.notNeeded();
    }

    _isSyncing = true;
    _globalSyncInProgress = true; // NUEVO: Activar flag global

    try {
      print('🔄 FORZANDO sincronización (dev)...');

      // CAMBIO: Saltar verificación de shouldSync() pero forzar descarga
      final events = await _downloadLatestBatch();

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
      _syncCompleteController.add(result);                                 // NUEVO: notificar completion
      return result;

    } catch (e) {
      print('❌ Error en sincronización forzada: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
      _globalSyncInProgress = false; // NUEVO: Liberar flag global
    }
  }
// ========== NOTIFICACIONES AUTOMÁTICAS ========== // NUEVO

  /// NUEVO: Enviar notificaciones automáticas post-sincronización
  Future<void> _sendSyncNotifications(int newEventsCount, CleanupResult cleanupResults) async {
    try {
      // NUEVO: Solo notificar si hay eventos nuevos significativos
      if (newEventsCount > 0) {
        // NUEVO: Crear instancia de NotificationsProvider
        final notificationsProvider = _notificationsProvider;
        // NUEVO: Notificación principal de eventos nuevos
        notificationsProvider.addNotification(
          title: '🎭 ¡Eventos nuevos en Córdoba!',
          message: 'Se agregaron $newEventsCount eventos culturales',
          type: 'new_events',
          icon: '🎉',
        );

        // NUEVO: Notificación adicional si hay muchos eventos
        if (newEventsCount >= 10) {
          notificationsProvider.addNotification(
            title: '🔥 ¡Semana cargada de cultura!',
            message: 'Más de $newEventsCount eventos esperándote',
            type: 'high_activity',
            icon: '🌟',
          );
        }

        // NUEVO: Notificación de limpieza si fue significativa
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
      // NUEVO: No fallar la sincronización por errores de notificaciones
    }
  }

  // NUEVO: Mantenimiento automático de recordatorios programados
  Future<void> _maintainNotificationSchedules() async {
    try {
      print('🔔 Manteniendo recordatorios programados...');

      // NUEVO: Obtener todos los recordatorios pendientes
      final pendingNotifications = await _eventRepository.getPendingScheduledNotifications();

      int updated = 0;                              // NUEVO: contador de actualizaciones
      int removed = 0;                              // NUEVO: contador de removidos

      for (final notification in pendingNotifications) {
        final eventCode = notification['event_code'] as String?;

        if (eventCode == null) continue;            // NUEVO: skip si no tiene event_code

        // NUEVO: Buscar evento actual por code en tabla eventos
        final db = await DatabaseHelper.database;
        final eventResults = await db.query(       // NUEVO: query por code
          'eventos',
          where: 'code = ?',
          whereArgs: [eventCode],
          limit: 1,
        );

        if (eventResults.isEmpty) {                // NUEVO: evento ya no existe
          // NUEVO: Cancelar recordatorio huérfano
          await _eventRepository.deleteNotification(notification['id'] as int);
          removed++;
          print('🗑️ Recordatorio cancelado: evento $eventCode ya no existe');
          continue;
        }

        final event = eventResults.first;
        final currentEventDate = event['date'] as String;
        final notificationScheduled = notification['scheduled_datetime'] as String?;

        if (notificationScheduled != null) {       // NUEVO: verificar si fecha cambió
          // NUEVO: Recalcular scheduled_datetime basado en nueva fecha del evento
          final newScheduledTime = _calculateScheduledTime(
              currentEventDate,
              notification['type'] as String
          );

          if (newScheduledTime != notificationScheduled) { // NUEVO: fecha cambió
            // NUEVO: Actualizar scheduled_datetime en la base de datos
            await db.update(                       // NUEVO: update directo en db
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

      if (updated > 0 || removed > 0) {           // NUEVO: log solo si hubo cambios
        print('🔔 Mantenimiento completado: $updated actualizados, $removed removidos');
      }

    } catch (e) {
      print('⚠️ Error en mantenimiento de recordatorios: $e');
      // NUEVO: No fallar sync por errores de mantenimiento
    }
  }

  // NUEVO: Calcular scheduled_datetime basado en fecha de evento y tipo
  String? _calculateScheduledTime(String eventDate, String notificationType) {
    try {
      final eventDateTime = DateTime.parse(eventDate); // NUEVO: parsear fecha del evento

      switch (notificationType) {                 // NUEVO: lógica por tipo de recordatorio
        case 'event_reminder_tomorrow':           // NUEVO: recordatorio "mañana"
          return eventDateTime.subtract(Duration(days: 1, hours: 6)).toIso8601String();
        case 'event_reminder_today':              // NUEVO: recordatorio "hoy"
          return DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day, 9).toIso8601String();
        case 'event_reminder_hour':               // NUEVO: recordatorio "1 hora antes"
          return eventDateTime.subtract(Duration(hours: 1)).toIso8601String();
        default:
          return null;                           // NUEVO: tipo no reconocido
      }
    } catch (e) {
      print('⚠️ Error calculando scheduled_time: $e');
      return null;                               // NUEVO: fallback seguro
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