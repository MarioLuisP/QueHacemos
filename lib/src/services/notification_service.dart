import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:app_badge_plus/app_badge_plus.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

// Fix para Android 13+ - Solicitar permisos explícitamente
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }

    // Cleanup inteligente: limpiar badge si es nuevo día
    await _cleanupBadgeIfNewDay();

    _initialized = true;
    print('🔔 NotificationService inicializado');
  }

  /// Callback cuando usuario toca una notificación
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notificación tocada: ${response.payload}');
    // TODO: Navegar a detalle del evento si es necesario
  }

  /// Mostrar notificación inmediata (para campanita de favoritos)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String message,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'general',
      'Notificaciones Generales',
      channelDescription: 'Notificaciones de la app QuehaCeMos',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, message, details, payload: payload);
  }

  /// Programar notificación para fecha específica (método base)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String message,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Recordatorios de Eventos',
      channelDescription: 'Recordatorios de eventos favoritos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      message,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('⏰ Notificación programada: $title para ${scheduledDate.toString()}');
  }

  /// Cancelar notificación específica
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('❌ Notificación cancelada: $id');
  }

  // ========== NUEVO SISTEMA DE NOTIFICACIONES DIARIAS ==========

  /// Calcular horario óptimo para notificación diaria
  static DateTime calculateNotificationTime(String date, List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      // No hay eventos, usar horario base
      final targetDate = DateTime.parse(date);
      return DateTime(targetDate.year, targetDate.month, targetDate.day, 11, 0);
    }

    // Encontrar el evento más temprano
    DateTime? earliestEvent;
    for (final event in events) {
      final eventDateStr = event['date'] ?? event['startTime'];
      if (eventDateStr != null) {
        try {
          final eventDateTime = DateTime.parse(eventDateStr.toString());
          if (earliestEvent == null || eventDateTime.isBefore(earliestEvent)) {
            earliestEvent = eventDateTime;
          }
        } catch (e) {
          print('❌ Error parseando fecha del evento: $e');
        }
      }
    }

    if (earliestEvent == null) {
      // No se pudo parsear ningún evento, usar horario base
      final targetDate = DateTime.parse(date);
      return DateTime(targetDate.year, targetDate.month, targetDate.day, 11, 0);
    }

    final targetDate = DateTime.parse(date);

    // NUEVA LÓGICA: Si evento más temprano es ≥ 12:00, notificar a las 11:00
    if (earliestEvent.hour >= 12) {
      return DateTime(targetDate.year, targetDate.month, targetDate.day, 11, 0);
    }

    // Si evento es < 12:00, calcular 1 hora antes con límites
    final oneHourBefore = earliestEvent.subtract(const Duration(hours: 1));
    final minTime = DateTime(targetDate.year, targetDate.month, targetDate.day, 6, 0);
    final maxTime = DateTime(targetDate.year, targetDate.month, targetDate.day, 11, 0);

    if (oneHourBefore.isBefore(minTime)) {
      return minTime; // 6:00 AM mínimo
    } else if (oneHourBefore.isAfter(maxTime)) {
      return maxTime; // 11:00 AM máximo
    } else {
      return oneHourBefore; // Horario calculado
    }
  }

  /// Generar mensaje inteligente para notificación diaria
  static String generateDailyMessage(List<Map<String, dynamic>> events) {
    if (events.isEmpty) return '';

    // Ordenar eventos por hora
    final sortedEvents = List<Map<String, dynamic>>.from(events);
    sortedEvents.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['date'] ?? a['startTime'].toString());
        final dateB = DateTime.parse(b['date'] ?? b['startTime'].toString());
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    final firstEvent = sortedEvents.first;
    final eventTitle = firstEvent['title'] ?? 'Evento';
    final eventTime = _formatEventTime(firstEvent);

    if (sortedEvents.length == 1) {
      return "Hoy: $eventTitle $eventTime";
    } else if (sortedEvents.length == 2) {
      final secondEvent = sortedEvents[1];
      final secondTitle = secondEvent['title'] ?? 'Evento';
      final secondTime = _formatEventTime(secondEvent);
      return "Hoy tienes 2: $eventTitle $eventTime, $secondTitle $secondTime";
    } else {
      final remainingCount = sortedEvents.length - 2;
      final secondEvent = sortedEvents[1];
      final secondTitle = secondEvent['title'] ?? 'Evento';
      final secondTime = _formatEventTime(secondEvent);
      return "Hoy tienes ${sortedEvents.length}: $eventTitle $eventTime, $secondTitle $secondTime + $remainingCount más";
    }
  }

  /// Formatear hora del evento para el mensaje
  static String _formatEventTime(Map<String, dynamic> event) {
    try {
      final dateStr = event['date'] ?? event['startTime'];
      if (dateStr == null) return '';

      final dateTime = DateTime.parse(dateStr.toString());
      final hour = dateTime.hour;
      final minute = dateTime.minute;

      if (minute == 0) {
        return "${hour}hs";
      } else {
        return "${hour}:${minute.toString().padLeft(2, '0')}hs";
      }
    } catch (e) {
      return '';
    }
  }

  /// Programar notificación diaria para una fecha específica
  static Future<void> scheduleDailyNotification(String date, List<Map<String, dynamic>> events) async {
    try {
      if (events.isEmpty) {
        print('📅 No hay eventos para $date, no se programa notificación');
        return;
      }

      // Calcular horario óptimo
      final notificationTime = calculateNotificationTime(date, events);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 11, 0);

      // Verificar si debe ser notificación inmediata (eventos ≥12:00)
      if (notificationTime.hour == 11 && notificationTime.minute == 0) {
        // Notificación inmediata para eventos ≥12:00
        final notificationId = "daily_$date".hashCode;
        final message = generateDailyMessage(events);

        await showNotification(
          id: notificationId,
          title: '🎭 Eventos de hoy',
          message: message,
          payload: 'daily_reminder:$date',
        );

        print('✅ Notificación inmediata enviada para $date (eventos ≥12:00)');
        return;
      }

      // Solo programar si es en el futuro (eventos <12:00)
      if (notificationTime.isBefore(now)) {
        print('⏰ Horario de notificación es pasado ($notificationTime), no se programa');
        return;
      }

      // Generar ID único para la fecha
      final notificationId = "daily_$date".hashCode;

      // Generar mensaje
      final message = generateDailyMessage(events);

      // Programar notificación
      await scheduleNotification(
        id: notificationId,
        title: '🎭 Eventos de hoy',
        message: message,
        scheduledDate: notificationTime,
        payload: 'daily_reminder:$date',
      );

      print('✅ Notificación programada para $date a las ${notificationTime.hour}:${notificationTime.minute.toString().padLeft(2, '0')} (eventos <12:00)');

    } catch (e) {
      print('❌ Error programando notificación diaria para $date: $e');
    }
  }

  /// Cancelar notificación diaria para una fecha específica
  static Future<void> cancelDailyNotification(String date) async {
    try {
      final notificationId = "daily_$date".hashCode;
      await cancelNotification(notificationId);
      print('✅ Notificación diaria cancelada para $date');
    } catch (e) {
      print('❌ Error cancelando notificación diaria para $date: $e');
    }
  }

  // ========== GESTIÓN DE BADGE ==========

  /// Establecer badge rojo (sin número)
  static Future<void> setBadge() async {
    try {
      // Cleanup preventivo: verificar si debe limpiarse antes de establecer
      await _cleanupBadgeIfNewDay();

      await AppBadgePlus.updateBadge(1); // 1 = badge rojo visible
      await _saveBadgeTimestamp(); // Guardar cuándo se estableció
      print('🔴 Badge establecido');
    } catch (e) {
      print('❌ Error estableciendo badge: $e');
    }
  }

  /// Limpiar badge
  static Future<void> clearBadge() async {
    try {
      await AppBadgePlus.updateBadge(0); // 0 = sin badge
      await _clearBadgeTimestamp(); // Limpiar timestamp
      print('⚪ Badge limpiado');
    } catch (e) {
      print('❌ Error limpiando badge: $e');
    }
  }

  /// Limpiar badge si es un nuevo día (sin background tasks)
  static Future<void> _cleanupBadgeIfNewDay() async {
    try {
      // TODO: Implementar lógica de verificación de nuevo día
      // Por ahora, cleanup simple en startup
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Si es startup del día, limpiar badge
      print('🧹 Cleanup badge para nuevo día: ${today.toString().split(' ')[0]}');
      await AppBadgePlus.updateBadge(0);

    } catch (e) {
      print('❌ Error en cleanup badge: $e');
    }
  }

  /// Guardar timestamp cuando se estableció badge
  static Future<void> _saveBadgeTimestamp() async {
    // TODO: Implementar con SharedPreferences si es necesario
    print('💾 Badge timestamp guardado');
  }

  /// Limpiar timestamp de badge
  static Future<void> _clearBadgeTimestamp() async {
    // TODO: Implementar con SharedPreferences si es necesario
    print('🗑️ Badge timestamp limpiado');
  }



  // ========== MÉTODOS OBSOLETOS (MANTENER TEMPORALMENTE PARA COMPATIBILITY) ==========

  /// Programar los 3 recordatorios para un evento favorito
  /// @deprecated - Usar scheduleDailyNotification en su lugar
  static Future<void> scheduleFavoriteReminders({
    required String eventId,
    required Map<String, dynamic> eventDetails,
  }) async {
    print('⚠️ scheduleFavoriteReminders está deprecated - usar scheduleDailyNotification');
    // Método mantenido para evitar breaking changes durante migración
    // TODO: Remover después de migración completa
  }

  /// Cancelar todos los recordatorios de un evento favorito
  /// @deprecated - Usar cancelDailyNotification en su lugar
  static Future<void> cancelFavoriteReminders(String eventId) async {
    print('⚠️ cancelFavoriteReminders está deprecated - usar cancelDailyNotification');
    // Método mantenido para evitar breaking changes durante migración
    // TODO: Remover después de migración completa
  }
}