class NotificationsProvider {
  static final NotificationsProvider _instance = NotificationsProvider._internal();
  factory NotificationsProvider() => _instance;
  NotificationsProvider._internal();

  static NotificationsProvider get instance => _instance;

  void addNotification({
    required String title,
    required String message,
    required String type,
    required String icon,
  }) {
    print('📱 Mock notification: $title - $message');
  }
}