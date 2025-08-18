//lib/src/sync/firestore_client.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/event_repository.dart';

/// 🔥 FIRESTORE CLIENT SIMPLIFICADO
/// Responsabilidad única: Descargar lotes diarios de Firestore
/// NUEVA LÓGICA: 1 lote por día faltante (máximo 10)
class FirestoreClient {
  static final FirestoreClient _instance = FirestoreClient._internal();
  factory FirestoreClient() => _instance;
  FirestoreClient._internal();

  final EventRepository _eventRepository = EventRepository();
  static const String _lastSyncKey = 'last_sync_timestamp';

  // 🎯 CONFIGURACIÓN ESCALABLE
  static const int LOTES_POR_DIA = 1;  // ← Cambiar para escalar🔥🔥🔥🔥🔥🔥
  static const int MAX_LOTES = 10;     // ← Límite de recuperación

  // ========== MÉTODO PRINCIPAL SIMPLIFICADO ==========

  /// 🔥 Descargar lotes basado en días desde última sync
  /// SÚPER SIMPLE: días_faltantes × LOTES_POR_DIA (máx 10)
  Future<List<Map<String, dynamic>>> downloadDailyBatches() async {
    try {
      final daysMissed = await _getDaysSinceLastSync();
      final lotesToDownload = (daysMissed * LOTES_POR_DIA).clamp(1, MAX_LOTES);

      print('📅 Días desde última sync: $daysMissed');
      print('📦 Descargando $lotesToDownload lotes...');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos_lotes')
          .orderBy('metadata.fecha_subida', descending: true)
          .limit(lotesToDownload)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('📭 No hay lotes disponibles en Firestore');
        return [];
      }

      // Procesar todos los lotes descargados
      final events = _getAllEventsFromDocs(querySnapshot.docs);

      // Actualizar info de sync
      if (querySnapshot.docs.isNotEmpty) {
        final latestBatchVersion = querySnapshot.docs.first.data()['metadata']?['nombre_lote'] as String? ?? 'unknown';
        await _eventRepository.updateSyncInfo(
          batchVersion: latestBatchVersion,
          totalEvents: events.length,
        );
      }

      print('✅ Total descargado: ${events.length} eventos de ${querySnapshot.docs.length} lotes');
      return events;

    } catch (e) {
      print('❌ Error descargando lotes diarios: $e');
      rethrow;
    }
  }

  // ========== LÓGICA DE DÍAS ==========

  /// 📅 Calcular días desde última sincronización
  Future<int> _getDaysSinceLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);

    if (lastSyncString == null) {
      print('🔄 Primera sincronización');
      return 1; // Solo 1 lote para primera sync diaria
    }

    final lastSync = DateTime.parse(lastSyncString);
    final now = DateTime.now();

    // Calcular diferencia en días
    final daysDifference = now.difference(lastSync).inDays;

    // Mínimo 1 día (para sync diario normal)
    return daysDifference < 1 ? 1 : daysDifference;
  }

  // ========== SYNC TIMING LOGIC ==========

  /// 🕐 Verificar si necesita sincronización (1 AM logic + ventana 00:00-01:00)
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
    final hoursSinceLastSync = now.difference(lastSync).inHours;

    // Ventana excepcional 00:00-01:00
    if (now.hour == 0 && hoursSinceLastSync >= 24) {
      print('🌙 Sincronización en ventana excepcional 00:00-01:00');
      return true;
    }

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

  /// 📅 Actualizar timestamp de última sincronización
  Future<void> updateSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // ========== UTILIDADES ==========

  /// 🔧 Extraer eventos de documentos Firestore
  List<Map<String, dynamic>> _getAllEventsFromDocs(List<QueryDocumentSnapshot> docs) {
    final allEvents = <Map<String, dynamic>>[];
    for (final doc in docs) {
      final batchData = doc.data() as Map<String, dynamic>;
      final eventos = (batchData['eventos'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [];
      allEvents.addAll(eventos);
    }
    return allEvents;
  }

  // ========== STATUS METHODS ==========

  /// 📊 Obtener información de última sincronización para UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    final syncInfo = await _eventRepository.getSyncInfo();
    final totalEvents = await _eventRepository.getTotalEvents();
    final totalFavorites = await _eventRepository.getTotalFavorites();
    final daysMissed = await _getDaysSinceLastSync();

    return {
      'lastSync': lastSyncString,
      'batchVersion': syncInfo?['batch_version'],
      'totalEvents': totalEvents,
      'totalFavorites': totalFavorites,
      'needsSync': await shouldSync(),
      'daysMissed': daysMissed, // ← NUEVO: útil para debug
    };
  }

  /// 🔄 Reset completo de sync state (solo para debug)
  Future<void> resetSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    print('🗑️ Sync state reseteado');
  }
}