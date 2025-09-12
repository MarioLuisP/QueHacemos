/// Modal expandible para mostrar detalle del evento - REFACTORIZADO
library;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import '../../cache/cache_models.dart';
import '../../services/analytics_service.dart';

/// Modelo inmutable con todos los datos pre-calculados para el modal
class EventDetailData {
  // Datos del cache (ya pre-calculados)
  final String id;
  final String spacecode;
  final String title;
  final Color baseColor;
  final Color darkColor;
  final Color textColor;
  final String categoryWithEmoji;
  final String formattedDate;
  final String location;
  final String district;
  final String price;
  final Color onSurfaceColor;
  final Color surfaceColor;
  final Color outlineColor;
  final TextStyle? bodyLargeStyle;
  final TextStyle? headlineSmallStyle;

  // Datos adicionales de SQLite (pre-procesados)
  final String imageUrl;
  final String fullDescription;
  final String truncatedDescription;
  final String address;
  final String websiteUrl;
  final double lat;
  final double lng;
  final String shareMessage;

  const EventDetailData({
    required this.id,
    required this.spacecode,
    required this.title,
    required this.baseColor,
    required this.darkColor,
    required this.textColor,
    required this.categoryWithEmoji,
    required this.formattedDate,
    required this.location,
    required this.district,
    required this.price,
    required this.imageUrl,
    required this.fullDescription,
    required this.truncatedDescription,
    required this.address,
    required this.websiteUrl,
    required this.lat,
    required this.lng,
    required this.shareMessage,
    required this.onSurfaceColor,
    required this.surfaceColor,
    required this.outlineColor,
    required this.bodyLargeStyle,
    required this.headlineSmallStyle,
  });

