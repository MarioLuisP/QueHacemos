
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/simple_home_provider.dart';
import '../../cache/cache_models.dart';
import '../../utils/dimens.dart';
import '../../data/repositories/event_repository.dart';  // NUEVO: Import para acceso directo a DB
import '../../providers/favorites_provider.dart';  // ✅ AGREGAR
import 'event_detail_modal.dart';  // CAMBIO: Misma carpeta widgets/cards/

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

    return ConstrainedBox( // NUEVO: Wrapper para altura fija
        constraints: const BoxConstraints.tightFor(height: 237.0), // NUEVO: Altura fija 237px
        child: Container( // CAMBIO: Ahora es child del ConstrainedBox
      margin: const EdgeInsets.symmetric( // CAMBIO: Movido de Card a Container
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingSmall,
      ),
          child: GestureDetector(
            onTap: () async {
              final repository = EventRepository();                             // NUEVO: Instancia directa
              final fullEvent = await repository.getEventById(event.id);        // NUEVO: Query directo a SQLite
              if (fullEvent != null) {
                EventDetailModal.show(context, event, fullEvent);               // CAMBIO: cache + full (ambos!)
              }
            },
        child: Container( // CAMBIO: Este Container ahora maneja decoración Y contenido
          decoration: BoxDecoration(
            gradient: LinearGradient( // NUEVO: Restaurado tu gradiente querido
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [event.baseColor, event.darkColor],
              stops: [0.0, 0.9],// NUEVO: Gradiente con pre-calculados
            ),
            borderRadius: BorderRadius.circular(AppDimens.borderRadius),
            boxShadow: [ // NUEVO: Reemplaza elevation de Card
              BoxShadow(
                color: Colors.black.withAlpha(25), // NUEVO: Shadow manual
                blurRadius: AppDimens.cardElevation, // NUEVO: Usa misma elevación
                offset: const Offset(0, 6), // NUEVO: Shadow hacia abajo
              ),
            ],
          ),


          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,  // lados
              vertical: 9,    // arriba/abajo
            ),
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
                    fontSize: 17,
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
                //const SizedBox(height: AppDimens.paddingSmall),

                // Fecha + favorito
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🗓  ${event.formattedDateForCard}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: event.textColor,
                        ),
                      ),
                    ),
                    Selector<FavoritesProvider, bool>(
                      selector: (context, favProvider) => favProvider.isFavorite(event.id.toString()),
                      builder: (context, isFavorite, child) {
                        return IconButton(
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : event.textColor,
                          ),
                          onPressed: () {
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
                          ),
                          Text(
                            event.district,
                            style: TextStyle(
                              fontSize: 16,
                              color: event.textFaded70,
                            ),
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
                        '🎫  ${event.price.isNotEmpty ? event.price : 'Consultar'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: event.textColor,
                        ),
                      ),
                    ),
                    if (event.premiumEmoji.isNotEmpty) // NUEVO: Solo si hay emoji premium
                      Text(
                        event.premiumEmoji, // NUEVO: Emoji precalculado
                        style: const TextStyle(fontSize: 20),
                      ),
                  ],
                ),
              ],
            ),
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