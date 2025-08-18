// lib/src/services/first_install_service.dart

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../sync/firestore_client.dart';
import '../data/repositories/event_repository.dart';
import '../providers/notifications_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../cache/event_cache_service.dart';
import '../sync/sync_service.dart'; // ← AÑADIR ESTE// ← NUEVO// ← NUEVO

/// 🚀 SERVICIO AUTÓNOMO DE PRIMERA INSTALACIÓN
/// Responsabilidad única: Setup técnico completo de la app
/// Ejecuta UNA SOLA VEZ en la vida de la app
class FirstInstallService {
  static final FirstInstallService _instance = FirstInstallService._internal();
  factory FirstInstallService() => _instance;

  FirstInstallService._internal() {
    // Escuchar completions de sync diario para actualizar cache
    SyncService.onSyncComplete.listen((result) {
      if (result.success && result.eventsAdded > 0) {
        _refreshSimpleHomeProvider();
      }
    });
  }

  // Flag independiente para primera instalación
  static const String _firstInstallKey = 'first_install_completed';

  // Componentes necesarios
  final FirestoreClient _firestoreClient = FirestoreClient();
  final EventRepository _eventRepository = EventRepository();
  final NotificationsProvider _notificationsProvider = NotificationsProvider.instance;

  // Control de proceso
  bool _isRunning = false;

  // ========== MÉTODO PRINCIPAL ==========