  /// Factory para crear desde cache + datos SQLite
  factory EventDetailData.fromCacheAndDb(
      EventCacheItem cacheEvent,
      Map<String, dynamic> fullEvent,
      BuildContext context,
      ) {
    // Pre-calcular descripción truncada
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final fullDesc = fullEvent['description'] ?? '';
    const maxLength = 150;
    final truncatedDesc = fullDesc.length > maxLength
        ? '${fullDesc.substring(0, maxLength)}...'
        : fullDesc;

    // Pre-calcular mensaje de compartir
    final shareMsg = 'Te comparto este evento que vi en la app QuehaCeMos Cba:\n\n'
        '📌 ${cacheEvent.title}\n'
        '🗓 ${cacheEvent.formattedDateForCard}\n'
        '📍 ${cacheEvent.location}\n\n'
        '¡No te lo pierdas!\n'
        '¡📲 Descargá la app desde playstore!';

    return EventDetailData(
      id: cacheEvent.id.toString(),
      spacecode: cacheEvent.spacecode,
      title: cacheEvent.title,
      baseColor: cacheEvent.baseColor,
      darkColor: cacheEvent.darkColor,
      textColor: cacheEvent.textColor,
      categoryWithEmoji: cacheEvent.categoryWithEmoji,
      formattedDate: cacheEvent.formattedDateForCard,
      location: cacheEvent.location,
      district: cacheEvent.district,
      price: cacheEvent.price.isNotEmpty ? cacheEvent.price : 'Consultar',
      imageUrl: fullEvent['imageUrl'] ?? '',
      fullDescription: fullDesc,
      truncatedDescription: truncatedDesc,
      address: fullEvent['address'] ?? '',
      websiteUrl: fullEvent['websiteUrl'] ?? '',
      lat: (fullEvent['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (fullEvent['lng'] as num?)?.toDouble() ?? 0.0,
      shareMessage: shareMsg,
      onSurfaceColor: colorScheme.onSurface,
      surfaceColor: colorScheme.surface,
      outlineColor: colorScheme.outline,
      bodyLargeStyle: textTheme.bodyLarge,
      headlineSmallStyle: textTheme.headlineSmall,
    );
  }
}

class EventDetailModal {
  static void show(
      BuildContext context,
      EventCacheItem cacheEvent,
      Map<String, dynamic> fullEvent,
      ) {
    // Pre-calcular TODOS los datos antes de abrir el modal
    final detailData = EventDetailData.fromCacheAndDb(cacheEvent, fullEvent, context);
    AnalyticsService.trackDetailView(cacheEvent.spacecode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque, // <- CLAVE: captura taps transparentes
          onTap: () => Navigator.pop(context),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return GestureDetector(
                onTap: () {}, // <- Evitar propagación del tap del contenido
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.lerp(detailData.baseColor, Colors.white, 0.7)!,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: EventDetailContent(
                    data: detailData,
                    scrollController: scrollController,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// StatelessWidget optimizado - ZERO rebuilds internos
class EventDetailContent extends StatelessWidget {
  final EventDetailData data;
  final ScrollController scrollController;

  const EventDetailContent({
    super.key,
    required this.data,
    required this.scrollController,
  });

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
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image con botón de favorito
                _buildHeroImageSection(context),

                // Información principal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(context),
                      const SizedBox(height: 16),
                      _buildDescriptionSection(),
                      const SizedBox(height: 24),
                      _buildInfoSection(context),
                      const SizedBox(height: 24),
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

          Widget _buildHeroImageSection(BuildContext context) {
            return Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [data.baseColor, data.darkColor],
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => _openImageFullscreen(context),
                    child: ClipRRect(  // <- SOLO UN CLIP
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: data.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 250,
                        alignment: Alignment(0.0, -0.4),  // <- Alignment directo aquí
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white70),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.event, size: 64, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),


        // Botón de favorito con Selector optimizado
        Positioned(
          top: 24,
          right: 24,
          child: Selector<FavoritesProvider, bool>(
            selector: (context, favProvider) => favProvider.isFavorite(data.id),
            builder: (context, isFavorite, child) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(77),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                    size: 28,
                  ),
                    onPressed: () {
                      AnalyticsService.trackFavoriteToggle(data.spacecode);
                      context.read<FavoritesProvider>().toggleFavorite(data.id);
                    }
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          data.title,
          style: data.headlineSmallStyle?.copyWith(
            fontWeight: FontWeight.bold,
            color: data.onSurfaceColor,
          ),
        ),
        const SizedBox(height: 8),

        // Categoría
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: data.baseColor.withAlpha(51),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: data.baseColor.withAlpha(128)),
          ),
          child: Text(
            data.categoryWithEmoji,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return SizedBox(
      width: double.infinity,
      child: ExpandableDescription(
        fullDescription: data.fullDescription,
        truncatedDescription: data.truncatedDescription,
        baseColor: data.baseColor,
        onSurfaceColor: data.onSurfaceColor,
        bodyLargeStyle: data.bodyLargeStyle,
      ),
    );
  }
  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.outlineColor),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, '🗓 ', 'Fecha y Hora', data.formattedDate),
          const Divider(height: 24),
          _buildLocationRow(context),
          const Divider(height: 24),
          _buildInfoRow(context, '📫', 'Dirección', data.address),
          const Divider(height: 24),
          _buildInfoRow(context, '🎟', 'Entrada', data.price),
          const Divider(height: 24),
          GestureDetector(
            onTap: () => _openWebsite(data.websiteUrl),
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

  Widget _buildLocationRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📍', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ubicación'),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: data.location,
                    style: TextStyle(
                      fontSize: 16,
                      color: data.onSurfaceColor,
                    ),
                  ),
                  TextSpan(
                    text: '\n${data.district}',
                    style: TextStyle(
                      fontSize: 18,
                      color: data.onSurfaceColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
                style: data.bodyLargeStyle?.copyWith(
                  color: isLink ? linkColor : data.onSurfaceColor,
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
          onTap: () => _openMaps(data.lat, data.lng),
          color: data.baseColor,
        ),
        _buildActionButton(
          context,
          icon: Icons.local_taxi_outlined,
          label: 'Uber',
          onTap: () => _openUber(data.lat, data.lng, data.title),
          color: data.baseColor,
        ),
        _buildActionButton(
          context,
          icon: Icons.share_outlined,
          label: 'Compartir',
          onTap: () => _shareEvent(data.shareMessage),
          color: data.baseColor,
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
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos de acción - Todos estáticos con parámetros pre-calculados
  void _openImageFullscreen(BuildContext context) {
    if (data.imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: data.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.white70,
                  size: 64,
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening maps: $e');
    }
  }

  Future<void> _openUber(double lat, double lng, String title) async {
    final uri = Uri.parse(
      'uber://?action=setPickup&pickup=my_location&dropoff[latitude]=$lat&dropoff[longitude]=$lng&dropoff[nickname]=$title',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse(
        'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[latitude]=$lat&dropoff[longitude]=$lng',
      );
      await launchUrl(webUri);
    }
  }

  Future<void> _shareEvent(String message) async {
    try {
      Share.share(message);
    } catch (e) {
      print('Error sharing: $e');
    }
  }

  Future<void> _openWebsite(String websiteUrl) async {
    if (websiteUrl.isEmpty) return;
    try {
      final uri = Uri.parse(websiteUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening website: $e');
    }
  }
}

/// Widget separado para descripción expandible - Maneja su propio estado
class ExpandableDescription extends StatefulWidget {
  final String fullDescription;
  final String truncatedDescription;
  final Color baseColor;
  final Color onSurfaceColor;     // ← AGREGAR
  final TextStyle? bodyLargeStyle;

  const ExpandableDescription({
    super.key,
    required this.fullDescription,
    required this.truncatedDescription,
    required this.baseColor,
    required this.onSurfaceColor,     // ← AGREGAR
    required this.bodyLargeStyle,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isExpanded ? widget.fullDescription : widget.truncatedDescription,
            style: widget.bodyLargeStyle?.copyWith(
              height: 1.5,
              color: widget.onSurfaceColor,
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Text(
              _isExpanded ? 'Ver menos' : 'Ver más...',
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}