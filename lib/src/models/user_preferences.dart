import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme') ?? 'normal';
  }

  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
  }

  static Future<Set<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('categories') ?? []).toSet();
  }

  static Future<void> setCategories(Set<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categories', categories.toList());
  }

  static Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('favorite_ids') ?? []).toSet();
  }

  static Future<void> setFavoriteIds(Set<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_ids', favoriteIds.toList());
  }

  static Future<Set<String>> getActiveFilterCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('activeFilterCategories') ?? []).toSet();
  }

  static Future<void> setActiveFilterCategories(Set<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('activeFilterCategories', categories.toList());
  }
  static Future<int> getEventCleanupDays() async {          // NUEVO: obtener días eventos
    final prefs = await SharedPreferences.getInstance();    // NUEVO: instancia SharedPrefs
    return prefs.getInt('event_cleanup_days') ?? 3;         // NUEVO: default 3 días
  }

  static Future<void> setEventCleanupDays(int days) async { // NUEVO: guardar días eventos
    final prefs = await SharedPreferences.getInstance();    // NUEVO: instancia SharedPrefs
    await prefs.setInt('event_cleanup_days', days);         // NUEVO: guardar valor
  }

  static Future<int> getFavoriteCleanupDays() async {       // NUEVO: obtener días favoritos
    final prefs = await SharedPreferences.getInstance();    // NUEVO: instancia SharedPrefs
    return prefs.getInt('favorite_cleanup_days') ?? 7;      // NUEVO: default 7 días
  }

  static Future<void> setFavoriteCleanupDays(int days) async { // NUEVO: guardar días favoritos
    final prefs = await SharedPreferences.getInstance();       // NUEVO: instancia SharedPrefs
    await prefs.setInt('favorite_cleanup_days', days);         // NUEVO: guardar valor
  }
  static Future<bool> getNotificationsReady() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_ready') ?? false;
  }

  static Future<void> setNotificationsReady(bool ready) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_ready', ready);
  }
// Prompt management for weekly reminders
  static Future<String> getLoginPromptData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('login_prompt_data') ?? '0_0';
  }

  static Future<void> setLoginPromptData(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('login_prompt_data', data);
  }

  static Future<String> getNotificationPromptData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('notification_prompt_data') ?? '0_0';
  }

  static Future<void> setNotificationPromptData(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_prompt_data', data);
  }
}