  /// 🎯 Verificar si necesita primera instalación
  Future<bool> needsFirstInstall() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_firstInstallKey) ?? false);
  }

  /// 🚀 Ejecutar primera instalación completa
  Future<FirstInstallResult> performFirstInstall() async {
    if (_isRunning) {
      return FirstInstallResult.alreadyRunning();
    }

    _isRunning = true;

    try {
      print('🚀 Iniciando primera instalación...');

      // 1. Verificación inicial
      if (!await needsFirstInstall()) {
        print('✅ Primera instalación ya completada previamente');
        return FirstInstallResult.alreadyCompleted();
      }

      // 2. Preparación técnica
      await _prepareTechnicalSetup();

      // 3. Descarga con reintentos
      final events = await _downloadInitialContent();

      // 4. Procesamiento de datos
      await _processInitialData(events);

      // 5. Finalización exitosa
      await _markFirstInstallCompleted();
      await _notifySuccess(events.length);
      /// 📅 Marcar sync como recién hecho (evitar recovery inmediato)
      Future<void> _setInitialSyncTimestamp() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_sync_timestamp', DateTime.now().toIso8601String());
        print('⏰ Timestamp de sync inicial seteado');
      }
      print('🎉 Primera instalación completada exitosamente');
      return FirstInstallResult.success(eventsDownloaded: events.length);

    } catch (e) {
      print('❌ Error en primera instalación: $e');
      await _notifyError(e);
      return FirstInstallResult.error(e.toString());
    } finally {
      _isRunning = false;
    }
  }

  // ========== MÉTODOS INTERNOS ==========

  /// 🔧 Preparación técnica inicial
  Future<void> _prepareTechnicalSetup() async {
    print('🔧 Preparando setup técnico...');

    // Inicializar base de datos (auto-creación de tablas)
    await _eventRepository.getTotalEvents(); // Trigger database creation

    print('✅ Base de datos SQLite inicializada');
  }

  /// 🔥 Descarga de contenido inicial con reintentos (AUTÓNOMO)
  Future<List<Map<String, dynamic>>> _downloadInitialContent() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔥 Intento $attempt/$maxRetries: Descargando 10 lotes iniciales...');

        // NUEVA LÓGICA AUTÓNOMA - Sin FirestoreClient
        final events = await _downloadFromFirestore();

        if (events.isEmpty) {
          throw Exception('No se encontraron eventos en el servidor');
        }

        print('✅ Descarga exitosa: ${events.length} eventos');
        return events;

      } catch (e) {
        print('❌ Intento $attempt falló: $e');

        if (attempt == maxRetries) {
          throw NetworkException('Error de conexión después de $maxRetries intentos: $e');
        }

        print('⏳ Esperando ${retryDelay.inSeconds} segundos antes del siguiente intento...');
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Error inesperado en descarga');
  }

  /// 📥 Descarga directa desde Firestore (movido de FirestoreClient)
  Future<List<Map<String, dynamic>>> _downloadFromFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos_lotes')
          .orderBy('metadata.fecha_subida', descending: true)
          .limit(10)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('📭 No hay lotes disponibles en Firestore');
        return [];
      }

      // Procesar eventos de todos los lotes descargados
      final events = _getAllEventsFromDocs(querySnapshot.docs);
      print('📦 Primera instalación: ${events.length} eventos de ${querySnapshot.docs.length} lotes');

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

  /// ⚙️ Procesamiento de datos iniciales
  Future<void> _processInitialData(List<Map<String, dynamic>> events) async {
    print('⚙️ Procesando ${events.length} eventos iniciales...');

    // Inserción masiva
    await _eventRepository.insertEvents(events);
    print('✅ Eventos insertados en SQLite');

    // Limpieza automática (eventos viejos + duplicados)
    final cleanupResults = await _eventRepository.cleanOldEvents();
    final duplicatesRemoved = await _eventRepository.removeDuplicatesByCodes();

    print('🧹 Limpieza completada:');
    print('   - Eventos normales removidos: ${cleanupResults['normalEvents']}');
    print('   - Favoritos removidos: ${cleanupResults['favoriteEvents']}');
    print('   - Duplicados removidos: $duplicatesRemoved');
    await _refreshSimpleHomeProvider();
  }

  /// ✅ Marcar primera instalación como completada
  Future<void> _markFirstInstallCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstInstallKey, true);
    print('✅ Flag de primera instalación marcado PERMANENTEMENTE');
  }

  /// 🎉 Notificar éxito de primera instalación
  Future<void> _notifySuccess(int eventsCount) async {
    await _notificationsProvider.addNotification(
      title: '🎭 ¡App lista para usar!',
      message: 'Se configuraron $eventsCount eventos culturales de Córdoba',
      type: 'first_install_complete',
    );
  }

  /// ⚠️ Notificar error de primera instalación
  Future<void> _notifyError(dynamic error) async {
    String title;
    String message;

    if (error is NetworkException) {
      title = '📡 Sin conexión a internet';
      message = 'No se pudieron descargar los eventos. La app intentará automáticamente más tarde';
    } else {
      title = '⚠️ Error de configuración';
      message = 'Error interno de la app, se reintentará en la próxima apertura';
    }

    await _notificationsProvider.addNotification(
      title: title,
      message: message,
      type: 'first_install_error',
    );
  }

  // ========== MÉTODOS DE ESTADO ==========

  /// 📊 Obtener estado actual de primera instalación
  Future<Map<String, dynamic>> getInstallationStatus() async {
    final isCompleted = !await needsFirstInstall();

    return {
      'completed': isCompleted,
      'running': _isRunning,
      'needsInstall': await needsFirstInstall(),
    };
  }

  /// 🔄 Reset para testing/debug (solo development)
  Future<void> resetFirstInstallFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstInstallKey);
    print('🔄 Flag de primera instalación reseteado para testing');
  }
  /// 🔄 Actualizar SimpleHomeProvider tras sync o primera instalación
  Future<void> _refreshSimpleHomeProvider() async {
    try {
      print('🔄 Actualizando cache de SimpleHomeProvider...');

      // Obtener instancia desde Provider.of en context global
      // Como no tenemos context aquí, usaremos el EventCacheService directamente
      final EventCacheService cacheService = EventCacheService();
      await cacheService.reloadCache();

      print('✅ Cache actualizado correctamente');
    } catch (e) {
      print('⚠️ Error actualizando cache: $e');
    }
  }
}

// ========== MODELOS DE RESULTADO ==========

/// Resultado de primera instalación
class FirstInstallResult {
  final bool success;
  final String? error;
  final int eventsDownloaded;
  final FirstInstallResultType type;

  FirstInstallResult._({
    required this.success,
    this.error,
    this.eventsDownloaded = 0,
    required this.type,
  });

  factory FirstInstallResult.success({required int eventsDownloaded}) =>
      FirstInstallResult._(
        success: true,
        eventsDownloaded: eventsDownloaded,
        type: FirstInstallResultType.success,
      );

  factory FirstInstallResult.alreadyCompleted() =>
      FirstInstallResult._(
        success: true,
        type: FirstInstallResultType.alreadyCompleted,
      );

  factory FirstInstallResult.alreadyRunning() =>
      FirstInstallResult._(
        success: false,
        error: 'Primera instalación ya en progreso',
        type: FirstInstallResultType.alreadyRunning,
      );

  factory FirstInstallResult.error(String error) =>
      FirstInstallResult._(
        success: false,
        error: error,
        type: FirstInstallResultType.error,
      );
}

enum FirstInstallResultType {
  success,
  alreadyCompleted,
  alreadyRunning,
  error
}


/// Excepción específica para errores de red
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}