
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

    return Container( // NUEVO: Container directo, elimina Card
      margin: const EdgeInsets.symmetric( // CAMBIO: Movido de Card a Container
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingSmall,
      ),
      child: GestureDetector( // CAMBIO: GestureDetector ahora dentro del Container
        onTap: () {
          //EventDetailModal.show(context, event, provider);
        },
        child: Container( // CAMBIO: Este Container ahora maneja decoración Y contenido
          decoration: BoxDecoration(
            gradient: LinearGradient( // NUEVO: Restaurado tu gradiente querido
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [event.baseColor, event.darkColor], // NUEVO: Gradiente con pre-calculados
            ),
            borderRadius: BorderRadius.circular(AppDimens.borderRadius),
            boxShadow: [ // NUEVO: Reemplaza elevation de Card
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // NUEVO: Shadow manual
                blurRadius: AppDimens.cardElevation, // NUEVO: Usa misma elevación
                offset: const Offset(0, 2), // NUEVO: Shadow hacia abajo
              ),
            ],
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
                    color: event.textColor, // NUEVO: Pre-calculado
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppDimens.paddingSmall),

                // Categoría con emoji
                Text(
                  event.categoryWithEmoji,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: event.textFaded90,
                  ),
                ),

                const SizedBox(height: AppDimens.paddingSmall),

                SizedBox(
                  height: 6,
                  width: double.infinity, // ¡AQUÍ ESTÁ LA CLAVE!
                  child: CustomPaint(
                      painter: LinePainter(event.textFaded30),
                  ),
                ),
                const SizedBox(height: AppDimens.paddingSmall),

                // Fecha + favorito
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🗓  ${event.formattedDateForCard}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: event.textColor,
                        ),
                      ),
                    ),
                    Selector<FavoritesProvider, bool>( // CAMBIO: Selector específico
                      selector: (context, favProvider) => favProvider.isFavorite(event.id.toString()), // CAMBIO: Solo escucha cambios de ESTE evento
                      builder: (context, isFavorite, child) { // CAMBIO: Solo rebuilda si cambia isFavorite de este evento
                        return IconButton(
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : event.textColor, // CAMBIO: Usa color precalculado
                          ),
                          onPressed: () { // CAMBIO: context.read para evitar dependencia del builder
                            context.read<FavoritesProvider>().toggleFavorite(event.id.toString());
                          },
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
                              color: event.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            event.district,
                            style: TextStyle(
                              fontSize: 14,
                              color: event.textFaded70,
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
                // Precio + Premium
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🎟  ${event.price.isNotEmpty ? event.price : 'Consultar'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: event.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (event.premiumEmoji.isNotEmpty) // NUEVO: Solo si hay emoji premium
                      Text(
                        event.premiumEmoji, // NUEVO: Emoji precalculado
                        style: const TextStyle(fontSize: 30),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }
}
class LinePainter extends CustomPainter {
  final Color color;

  const LinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint
    );
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) => oldDelegate.color != color;
}