import 'package:flutter/foundation.dart';

class FavoritesProvider with ChangeNotifier {
  Set<String> _favoriteIds = {};

  bool favorite(String eventId) => _favoriteIds.contains(eventId);

  void toggleFavorite(String eventId) {
    if (_favoriteIds.contains(eventId)) {
      _favoriteIds.remove(eventId);
      print('💔 Favorito removido: $eventId');
    } else {
      _favoriteIds.add(eventId);
      print('❤️ Favorito agregado: $eventId');
    }

    notifyListeners();
  }

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
}