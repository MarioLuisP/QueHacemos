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

      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos_lotes')
          .orderBy('metadata.fecha_subida', descending: true)
          .limit(lotesToDownload)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final events = _getAllEventsFromDocs(querySnapshot.docs);

      if (querySnapshot.docs.isNotEmpty) {
        final latestBatchVersion = querySnapshot.docs.first.data()['metadata']?['nombre_lote'] as String? ?? 'unknown';
        await _eventRepository.updateSyncInfo(
          batchVersion: latestBatchVersion,
          totalEvents: events.length,
        );
      }

      return events;

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