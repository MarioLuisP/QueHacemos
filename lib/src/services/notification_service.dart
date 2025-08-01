import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

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

    _initialized = true;
    print('🔔 NotificationService inicializado');
  }

  /// Callback cuando usuario toca una notificación
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notificación tocada: ${response.payload}');
    // TODO: Navegar a detalle del evento si es necesario
  }

  /// Mostrar notificación inmediata
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

  /// Programar notificación para fecha específica
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

  /// Cancelar múltiples notificaciones
  static Future<void> cancelNotifications(List<int> ids) async {
    for (final id in ids) {
      await cancelNotification(id);
    }
  }

  // ========== LÓGICA ESPECÍFICA DE FAVORITOS ==========

  /// Programar los 3 recordatorios para un evento favorito
  static Future<void> scheduleFavoriteReminders({
    required String eventId,
    required Map<String, dynamic> eventDetails,
  }) async {
    try {
      final eventTitle = eventDetails['title'] ?? 'Evento sin título';
      final eventDateStr = eventDetails['date'] ?? '';

      if (eventDateStr.isEmpty) {
        print('⚠️ Evento sin fecha, no se pueden programar recordatorios');
        return;
      }

      final eventDateTime = DateTime.parse(eventDateStr);
      final now = DateTime.now();

      // IDs únicos para cada tipo de recordatorio
      final baseId = eventId.hashCode;
      final dayBeforeId = baseId + 1;
      final dayOfId = baseId + 2;
      final twoHoursId = baseId + 3;

      // 1. DÍA ANTERIOR - 20:00
      final dayBefore = eventDateTime.subtract(const Duration(days: 1));
      final dayBeforeAt8PM = DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 20, 0);

      if (dayBeforeAt8PM.isAfter(now)) {
        await scheduleNotification(
          id: dayBeforeId,
          title: '🌟 ¡Mañana tienes un evento favorito!',
          message: '$eventTitle - Prepárate para mañana',
          scheduledDate: dayBeforeAt8PM,
          payload: 'favorite_reminder_day_before:$eventId',
        );
      }

      // 2. DÍA DEL EVENTO - 11:00
      final dayOfAt11AM = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day, 11, 0);

      if (dayOfAt11AM.isAfter(now)) {
        await scheduleNotification(
          id: dayOfId,
          title: '🎭 ¡Hoy tienes un evento favorito!',
          message: '$eventTitle - No te lo pierdas',
          scheduledDate: dayOfAt11AM,
          payload: 'favorite_reminder_day_of:$eventId',
        );
      }

      // 3. DOS HORAS ANTES
      final twoHoursBefore = eventDateTime.subtract(const Duration(hours: 2));

      if (twoHoursBefore.isAfter(now)) {
        await scheduleNotification(
          id: twoHoursId,
          title: '⏰ ¡Tu evento favorito empieza pronto!',
          message: '$eventTitle en 2 horas',
          scheduledDate: twoHoursBefore,
          payload: 'favorite_reminder_two_hours:$eventId',
        );
      }

      print('✅ Recordatorios programados para evento: $eventTitle');

    } catch (e) {
      print('❌ Error programando recordatorios para evento $eventId: $e');
    }
  }

  /// Cancelar todos los recordatorios de un evento favorito
  static Future<void> cancelFavoriteReminders(String eventId) async {
    try {
      final baseId = eventId.hashCode;
      final ids = [baseId + 1, baseId + 2, baseId + 3]; // day_before, day_of, two_hours

      await cancelNotifications(ids);
      print('✅ Recordatorios cancelados para evento: $eventId');

    } catch (e) {
      print('❌ Error cancelando recordatorios para evento $eventId: $e');
    }
  }
}