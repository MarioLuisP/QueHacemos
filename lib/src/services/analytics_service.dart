//lib/src/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Trackea cuando un usuario ve el detalle de un evento
  static Future<void> trackDetailView(String spacecode) async {
    try {
      await _analytics.logEvent(
        name: 'event_detail_view',
        parameters: {
          'spacecode': spacecode,
        },
      );
      print('📊 Analytics: detail_view - $spacecode');
    } catch (e) {
      // Silencioso - no interrumpir UX
    }
  }

  /// Trackea cuando un usuario hace toggle de favorito
  static Future<void> trackFavoriteToggle(String spacecode) async {
    try {
      await _analytics.logEvent(
        name: 'event_favorite_toggle',
        parameters: {
          'spacecode': spacecode,
        },
      );
      print('📊 Analytics: favorite_toggle - $spacecode');
    } catch (e) {
      // Silencioso - no interrumpir UX
    }
  }
}