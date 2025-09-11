// lib/src/services/first_install_service.dart

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../sync/firestore_client.dart';
import '../data/repositories/event_repository.dart';
import '../providers/notifications_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../cache/event_cache_service.dart';
import '../sync/sync_service.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_preferences.dart';

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

      // 3. Descarga con reintentos (ahora retorna documentos completos)
      final completeBatches = await _downloadInitialContent();

      // 4. Procesamiento de datos (ahora secuencial por lote)
      await _processInitialData(completeBatches);

      // 5. Finalización exitosa
      await _markFirstInstallCompleted();
      await _setInitialSyncTimestamp(); // ← MOVIDO AQUÍ

      // Contar total de eventos para notificación
      final totalEvents = completeBatches.fold<int>(0, (sum, batch) {
        final eventos = (batch['eventos'] as List<dynamic>?) ?? [];
        return sum + eventos.length;
      });

      await _notifySuccess(totalEvents);

      print('🎉 Primera instalación completada exitosamente');
      return FirstInstallResult.success(eventsDownloaded: totalEvents);

    } catch (e) {
      print('❌ Error en primera instalación: $e');
      await _notifyError(e);
      return FirstInstallResult.error(e.toString());
    } finally {
      _isRunning = false;
    }
  }

  /// 📅 Marcar sync como recién hecho (evitar recovery inmediato)
  Future<void> _setInitialSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_timestamp', DateTime.now().toIso8601String());
    print('⏰ Timestamp de sync inicial seteado');
  }
  // ========== MÉTODOS INTERNOS ==========

  /// 🔧 Preparación técnica inicial
  Future<void> _prepareTechnicalSetup() async {
    print('🔧 Preparando setup técnico...');

    // Inicializar base de datos (auto-creación de tablas)
    await _eventRepository.getTotalEvents(); // Trigger database creation
// Inicializar OneSignal para Android <13 (permisos automáticos)
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt < 33) {
        print('📱 Android <13 detectado - inicializando OneSignal...');
        try {
          OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!);

          // Obtener y mostrar el token
          final userId = OneSignal.User.pushSubscription.id;
          final token = OneSignal.User.pushSubscription.token;
          await UserPreferences.setOneSignalInitialized(true);
          await UserPreferences.setNotificationsReady(true);
          print('✅ OneSignal inicializado en primera instalación');
        } catch (e) {
          print('⚠️ Error inicializando OneSignal: $e');
        }
      }
    }


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

        print('✅ Descarga exitosa: ${events.length} lotes');
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

  /// 📥 Descarga directa desde Firestore (retorna documentos completos)
  Future<List<Map<String, dynamic>>> _downloadFromFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos_lotes')
          .orderBy('metadata.fecha_subida', descending: true)
          .limit(10)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('🔭 No hay lotes disponibles en Firestore');
        return [];
      }

      // Retornar documentos completos con metadata + eventos
      final completeBatches = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      print('📦 Primera instalación: ${completeBatches.length} lotes descargados');

      // Actualizar versión del lote más reciente (como antes)
      final newBatchVersion = completeBatches.first['metadata']?['nombre_lote'] as String? ?? 'multiple';

      // Contar total de eventos de todos los lotes
      final totalEvents = completeBatches.fold<int>(0, (sum, batch) {
        final eventos = (batch['eventos'] as List<dynamic>?) ?? [];
        return sum + eventos.length;
      });

      await _eventRepository.updateSyncInfo(
        batchVersion: newBatchVersion,
        totalEvents: totalEvents,
      );

      return completeBatches;

    } catch (e) {
      print('❌ Error descargando de Firestore: $e');
      rethrow;
    }
  }

  /// ⚙️ Procesamiento de datos iniciales (secuencial por lote)
  Future<void> _processInitialData(List<Map<String, dynamic>> completeBatches) async {
    if (completeBatches.isEmpty) {
      print('⚙️ No hay lotes para procesar');
      return;
    }

    // Ordenar lotes por fecha ascendente (del más antiguo al más nuevo)
    completeBatches.sort((a, b) {
      final fechaA = a['metadata']?['fecha_subida'] as String? ?? '';
      final fechaB = b['metadata']?['fecha_subida'] as String? ?? '';
      return fechaA.compareTo(fechaB);
    });

    print('⚙️ Procesando ${completeBatches.length} lotes en orden cronológico...');

    int totalEventosInsertados = 0;
    int totalDuplicadosRemovidos = 0;
    int totalEventosLimpiados = 0;
    int totalFavoritosLimpiados = 0;

    // Procesar cada lote secuencialmente (simulando comportamiento diario)
    for (int i = 0; i < completeBatches.length; i++) {
      final batch = completeBatches[i];
      final metadata = batch['metadata'] as Map<String, dynamic>?;
      final eventos = (batch['eventos'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [];

      final nombreLote = metadata?['nombre_lote'] ?? 'lote_${i + 1}';
      final fechaSubida = metadata?['fecha_subida'] ?? 'unknown';

      print('📦 Procesando lote ${i + 1}/${completeBatches.length}: $nombreLote');
      print('   📅 Fecha: $fechaSubida');
      print('   📊 Eventos: ${eventos.length}');

      if (eventos.isEmpty) {
        print('   ⚠️ Lote vacío, saltando...');
        continue;
      }

      // 1. Insertar eventos del lote actual
      await _eventRepository.insertEvents(eventos);
      totalEventosInsertados += eventos.length;
      print('   ✅ Eventos insertados: ${eventos.length}');

      // 2. Remover duplicados (igual que sync diario)
      final duplicadosRemovidos = await _eventRepository.removeDuplicatesByCodes();
      totalDuplicadosRemovidos += duplicadosRemovidos;
      if (duplicadosRemovidos > 0) {
        print('   🔄 Duplicados removidos: $duplicadosRemovidos');
      }

      // 3. Limpiar eventos viejos (igual que sync diario)
      final cleanupResults = await _eventRepository.cleanOldEvents();
      final eventosLimpiados = cleanupResults['normalEvents'] ?? 0;
      final favoritosLimpiados = cleanupResults['favoriteEvents'] ?? 0;

      totalEventosLimpiados += eventosLimpiados;
      totalFavoritosLimpiados += favoritosLimpiados;

      if (eventosLimpiados > 0 || favoritosLimpiados > 0) {
        print('   🧹 Limpieza: $eventosLimpiados eventos, $favoritosLimpiados favoritos');
      }

      print('   ✅ Lote $nombreLote procesado completamente\n');
    }

    // Resumen final
    print('🎯 Procesamiento secuencial completado:');
    print('   📊 Total eventos insertados: $totalEventosInsertados');
    print('   🔄 Total duplicados removidos: $totalDuplicadosRemovidos');
    print('   🧹 Total eventos limpiados: $totalEventosLimpiados');
    print('   ❤️ Total favoritos limpiados: $totalFavoritosLimpiados');

    // Actualizar cache
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