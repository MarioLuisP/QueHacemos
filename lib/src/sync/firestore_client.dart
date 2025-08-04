// lib/src/sync/firestore_client.dart

//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/event_repository.dart';
import '../mock/mock_events.dart';

/// 🔒 CAPA 1 AISLADA - Solo External Data Sources
/// Responsabilidad única: Descargar datos de Firestore/Mock
/// BLINDAJE: No puede tocar SQLite, UI, ni coordinación
class FirestoreClient {
  static final FirestoreClient _instance = FirestoreClient._internal();
  factory FirestoreClient() => _instance;
  FirestoreClient._internal();

  final EventRepository _eventRepository = EventRepository();
  static const String _lastSyncKey = 'last_sync_timestamp';

  // ========== EXTERNAL DATA DOWNLOAD ==========

  /// 🔥 CORE: Descargar lotes desde Firestore/Mock
  /// Único método que toca external sources
  Future<List<Map<String, dynamic>>> downloadBatch({bool isMultipleLots = false, List<String>? specificBatches}) async { // CAMBIO
    try {
      print('📥 Descargando lote desde mock (luego firestore)...');

      // MOCK DATA (después será Firestore real)
      final batchData = MockEvents.mockBatch;

      /*
      // FIRESTORE REAL (comentado por ahora):
      final querySnapshot = await FirebaseFirestore.instance
        .collection('eventos_lotes')
        .orderBy('metadata.fecha_subida', descending: true)
        .limit(isMultipleLots ? 10 : 1)
        .get();

      if (querySnapshot.docs.isEmpty) {
        print('📭 No hay lotes disponibles en Firestore');
        return [];
      }

      final latestBatch = querySnapshot.docs.first;
      final batchData = latestBatch.data();
      */

      print('🔍 Campos disponibles en batchData: ${batchData.keys.toList()}');
      print('🔍 Total eventos en metadata: ${batchData['metadata']?['total_eventos']}');

      // Verificar si es un lote nuevo (solo para 1 lote)
      if (!isMultipleLots) {
        final currentBatchVersion = await _getCurrentBatchVersion();
        final newBatchVersion = batchData['metadata']?['nombre_lote'] as String? ?? 'unknown';
        final totalEventsInDB = await _eventRepository.getTotalEvents();

        if (currentBatchVersion == newBatchVersion && totalEventsInDB > 0) {
          print('📄 Mismo lote, no hay actualizaciones');
          return [];
        }
      }
// Extraer eventos del lote
      final baseEvents = (batchData['eventos'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [];

// NUEVO: Si se especifican lotes específicos, usar esa lista
      if (specificBatches != null && specificBatches.isNotEmpty) { // NUEVO
        print('📦 Descargando lotes específicos: ${specificBatches.join(", ")}'); // NUEVO
        final events = List.generate(specificBatches.length, (i) => baseEvents).expand((x) => x).toList(); // NUEVO
        print('📥 Descargados ${events.length} eventos de ${specificBatches.length} lotes específicos'); // NUEVO

        // Actualizar batch_version al último de la lista // NUEVO
        final lastBatch = specificBatches.last; // NUEVO
        await _eventRepository.updateSyncInfo( // NUEVO
          batchVersion: lastBatch, // NUEVO
          totalEvents: events.length, // NUEVO
        ); // NUEVO

        return events; // NUEVO
      } // NUEVO

// 🎯 LÓGICA DE MÚLTIPLES LOTES (legacy)
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
    final hoursSinceLastSync = now.difference(lastSync).inHours; // NUEVO

    // NUEVO: Ventana excepcional 00:00-01:00
    if (now.hour == 0 && hoursSinceLastSync >= 24) { // NUEVO
      print('🌙 Sincronización en ventana excepcional 00:00-01:00'); // NUEVO
      return true; // NUEVO
    } // NUEVO

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
  /// 📋 Obtener lista de lotes disponibles desde servidor // NUEVO
  Future<List<String>> getAvailableBatches() async { // NUEVO
    try { // NUEVO
      print('📋 Obteniendo lista de lotes disponibles...'); // NUEVO

      // MOCK: Simular lotes disponibles ordenados cronológicamente // NUEVO
      final availableBatches = [ // NUEVO
        'lote_2025_08_01_mock_1', // NUEVO
        'lote_2025_08_02_mock_1', // NUEVO
        'lote_2025_08_03_mock_1', // NUEVO
        'lote_2025_08_04_mock_1', // NUEVO
        'lote_2025_08_04_mock_2', // NUEVO
      ]; // NUEVO

      /* // NUEVO
      // FIRESTORE REAL (comentado por ahora): // NUEVO
      final querySnapshot = await FirebaseFirestore.instance // NUEVO
        .collection('lotes_metadata') // NUEVO
        .orderBy('fecha_creacion') // NUEVO
        .get(); // NUEVO

      final availableBatches = querySnapshot.docs // NUEVO
        .map((doc) => doc.id) // NUEVO
        .toList(); // NUEVO
      */ // NUEVO

      print('📋 Lotes disponibles: ${availableBatches.length}'); // NUEVO
      return availableBatches; // NUEVO

    } catch (e) { // NUEVO
      print('❌ Error obteniendo lista de lotes: $e'); // NUEVO
      return []; // NUEVO
    } // NUEVO
  } // NUEVO
  // ========== UTILIDADES INTERNAS ==========

  /// Obtener versión actual del lote
  Future<String> _getCurrentBatchVersion() async {
    final syncInfo = await _eventRepository.getSyncInfo();
    return syncInfo?['batch_version'] as String? ?? '0.0.0';
  }

  // ========== STATUS METHODS ==========

  /// 📊 Obtener información de última sincronización para UI
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

  /// 🔄 Reset completo de sync state (solo para debug)
  Future<void> resetSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    print('🗑️ Sync state reseteado');
  }
}