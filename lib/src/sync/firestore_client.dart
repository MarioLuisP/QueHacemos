//lib/src/sync/firestore_client.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/event_repository.dart';
import '../mock/mock_events.dart';

/// 🔒 CAPA 1 AISLADA - Solo External Data Sources
/// Responsabilidad única: Descargar datos de Firestore
/// BLINDAJE: No puede tocar SQLite, UI, ni coordinación
class FirestoreClient {
  static final FirestoreClient _instance = FirestoreClient._internal();
  factory FirestoreClient() => _instance;
  FirestoreClient._internal();

  final EventRepository _eventRepository = EventRepository();
  static const String _lastSyncKey = 'last_sync_timestamp';

  // ========== EXTERNAL DATA DOWNLOAD ==========

  /// 🔥 CORE: Descargar lotes desde Firestore
  /// Único método que toca external sources
  Future<List<Map<String, dynamic>>> downloadBatch({bool isMultipleLots = false, List<String>? specificBatches}) async {
    try {
      print('📥 Descargando lote desde mock (luego firestore)...');

      // MOCK DATA (después será Firestore real)
      // final batchData = MockEvents.mockBatch;


      // FIRESTORE REAL (comentado por ahora):
      final querySnapshot = await FirebaseFirestore.instance
        .collection('eventos_lotes')
        .orderBy('metadata.fecha_subida', descending: true)
        .limit(isMultipleLots ? 10 : 5)
        .get();

      if (querySnapshot.docs.isEmpty) {
        print('📭 No hay lotes disponibles en Firestore');
        return [];
      }

      // Si se especifican lotes específicos, usar nuevo enfoque eficiente
      if (specificBatches != null && specificBatches.isNotEmpty) {
        print('🔦 Sync diario - descargando 5 lotes más recientes...');

        final currentBatchVersion = await _getCurrentBatchVersion();

        // Filtrar solo lotes nuevos
        final newBatches = querySnapshot.docs.where((doc) {
          final batchName = doc.data()['metadata']?['nombre_lote'] as String? ?? '';
          return batchName.compareTo(currentBatchVersion) > 0;
        }).toList();

        if (newBatches.isEmpty) {
          print('📄 No hay lotes nuevos disponibles');
          return [];
        }

        // Procesar eventos de todos los lotes nuevos
        final allEvents = _getAllEventsFromDocs(newBatches);

        // Actualizar con el más reciente
        final latestBatchVersion = newBatches.first.data()['metadata']?['nombre_lote'] as String? ?? 'unknown';
        await _eventRepository.updateSyncInfo(
          batchVersion: latestBatchVersion,
          totalEvents: allEvents.length,
        );

        print('✅ Total descargado: ${allEvents.length} eventos de ${newBatches.length} lotes nuevos');
        return allEvents;
      }


// 🎯 PRIMERA INSTALACIÓN - Procesar todos los lotes descargados
      final events = _getAllEventsFromDocs(querySnapshot.docs);
      print('🔦 Primera instalación: ${events.length} eventos de ${querySnapshot.docs.length} lotes');

      // Actualizar versión del lote más reciente
      final newBatchVersion = querySnapshot.docs.first.data()['metadata']?['nombre_lote'] as String? ?? 'multiple';
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

  // ========== UTILIDADES INTERNAS ==========

  /// Obtener versión actual del lote
  Future<String> _getCurrentBatchVersion() async {
    final syncInfo = await _eventRepository.getSyncInfo();
    return syncInfo?['batch_version'] as String? ?? '';
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