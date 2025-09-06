//lib/src/services/weekly_prompt_service.dart

import '../models/user_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/notification_config_service.dart';

class WeeklyPromptService {
  // Evalúa si debe mostrar prompt de login
  static Future<bool> shouldShowLoginPrompt(AuthProvider authProvider) async {
    if (authProvider.isLoggedIn) return false;

    final data = await UserPreferences.getLoginPromptData();
    final parts = data.split('_');
    final lastPrompt = int.parse(parts[0]);
    final declineCount = int.parse(parts[1]);

    final now = DateTime.now().millisecondsSinceEpoch;
    final daysPassed = (now - lastPrompt) / (1000 * 60 * 60 * 24);

    final requiredDays = _getRequiredDays(declineCount);
    return daysPassed >= requiredDays;
  }

  // Evalúa si debe mostrar prompt de notificaciones
  static Future<bool> shouldShowNotificationPrompt() async {
    final isConfigured = await NotificationConfigurationService.isAlreadyConfigured();
    if (isConfigured) return false;

    final data = await UserPreferences.getNotificationPromptData();
    final parts = data.split('_');
    final lastPrompt = int.parse(parts[0]);
    final declineCount = int.parse(parts[1]);

    final now = DateTime.now().millisecondsSinceEpoch;
    final daysPassed = (now - lastPrompt) / (1000 * 60 * 60 * 24);

    final requiredDays = _getRequiredDays(declineCount);
    return daysPassed >= requiredDays;
  }

  // Registra que el usuario rechazó el prompt de login
  static Future<void> recordLoginDecline() async {
    final data = await UserPreferences.getLoginPromptData();
    final parts = data.split('_');
    final declineCount = int.parse(parts[1]) + 1;
    final now = DateTime.now().millisecondsSinceEpoch;

    await UserPreferences.setLoginPromptData('${now}_$declineCount');
  }

  // Registra que el usuario rechazó el prompt de notificaciones
  static Future<void> recordNotificationDecline() async {
    final data = await UserPreferences.getNotificationPromptData();
    final parts = data.split('_');
    final declineCount = int.parse(parts[1]) + 1;
    final now = DateTime.now().millisecondsSinceEpoch;

    await UserPreferences.setNotificationPromptData('${now}_$declineCount');
  }

  // Calcula días requeridos según rechazos: 7, 7, 30, nunca más
  static int _getRequiredDays(int declineCount) {
    switch (declineCount) {
      case 0: return 7;   // Primera vez
      case 1: return 7;   // Segunda vez
      case 2: return 7;
      case 3: return 30;  // Tercera vez
      case 4: return 30;  // Cuarta vez
      default: return 999999; // No preguntar más
    }
  }
}