import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/event_repository.dart';

class FirestoreClient {
  static final FirestoreClient _instance = FirestoreClient._internal();
  factory FirestoreClient() => _instance;
  FirestoreClient._internal();

  final EventRepository _eventRepository = EventRepository();
  static const String _lastSyncKey = 'last_sync_timestamp';

  Future<List<Map<String, dynamic>>> downloadBatch({bool isMultipleLots = false, List<String>? specificBatches}) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos_lotes')
          .orderBy('metadata.fecha_subida', descending: true)
          .limit(isMultipleLots ? 10 : 1)
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      final latestBatch = querySnapshot.docs.first;
      final batchData = latestBatch.data();

      if (!isMultipleLots) {
        final currentBatchVersion = await _getCurrentBatchVersion();
        final newBatchVersion = batchData['metadata']?['nombre_lote'] as String? ?? 'unknown';
        final totalEventsInDB = await _eventRepository.getTotalEvents();

        if (currentBatchVersion == newBatchVersion && totalEventsInDB > 0) {
          return [];
        }
      }

      final baseEvents = (batchData['eventos'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [];

      if (specificBatches != null && specificBatches.isNotEmpty) {
        final events = List.generate(specificBatches.length, (i) => baseEvents).expand((x) => x).toList();
        final lastBatch = specificBatches.last;
        await _eventRepository.updateSyncInfo(
          batchVersion: lastBatch,
          totalEvents: events.length,
        );
        return events;
      }

      final events = baseEvents;
      final newBatchVersion = batchData['metadata']?['nombre_lote'] as String? ?? 'unknown';
      await _eventRepository.updateSyncInfo(
        batchVersion: newBatchVersion,
        totalEvents: events.length,
      );

      return events;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> shouldSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    final now = DateTime.now();

    if (lastSyncString == null) return true;

    final lastSync = DateTime.parse(lastSyncString);
    final hoursSinceLastSync = now.difference(lastSync).inHours;

    if (now.hour == 0 && hoursSinceLastSync >= 24) return true;

    final today = DateTime(now.year, now.month, now.day);
    final lastSyncDay = DateTime(lastSync.year, lastSync.month, lastSync.day);

    if (today.isAfter(lastSyncDay)) {
      if (now.hour >= 1) return true;
      return false;
    }

    return false;
  }

  Future<void> updateSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  Future<List<String>> getAvailableBatches() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos_lotes')
          .orderBy('metadata.fecha_subida', descending: true)
          .limit(20)
          .get();

      final availableBatches = querySnapshot.docs
          .map((doc) => doc.data()['metadata']['nombre_lote'] as String)
          .toList();

      return availableBatches;
    } catch (e) {
      return [];
    }
  }

  Future<String> _getCurrentBatchVersion() async {
    final syncInfo = await _eventRepository.getSyncInfo();
    return syncInfo?['batch_version'] as String? ?? '0.0.0';
  }

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

  Future<void> resetSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
  }
}
