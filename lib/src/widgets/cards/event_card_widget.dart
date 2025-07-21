
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/simple_home_provider.dart';
import '../../cache/cache_models.dart';
import '../../utils/dimens.dart';
import '../../utils/colors.dart';
import '../../providers/favorites_provider.dart';  // ✅ AGREGAR
import '../event_detail_modal.dart';

class EventCardWidget extends StatelessWidget {
  final EventCacheItem event;
  final SimpleHomeProvider provider;
  
  const EventCardWidget({
    super.key,
    required this.event,
    required this.provider,
  });

@override
Widget build(BuildContext context) {
  // NUEVO: Usar colores pre-calculados
  final colors = EventCardColorPalette.getOptimizedColors('normal', 'arte');
  final formattedDate = provider.formatEventDate(event.date, format: 'card');
  final categoryWithEmoji = CategoryDisplayNames.getCategoryWithEmoji(event.type);

  return GestureDetector(
    onTap: () {
      //EventDetailModal.show(context, event, provider);
    },
    child: Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingSmall,
      ),
      elevation: AppDimens.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.base,
         // gradient: LinearGradient(
          //  begin: Alignment.topLeft,
          //  end: Alignment.bottomRight,
          //  colors: [colors.base, colors.dark], // NUEVO: Pre-calculados
          //),
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.text, // NUEVO: Pre-calculado
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppDimens.paddingSmall),
              
              // Categoría con emoji
              Text(
                categoryWithEmoji,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.text.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: AppDimens.paddingSmall),
              
              // Línea divisoria
              Container(
                height: 0.5,
                color: colors.text.withOpacity(0.3),
              ),
              
              const SizedBox(height: AppDimens.paddingSmall),
              
              // Fecha + favorito
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '🗓  $formattedDate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                  ),
                  Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final isFavorite = favoritesProvider.isFavorite(event.id.toString());
                      return IconButton(
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : colors.text,
                        ),
                        onPressed: () => favoritesProvider.toggleFavorite(event.id.toString()),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 1),
              
              // Ubicación
              Row(
                children: [
                  const Text('📍', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 18,
                            color: colors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          event.district,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.text.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimens.paddingSmall),
              
              // Precio
              Text(
                '🎟  ${event.price.isNotEmpty ? event.price : 'Consultar'}',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}