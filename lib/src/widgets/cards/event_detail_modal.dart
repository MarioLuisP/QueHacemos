/// Modal expandible para mostrar detalle del evento.
library;
import 'package:url_launcher/url_launcher.dart';                // NUEVO: Para links
import 'package:share_plus/share_plus.dart';                    // NUEVO: Para compartir
import 'package:cached_network_image/cached_network_image.dart'; // NUEVO: Para imágenes
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import '../../cache/cache_models.dart';                               // NUEVO: Para EventCacheItem

class EventDetailModal {
  static void show(
      BuildContext context,
      EventCacheItem cacheEvent,                                       // NUEVO: Para colores pre-calculados
      Map<String, dynamic> fullEvent,                                  // NUEVO: Para datos completos SQLite
      ) {
    // CAMBIO: String → dynamic
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cardColor = cacheEvent.baseColor;                        // NUEVO: Color pre-calculado del cache
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Color.lerp(cardColor, Colors.white, 0.7)!,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: EventDetailContent(
                cacheEvent: cacheEvent,                                          // NUEVO: Cache con colores
                fullEvent: fullEvent,                                            // NUEVO: Datos completos SQLite
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }
}

class EventDetailContent extends StatefulWidget {
  final EventCacheItem cacheEvent;                                 // NUEVO: Cache con colores
  final Map<String, dynamic> fullEvent;                            // NUEVO: Datos completos SQLite
  final ScrollController scrollController;

  const EventDetailContent({
    super.key,
    required this.cacheEvent,                                      // NUEVO: Cache
    required this.fullEvent,                                       // NUEVO: Full data
    required this.scrollController,
  });

  @override
  State<EventDetailContent> createState() => _EventDetailContentState();
}

class _EventDetailContentState extends State<EventDetailContent> {
  bool _isDescriptionExpanded = false;

  // Variables memoizadas (calculadas una sola vez)
// Variables memoizadas (pre-calculadas del cache)               // CAMBIO: Comentario actualizado
  late Color cardColor;
  late Color darkColor;                                            // CAMBIO: Renombrado para consistencia
  late String truncatedDescription;

  // Variables dinámicas del JSON
  String get _imageUrl => widget.fullEvent['imageUrl'] ?? '';        // CAMBIO: fullEvent en lugar de event
  String get _description => widget.fullEvent['description'] ?? '';  // CAMBIO: fullEvent + null safety
  String get _address => widget.fullEvent['address'] ?? '';          // CAMBIO: fullEvent + null safety
  String get _district => widget.fullEvent['district'] ?? '';        // CAMBIO: fullEvent + null safety
  String get _websiteUrl => widget.fullEvent['websiteUrl'] ?? '';    // CAMBIO: fullEvent + null safety
  double get _lat => (widget.fullEvent['lat'] as num?)?.toDouble() ?? 0.0;  // CAMBIO: fullEvent + null safety
  double get _lng => (widget.fullEvent['lng'] as num?)?.toDouble() ?? 0.0;  // CAMBIO: fullEvent + null safety

