// lib/src/sync/sync_service.dart

import 'dart:async';
import '../data/repositories/event_repository.dart';
import '../data/database/database_helper.dart';
import '../providers/notifications_provider.dart';
import 'firestore_client.dart'; // 🔥 NUEVA DEPENDENCIA
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/simple_home_provider.dart'; // 🔥 Para usar SimpleHomeProvider

/// 🏗️ SYNC SERVICE LIMPIO - Solo CAPA 2 + Coordinación
/// Responsabilidades: Processing, Cleanup, Notifications, Orchestration
/// BLINDAJE: No puede tocar external sources - depende de FirestoreClient
class SyncService {
  SimpleHomeProvider? _homeProvider;
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  /// Inyectar el provider de UI para poder refrescar la cache después del sync
  void setHomeProvider(SimpleHomeProvider provider) {
    _homeProvider = provider;
    print('🔗 SyncService: SimpleHomeProvider inyectado. Cache actual: ${_homeProvider?.eventCount ?? 0} eventos');
  }
  // StreamController para notificar cuando termina sync
  static final StreamController<SyncResult> _syncCompleteController =
  StreamController<SyncResult>.broadcast();

  // Stream público para escuchar completions de sync
  static Stream<SyncResult> get onSyncComplete => _syncCompleteController.stream;

  final EventRepository _eventRepository = EventRepository();
  final FirestoreClient _firestoreClient = FirestoreClient(); // 🔥 CAPA 1 AISLADA
  NotificationsProvider get _notificationsProvider => NotificationsProvider.instance;

  // Flags para evitar múltiples sincronizaciones
  bool _isSyncing = false;
  static bool _globalSyncInProgress = false;

  // ========== MÉTODOS PRINCIPALES DE SYNC ==========

  /// 🔄 Sincronización automática diaria - Solo 1 lote
  Future<SyncResult> performAutoSync() async {
    if (_isSyncing) {
      print('⏭️ Sincronización ya en progreso, omitiendo...');
      return SyncResult.notNeeded();
    }

    // 🔥 USAR FIRESTORE CLIENT - Verificar timing
    if (!await _firestoreClient.shouldSync()) {
      print('⏭️ Sincronización no necesaria aún');
      return SyncResult.notNeeded();
    }
    print('🐛 DEBUG shouldSync: ${await _firestoreClient.shouldSync()}');
    _isSyncing = true;
    _globalSyncInProgress = true;

    try {

      print('🔄 Iniciando sync diario - delegando filtrado a FirestoreClient...');

      // Delegar toda la lógica al nuevo enfoque de FirestoreClient
      final events = await _firestoreClient.downloadDailyBatches();

      if (events.isEmpty) {
        print('🔭 No hay eventos nuevos disponibles');
        _notificationsProvider.addNotification(
          title: '✅ Todo actualizado',
          message: 'La app está al día, no hay eventos nuevos',
          type: 'sync_up_to_date',
        );
        return SyncResult.noNewData();
      }

      print('📦 Descargados ${events.length} eventos nuevos');

      // Processing interno (CAPA 2)
      await _processEvents(events);
      final cleanupResults = await _performCleanup();

      // Update timestamp via FirestoreClient
      await _firestoreClient.updateSyncTimestamp();

      // Notifications y maintenance
      final realNewEvents = events.length - cleanupResults.duplicatesRemoved;
      await _sendSyncNotifications(realNewEvents, cleanupResults);
      await _maintainNotificationSchedules();
      // 🔁 Refrescar UI si hay nuevos eventos y el provider está inyectado
      if (_homeProvider != null && events.isNotEmpty) {
        print('🔁 SyncService: refrescando UI con ${events.length} nuevos eventos...');
        _homeProvider!.refresh(); // ⚡ sin await → no bloquea el sync
      }
      print('✅ Sincronización automática completada: ${events.length} eventos nuevos');
      final result = SyncResult.success(
        eventsAdded: events.length,
        eventsRemoved: cleanupResults.eventsRemoved,
        favoritesRemoved: cleanupResults.favoritesRemoved,
      );
      _syncCompleteController.add(result);
      return result;

    } catch (e) {
      print('❌ Error en sincronización automática: $e');

      // Notificar error en sync automático
      _notificationsProvider.addNotification(
        title: '⚠️ Error al actualizar contenido',
        message: 'Problema de conexión - usando contenido guardado',
        type: 'auto_sync_error',
      );

      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
      _globalSyncInProgress = false;
    }
  }
  /// 💪 Force sync para desarrollo - ejecuta sync automático
  Future<SyncResult> forceSync() async {
    print('🔧 DEV: Force sync ejecutando sync automático...');
    return await performAutoSync();
  }
  // ========== PROCESSING INTERNO (CAPA 2) ==========

