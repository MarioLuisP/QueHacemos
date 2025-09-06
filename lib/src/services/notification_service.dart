import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:app_badge_plus/app_badge_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static AndroidFlutterLocalNotificationsPlugin? resolveAndroid() {
    if (Platform.isAndroid) {
      return _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    }
    return null;
  }
  static bool _initialized = false;
  static Completer<void>? _initCompleter;
  static bool get isInitialized => _initialized;
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final success = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (success == true) {
        await _cleanupBadgeIfNewDay();
        _initialized = true;
        _initCompleter?.complete();
        return true;
      } else {
        _initialized = false;
        return false;
      }
    } catch (e) {
      _initialized = false;
      _initCompleter?.completeError(e);
      return false;
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {}

  static Future<void> showNotification({
    required int id,
    required String title,
    required String message,
    String? payload,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'general',
      'Notificaciones Generales',
      channelDescription: 'Notificaciones de la app QuehaCeMos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: Colors.orange,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, message, details, payload: payload);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String message,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Recordatorios de Eventos',
      channelDescription: 'Recordatorios de eventos favoritos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: Colors.orange,
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
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static DateTime calculateNotificationTime(String date, List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      final targetDate = DateTime.parse(date);
      return DateTime(targetDate.year, targetDate.month, targetDate.day, 11, 0);
    }

    DateTime? earliestEvent;
    for (final event in events) {
      final eventDateStr = event['date'] ?? event['startTime'];
      if (eventDateStr != null) {
        try {
          final eventDateTime = DateTime.parse(eventDateStr.toString());
          if (earliestEvent == null || eventDateTime.isBefore(earliestEvent)) {
            earliestEvent = eventDateTime;
          }
        } catch (e) {}
      }
    }

    if (earliestEvent == null) {
      final targetDate = DateTime.parse(date);
      return DateTime(targetDate.year, targetDate.month, targetDate.day, 11, 0);
    }

    final targetDate = DateTime.parse(date);

    if (earliestEvent.hour >= 12) {
      return DateTime(targetDate.year, targetDate.month, targetDate.day, 11, 0);
    }

    final oneHourBefore = earliestEvent.subtract(const Duration(hours: 1));
    final minTime = DateTime(targetDate.year, targetDate.month, targetDate.day, 6, 0);
    final maxTime = DateTime(targetDate.year, targetDate.month, targetDate.day, 11, 0);

    if (oneHourBefore.isBefore(minTime)) {
      return minTime;
    } else if (oneHourBefore.isAfter(maxTime)) {
      return maxTime;
    } else {
      return oneHourBefore;
    }
  }

  static String generateDailyMessage(List<Map<String, dynamic>> events) {
    if (events.isEmpty) return '';

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
      return "✨ No te lo pierdas\n$eventTitle ⏰ $eventTime";
    } else if (sortedEvents.length == 2) {
      final secondEvent = sortedEvents[1];
      final secondTitle = secondEvent['title'] ?? 'Evento';
      final secondTime = _formatEventTime(secondEvent);
      return "🥂 Doble planazo\n✨ $eventTitle ⏰ $eventTime\n✨ $secondTitle ⏰ $secondTime";
    } else {
      final remainingCount = sortedEvents.length - 2;
      final secondEvent = sortedEvents[1];
      final secondTitle = secondEvent['title'] ?? 'Evento';
      final secondTime = _formatEventTime(secondEvent);
      return "🚀 Maratón cultural\n✨ $eventTitle ⏰ $eventTime\n✨ $secondTitle ⏰ $secondTime + $remainingCount más";
    }
  }

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
  static Future<void> waitForInitialization() {
    if (_initialized) return Future.value();

    _initCompleter ??= Completer<void>();
    return _initCompleter!.future;
  }

  static Future<void> scheduleDailyNotification(String date, List<Map<String, dynamic>> events) async {
    try {
      if (events.isEmpty) return;

      final now = DateTime.now();
      if (now.hour >= 11) {
        final notificationId = "daily_$date".hashCode;
        final message = generateDailyMessage(events);

        await showNotification(
          id: notificationId,
          title: '❤️ Favoritos de hoy ⭐',
          message: message,
          payload: 'daily_reminder:$date',
        );
        return;
      }

      final notificationTime = calculateNotificationTime(date, events);

      if (notificationTime.isBefore(now)) return;

      final notificationId = "daily_$date".hashCode;
      final message = generateDailyMessage(events);

      await scheduleNotification(
        id: notificationId,
        title: '❤️ Favoritos de hoy ⭐',
        message: message,
        scheduledDate: notificationTime,
        payload: 'daily_reminder:$date',
      );
    } catch (e) {}
  }

  static Future<void> cancelDailyNotification(String date) async {
    try {
      final notificationId = "daily_$date".hashCode;
      await cancelNotification(notificationId);
    } catch (e) {}
  }

  static Future<void> setBadge() async {
    try {
      await _cleanupBadgeIfNewDay();
      await AppBadgePlus.updateBadge(1);
      await _saveBadgeTimestamp();
    } catch (e) {}
  }

  static Future<void> clearBadge() async {
    try {
      await AppBadgePlus.updateBadge(0);
      await _clearBadgeTimestamp();
    } catch (e) {}
  }

  static Future<void> _cleanupBadgeIfNewDay() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await AppBadgePlus.updateBadge(0);
    } catch (e) {}
  }

  static Future<void> _saveBadgeTimestamp() async {}

  static Future<void> _clearBadgeTimestamp() async {}
}