  @override
  void initState() {
    super.initState();
    // NUEVO: Usar colores pre-calculados del cache
    cardColor = widget.cacheEvent.baseColor;                        // NUEVO: Color directo del cache
    darkColor = widget.cacheEvent.darkColor;     // CORREGIR: usar darkColor consistente
    // Pre-calculamos la descripción truncada
    const maxLength = 150;
    truncatedDescription =
    _description.length > maxLength
        ? '${_description.substring(0, maxLength)}...'
        : _description;
  }
  Color _darkenColor(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
// NUEVO: Método local para formatear fechas (reemplaza viewModel.formatEventDate)
  String _formatEventDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      final month = months[date.month] ?? 'mes';
      final timeString = (date.hour != 0 || date.minute != 0)
          ? " - ${date.hour}:${date.minute.toString().padLeft(2, '0')} hs"
          : "";
      return "${date.day} $month$timeString";
    } catch (e) {
      return dateString;
    }
  }
  //desde aca
  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_lat,$_lng',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback si no puede abrir
      print('Error opening maps: $e');
    }
  }

  Future<void> _openUber() async {
    final uri = Uri.parse(
      'uber://?action=setPickup&pickup=my_location&dropoff[latitude]=$_lat&dropoff[longitude]=$_lng&dropoff[nickname]=${widget.fullEvent['title']}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback a URL web de Uber
      final webUri = Uri.parse(
        'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[latitude]=$_lat&dropoff[longitude]=$_lng',
      );
      await launchUrl(webUri);
    }
  }
  Future<void> _shareEvent() async {
    final formattedDate = _formatEventDate(widget.fullEvent['date']!);         // NUEVO: Método local
    final message =
        'Te comparto este evento que vi en la app QuehaCeMos Cba:\n\n'
        '📌 ${widget.fullEvent['title']}\n'                                    // CAMBIO: fullEvent
        '🗓 $formattedDate\n'
        '📍 ${widget.fullEvent['location']}\n\n'                               // CAMBIO: fullEvent
        '¡No te lo pierdas!\n'
        '¡📲 Descargá la app desde playstore!';

    try {
      Share.share(message); // esto abre el menú de compartir del sistema
    } catch (e) {
      print('Error sharing: $e');
    }
  }

  Future<void> _openWebsite() async {
    try {
      final uri = Uri.parse(_websiteUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening website: $e');
    }
  }

  void _openImageFullscreen(BuildContext context) {
    if (_imageUrl == null || _imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder:
          (context) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: _imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder:
                        (context, url) =>
                            Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) =>
                            Icon(Icons.error, color: Colors.white70, size: 64),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle indicator
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image con botón de favorito
                Stack(
                  children: [
                    //*********************** */
                    Container(
                      height: 250,
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cardColor, darkColor],              // CORREGIR: usar darkColor
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () => _openImageFullscreen(context),
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment(
                              0.0,
                              -0.4,
                            ), // Centra el recorte entre 15% y 70%
                            heightFactor:
                                0.55, // Muestra el 55% de la altura (70% - 15%)
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: _imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorWidget:
                                    (context, url, error) => Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [cardColor, darkColor],              // CORREGIR: usar darkColor
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.event,
                                          size: 64,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

// Botón de favorito*******************
                    Positioned(
                      top: 24,
                      right: 24,
                      child: Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, child) {
                          final isFavorite = favoritesProvider.isFavorite(
                            widget.fullEvent['id']!.toString(),                         // CAMBIO: fullEvent
                          );
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(77),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                                size: 28,
                              ),
                              onPressed:
                                  () => favoritesProvider.toggleFavorite(
                                widget.fullEvent['id']!.toString(),                  // CAMBIO: fullEvent
                              ),
                            ),
                          );
                        },
                      ),
                    ),


                  ],
                ),

                // Información principal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        widget.fullEvent['title']!,                                       // CAMBIO: fullEvent
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Categoría
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardColor.withAlpha(128)),
                        ),
                        child: Text(
                          widget.cacheEvent.categoryWithEmoji,                              // NUEVO: Pre-calculado del cache
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Descripción
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surface, // NUEVO: Respeta theme
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDescriptionExpanded
                                  ? _description
                                  : truncatedDescription,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap:
                                  () => setState(
                                    () =>
                                        _isDescriptionExpanded =
                                            !_isDescriptionExpanded,
                                  ),
                              child: Text(
                                _isDescriptionExpanded
                                    ? 'Ver menos'
                                    : 'Ver más...',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Información del evento
                      _buildInfoSection(context),

                      const SizedBox(height: 24),

                      // Botones de acción
                      _buildActionButtons(context),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final formattedDate = _formatEventDate(widget.fullEvent['date']!);   // CAMBIO: método local + fullEvent

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // NUEVO: Respeta theme
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ), // NUEVO: Border temático
      ),
      child: Column(
        children: [
          _buildInfoRow(context, '🗓 ', 'Fecha y Hora', formattedDate),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📍', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ubicación'),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.fullEvent['location'] ?? 'Sin ubicación',        // CAMBIO: fullEvent
                          style: TextStyle(
                            fontSize: 16,
                            color:
                            Theme.of(
                              context,
                            ).colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: '\n${widget.fullEvent['district']}',                   // CAMBIO: fullEvent
                          style: TextStyle(
                            fontSize: 18,
                            color:
                            Theme.of(
                              context,
                            ).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ],
          ),

          const Divider(height: 24),
          _buildInfoRow(context, '📫', 'Dirección', _address),
          // _buildInfoRow(context, '📫', 'Dirección', widget.event['address'] ?? _address), // Usar cuando esté disponible
          const Divider(height: 24),
          _buildInfoRow(
            context,
            '🎟',
            'Entrada',
            widget.fullEvent['price']?.isNotEmpty == true                      // CAMBIO: fullEvent
                ? widget.fullEvent['price']!                                   // CAMBIO: fullEvent
                : 'Consultar',
          ),
          const Divider(height: 24),
          GestureDetector(
            onTap: _openWebsite,
            child: _buildInfoRow(
              context,
              '🌐',
              'Más información',
              'Ver sitio oficial',
              isLink: true,
              linkColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String emoji,
    String label,
    String value, {
    bool isLink = false,
    Color? linkColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      isLink
                          ? linkColor
                          : Theme.of(context).colorScheme.onSurface,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          icon: Icons.map_outlined,
          label: 'Maps',
          onTap: _openMaps,
          color: cardColor,
        ),
        _buildActionButton(
          context,
          icon: Icons.local_taxi_outlined,
          label: 'Uber',
          onTap: _openUber,
          color: cardColor,
        ),
        _buildActionButton(
          context,
          icon: Icons.share_outlined,
          label: 'Compartir',
          onTap: _shareEvent,
          color: cardColor,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600], // gris medio
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
