// lib/src/services/first_install_service.dart

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../sync/firestore_client.dart';
import '../data/repositories/event_repository.dart';
import '../providers/notifications_provider.dart';

/// 🚀 SERVICIO AUTÓNOMO DE PRIMERA INSTALACIÓN
/// Responsabilidad única: Setup técnico completo de la app
/// Ejecuta UNA SOLA VEZ en la vida de la app
class FirstInstallService {
  static final FirstInstallService _instance = FirstInstallService._internal();
  factory FirstInstallService() => _instance;
  FirstInstallService._internal();

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

  /// 📥 Descarga de contenido inicial con reintentos
  Future<List<Map<String, dynamic>>> _downloadInitialContent() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('📥 Intento $attempt/$maxRetries: Descargando 10 lotes iniciales...');

        final events = await _firestoreClient.downloadBatch(isMultipleLots: true);

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