  /// ⚙️ Procesar eventos descargados (inserción masiva a SQLite)
  Future<void> _processEvents(List<Map<String, dynamic>> events) async {
    print('⚙️ Agregando ${events.length} eventos nuevos...');
    await _eventRepository.insertEvents(events);
    print('✅ ${events.length} eventos agregados a SQLite');
  }

  /// 🧹 Realizar limpieza automática completa
  Future<CleanupResult> _performCleanup() async {
    print('🧹 Realizando limpieza automática...');

    final cleanupStats = await _eventRepository.cleanOldEvents();
    final duplicatesRemoved = await _eventRepository.removeDuplicatesByCodes();

    print('🗑️ Limpieza completada: ${cleanupStats['normalEvents']} eventos normales, ${cleanupStats['favoriteEvents']} favoritos, $duplicatesRemoved duplicados');

    return CleanupResult(
      eventsRemoved: cleanupStats['normalEvents']! + duplicatesRemoved,
      favoritesRemoved: cleanupStats['favoriteEvents']!,
      duplicatesRemoved: duplicatesRemoved, // ← AGREGAR
    );
  }

  // ========== UTILIDADES PÚBLICAS ==========

  /// 📊 Obtener información de sincronización para UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    // 🔥 DELEGAR A FIRESTORE CLIENT
    return await _firestoreClient.getSyncStatus();
  }

  /// 🧹 Forzar limpieza manual (solo para debug/settings)
  Future<CleanupResult> forceCleanup() async {
    return await _performCleanup();
  }

  /// 🔄 Reset completo (solo para debug)
  Future<void> resetSync() async {
    await _firestoreClient.resetSyncState();
    await _eventRepository.clearAllData();
    print('🗑️ Sync completamente reseteado');
  }

  // ========== NOTIFICACIONES (CAPA 3) ==========

  /// 📱 Enviar notificaciones automáticas post-sincronización
  Future<void> _sendSyncNotifications(int newEventsCount, CleanupResult cleanupResults) async {
    try {
      if (newEventsCount > 0) {
        final notificationsProvider = _notificationsProvider;

        notificationsProvider.addNotification(
          title: '🎭 ¡Eventos nuevos en Córdoba!',
          message: 'Se agregaron $newEventsCount eventos culturales',
          type: 'new_events',
        );

        if (newEventsCount >= 10) {
          notificationsProvider.addNotification(
            title: '🔥 ¡Semana cargada de cultura!',
            message: 'Más de $newEventsCount eventos esperándote',
            type: 'high_activity',
          );
        }

        if (cleanupResults.eventsRemoved > 5) {
          notificationsProvider.addNotification(
            title: '🧹 Base de datos optimizada',
            message: 'Se limpiaron ${cleanupResults.eventsRemoved} eventos pasados',
            type: 'cleanup',
          );
        }

        print('📱 Notificaciones de sync enviadas: $newEventsCount eventos');
      }

    } catch (e) {
      print('⚠️ Error enviando notificaciones de sync: $e');
    }
  }

  // ========== MAINTENANCE ==========

  /// 🔔 Mantenimiento automático de recordatorios programados
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

  /// 📅 Calcular scheduled_datetime basado en fecha de evento y tipo
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
  final int duplicatesRemoved; // ← AGREGAR

  CleanupResult({
    required this.eventsRemoved,
    required this.favoritesRemoved,
    required this.duplicatesRemoved, // ← AGREGAR
  });
}