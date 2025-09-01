//lib/src/sync/firestore_client.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/event_repository.dart';

class FirestoreClient {
  static final FirestoreClient _instance = FirestoreClient._internal();
  factory FirestoreClient() => _instance;
  FirestoreClient._internal();

  final EventRepository _eventRepository = EventRepository();
  static const String _lastSyncKey = 'last_sync_timestamp';

  static const int LOTES_POR_DIA = 1;
  static const int MAX_LOTES = 10;

  Future<List<Map<String, dynamic>>> downloadDailyBatches() async {
    try {
      final daysMissed = await _getDaysSinceLastSync();
      final lotesToDownload = (daysMissed * LOTES_POR_DIA).clamp(1, MAX_LOTES);
      // Cambiar para descargar + de 1 lote x dia 💥💥💥💥💥💥💥💥💥💥💥💥
      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos_lotes')
          .orderBy('metadata.fecha_subida', descending: true)
          .limit(lotesToDownload)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Retornar documentos completos con metadata + eventos
      final completeBatches = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      if (querySnapshot.docs.isNotEmpty) {
        final latestBatchVersion = completeBatches.first['metadata']?['nombre_lote'] as String? ?? 'unknown';

        // Contar total de eventos de todos los lotes
        final totalEvents = completeBatches.fold<int>(0, (sum, batch) {
          final eventos = (batch['eventos'] as List<dynamic>?) ?? [];
          return sum + eventos.length;
        });

        await _eventRepository.updateSyncInfo(
          batchVersion: latestBatchVersion,
          totalEvents: totalEvents,
        );
      }

      return completeBatches;

    } catch (e) {
      rethrow;
    }
  }

  Future<int> _getDaysSinceLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);

    if (lastSyncString == null) {
      return 1;
    }

    final lastSync = DateTime.parse(lastSyncString);
    final now = DateTime.now();

    final daysDifference = now.difference(lastSync).inDays;

    return daysDifference < 1 ? 1 : daysDifference;
  }

  Future<bool> shouldSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    final now = DateTime.now();

    if (lastSyncString == null) {
      return true;
    }

    final lastSync = DateTime.parse(lastSyncString);
    final hoursSinceLastSync = now.difference(lastSync).inHours;

    if (now.hour == 0 && hoursSinceLastSync >= 24) {
      return true;
    }

    final today = DateTime(now.year, now.month, now.day);
    final lastSyncDay = DateTime(lastSync.year, lastSync.month, lastSync.day);

    if (today.isAfter(lastSyncDay)) {
      if (now.hour >= 1) {
        return true;
      } else {
        return false;
      }
    }

    return false;
  }

  Future<void> updateSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }


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
      'daysMissed': daysMissed,
    };
  }

  Future<void> resetSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
  }
}