// lib/src/widgets/cards/fast_event_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/simple_home_provider.dart';
import '../../providers/category_constants.dart';
import '../../cache/cache_models.dart';
import '../../utils/dimens.dart';
import '../../utils/colors.dart';
import 'unified_event_card_painter.dart';

/// Widget optimizado para renderizar tarjetas de eventos desde cache
/// Version adaptada para SimpleHomeProvider + EventCacheItem
class FastEventCard extends StatefulWidget {
  final EventCacheItem event;
  final SimpleHomeProvider provider;

  const FastEventCard({
    super.key,
    required this.event,
    required this.provider,
  });

  @override
  State<FastEventCard> createState() => _FastEventCardState();
}

class _FastEventCardState extends State<FastEventCard> with TickerProviderStateMixin {
  /// Crear el UnifiedEventCardPainter con datos del cache
  UnifiedEventCardPainter _createUnifiedPainter(int rating) {
    final categoryWithEmoji = widget.provider.getCategoryWithEmoji(widget.event.type);
    final formattedDate = widget.provider.formatEventDate(
      widget.event.date,
      format: 'card',
    );

    // TODO: Agregar theme provider cuando esté listo
    const theme = 'normal'; // Hardcoded por ahora
    final uiCategory = CategoryConstants.getUiName(widget.event.type.toLowerCase());

    return UnifiedEventCardPainter(
      rating: rating,
      title: widget.event.title,
      categoryWithEmoji: categoryWithEmoji,
      formattedDate: formattedDate,
      location: widget.event.location,
      district: widget.event.district,
      price: widget.event.price,
      isFavorite: widget.event.isFavorite,
      theme: theme,
      category: uiCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rating = widget.event.rating;

    return GestureDetector(
      onTapDown: (details) {
        // Obtener la posición relativa del tap
        final RenderBox box = context.findRenderObject() as RenderBox;
        final size = box.size;
        final localPosition = box.globalToLocal(details.globalPosition);

        // Crear painter para hacer hit test
        final painter = _createUnifiedPainter(rating);

        // Si tocó el corazón, toggle favorito
        if (painter.hitTestHeart(localPosition, size)) {
          widget.provider.toggleFavorite(widget.event.id);
        } else {
          // Si no, abrir modal de detalles
          _showEventDetails();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        child: RepaintBoundary(
          child: CustomPaint(
            size: const Size(double.infinity, 236),
            painter: _createUnifiedPainter(rating),
            isComplex: true,
            willChange: false,
          ),
        ),
      ),
    );
  }

  /// Mostrar detalles del evento (temporal)
  void _showEventDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Evento: ${widget.event.title}'),
        action: SnackBarAction(
          label: 'Detalles',
          onPressed: () {
            // TODO: Implementar modal de detalles
            print('Abrir modal para evento ${widget.event.id}');
          },
        ),
      ),
    );
  }
}

/// Painter simplificado temporal - REEMPLAZAR por tu UnifiedEventCardPainter
/// TODO: Crear colors básicos temporales para que compile tu UnifiedEventCardPainter
class UnifiedEventCardPainter extends CustomPainter {
  // Datos del evento
  final int rating;
  final String title;
  final String categoryWithEmoji;
  final String formattedDate;
  final String location;
  final String district;
  final String price;
  final bool isFavorite;
  final String theme;
  final String category;

  // Callbacks
  final VoidCallback? onFavoriteTap;

  // Cache de Paints y TextPainters - ESTÁTICOS para reutilización
  static final Map<String, Paint> _shadowPaints = {};
  static final Map<String, TextPainter> _textPainters = {};
  static bool _initialized = false;

  UnifiedEventCardPainter({
    required this.rating,
    required this.title,
    required this.categoryWithEmoji,
    required this.formattedDate,
    required this.location,
    required this.district,
    required this.price,
    required this.isFavorite,
    required this.theme,
    required this.category,
    this.onFavoriteTap,
  }) {
    // Inicializar recursos la primera vez
    if (!_initialized) {
      _initializeResources();
      _initialized = true;
    }
  }

  /// Inicializa todos los recursos estáticos una sola vez
  static void _initializeResources() {
    // Crear solo los shadow paints (los gradient paints se crean en paint())
    EventCardColorPalette.colors.forEach((themeName, themeColors) {
      themeColors.forEach((categoryName, colors) {
        final key = '$themeName-$categoryName';

        // Paint para la sombra (reutilizable)
        _shadowPaints[key] = Paint()
          ..color = Colors.black.withAlpha(26)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      });
    });

    // Inicializar TextPainters base (sin texto)
    _textPainters['title'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    _textPainters['category'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    _textPainters['date'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    _textPainters['location'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    _textPainters['district'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    _textPainters['price'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // PASO 1: Pintar tarjeta base (TODAS pasan por aquí)
    _drawBaseCard(canvas, size);

    // PASO 2: Badge si es destacado (rating >= 100)
    if (rating >= 100) {
      _drawDestacadoBadge(canvas, size);
    }

    // PASO 3: Borde si es silver (rating >= 200)
    if (rating >= 200) {
      _drawSilverBorder(canvas, size);
    }

    // FIN - Tarjetas 0-200 terminadas aquí
  }

  /// Dibuja la tarjeta base completa (extraído del EventCardPainter original)
  void _drawBaseCard(Canvas canvas, Size size) {
    final colors = EventCardColorPalette.getColors(theme, category);
    final paintKey = '$theme-$category';

    // Crear el paint del gradiente aquí con el tamaño real
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.base, colors.dark],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // 1. Dibujar sombra
    final shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(AppDimens.borderRadius),
        ),
      );
    canvas.drawPath(shadowPath, _shadowPaints[paintKey]!);

    // 2. Dibujar fondo con gradiente
    final backgroundPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(AppDimens.borderRadius),
        ),
      );
    canvas.drawPath(backgroundPath, gradientPaint);

    // 3. Preparar y dibujar textos
    const leftPadding = AppDimens.paddingMedium;
    const rightPadding = AppDimens.paddingMedium;
    final textWidth = size.width - leftPadding - rightPadding - 40; // 40 para el corazón

    // Título con ellipsis (FIX #1)
    _textPainters['title']!.text = TextSpan(
      text: title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colors.text,
        overflow: TextOverflow.ellipsis,
      ),
    );
    _textPainters['title']!.layout(maxWidth: textWidth);
    _textPainters['title']!.paint(canvas, const Offset(leftPadding, 16));

    // Categoría con emoji
    _textPainters['category']!.text = TextSpan(
      text: categoryWithEmoji,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.text.withAlpha(230),
        height: 1.0,
      ),
    );
    _textPainters['category']!.layout(maxWidth: textWidth);
    _textPainters['category']!.paint(canvas, const Offset(leftPadding, 46));

    // Línea divisoria
    final linePaint = Paint()
      ..color = colors.text.withAlpha(77)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(leftPadding, 80),
      Offset(size.width - rightPadding, 80),
      linePaint,
    );

    // Fecha
    _textPainters['date']!.text = TextSpan(
      text: '🗓  $formattedDate',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.text,
      ),
    );
    _textPainters['date']!.layout(maxWidth: textWidth);
    _textPainters['date']!.paint(canvas, const Offset(leftPadding, 90));

    // Corazón de favoritos con posición relativa (FIX #2)
    _drawHeartFavorite(canvas, size, colors);

    // Ubicación con emoji
    _textPainters['location']!.text = TextSpan(
      text: '📍 $location',
      style: TextStyle(fontSize: 18, color: colors.text),
    );
    _textPainters['location']!.layout(maxWidth: textWidth);
    _textPainters['location']!.paint(canvas, const Offset(leftPadding, 125));

    // Distrito
    _textPainters['district']!.text = TextSpan(
      text: '     $district', // Espacios para alinear con el emoji
      style: TextStyle(fontSize: 14, color: colors.text.withAlpha(179)),
    );
    _textPainters['district']!.layout(maxWidth: textWidth);
    _textPainters['district']!.paint(canvas, const Offset(leftPadding, 148));

    // Precio
    _textPainters['price']!.text = TextSpan(
      text: '🎟  ${price.isNotEmpty ? price : 'Consultar'}',
      style: TextStyle(fontSize: 16, color: colors.text),
    );
    _textPainters['price']!.layout(maxWidth: textWidth);
    _textPainters['price']!.paint(canvas, const Offset(leftPadding, 180));
  }

  /// Dibuja el corazón con posición relativa (como la medalla)
  void _drawHeartFavorite(Canvas canvas, Size size, EventCardColors colors) {
    const rightPadding = AppDimens.paddingMedium;
    const heartSize = 20.0;

    // Posición relativa (FIX #2)
    final heartX = size.width - rightPadding - heartSize;
    final heartY = 95.0;

    final heartPaint = Paint()
      ..color = isFavorite ? Colors.red : colors.text
      ..style = isFavorite ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Dibujar corazón simple con Path
    final heartPath = Path();

    // Forma de corazón simplificada
    heartPath.moveTo(heartX + heartSize / 2, heartY + heartSize * 0.85);
    heartPath.cubicTo(
      heartX + heartSize * 0.2,
      heartY + heartSize * 0.6,
      heartX,
      heartY + heartSize * 0.3,
      heartX,
      heartY + heartSize * 0.3,
    );
    heartPath.cubicTo(
      heartX,
      heartY,
      heartX + heartSize * 0.5,
      heartY,
      heartX + heartSize / 2,
      heartY + heartSize * 0.3,
    );
    heartPath.cubicTo(
      heartX + heartSize / 2,
      heartY,
      heartX + heartSize,
      heartY,
      heartX + heartSize,
      heartY + heartSize * 0.3,
    );
    heartPath.cubicTo(
      heartX + heartSize,
      heartY + heartSize * 0.3,
      heartX + heartSize * 0.8,
      heartY + heartSize * 0.6,
      heartX + heartSize / 2,
      heartY + heartSize * 0.85,
    );
    canvas.drawPath(heartPath, heartPaint);
  }

  /// Dibuja el badge de "Destacado" (extraído de DestacadoEventCardPainter)
  void _drawDestacadoBadge(Canvas canvas, Size size) {
    // Posición del badge (esquina inferior derecha con padding)
    const badgeSize = 40.0;
    const padding = 16.0;

    final badgeX = size.width - padding - badgeSize;
    final badgeY = size.height - padding - badgeSize;

    // TextPainter para el emoji 🏅
    final badgeTextPainter = TextPainter(
      text: const TextSpan(
        text: '🏅',
        style: TextStyle(
          fontSize: badgeSize,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Layout y paint del badge
    badgeTextPainter.layout();
    badgeTextPainter.paint(
      canvas,
      Offset(badgeX, badgeY),
    );
  }

  /// Dibuja el borde dorado (extraído de SilverEventCardPainter)
  void _drawSilverBorder(Canvas canvas, Size size) {
    // Paint para el borde dorado adaptativo por tema
    final borderPaint = Paint()
      ..color = _getBorderColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Path del borde (misma forma que la tarjeta)
    final borderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        Radius.circular(AppDimens.borderRadius),
      ));

    // Dibujar el borde dorado
    canvas.drawPath(borderPath, borderPaint);
  }

  /// Obtiene el color del borde según el tema para máxima visibilidad
  Color _getBorderColor() {
    switch (theme) {
      case 'dark':
      case 'fluor':
        return const Color(0xFFFFD700); // Oro clásico brillante
      case 'normal':
      case 'pastel':
        return const Color(0xFFB8860B); // Oro oscuro (DarkGoldenRod)
      case 'sepia':
        return const Color(0xFFCD853F); // Oro terroso (Peru)
      case 'harmony':
        return const Color(0xFFDAA520); // Oro medio (GoldenRod)
      default:
        return const Color(0xFFB8860B); // Fallback oro oscuro
    }
  }

  @override
  bool shouldRepaint(UnifiedEventCardPainter oldDelegate) {
    // Solo repintar si cambian datos relevantes
    return rating != oldDelegate.rating ||
        title != oldDelegate.title ||
        categoryWithEmoji != oldDelegate.categoryWithEmoji ||
        formattedDate != oldDelegate.formattedDate ||
        location != oldDelegate.location ||
        district != oldDelegate.district ||
        price != oldDelegate.price ||
        isFavorite != oldDelegate.isFavorite ||
        theme != oldDelegate.theme ||
        category != oldDelegate.category;
  }

  /// Método para detectar si se tocó el corazón (actualizado para posición relativa)
  bool hitTestHeart(Offset position, Size size) {
    const rightPadding = AppDimens.paddingMedium;
    const heartSize = 20.0;

    // Área del corazón con posición relativa precisa
    final heartX = size.width - rightPadding - heartSize;
    final heartRect = Rect.fromLTWH(heartX - 10, 85, 40, 40);
    return heartRect.contains(position);
  }
}

/// EventCardColorPalette temporal para que compile UnifiedEventCardPainter
/// YA NO NECESARIO - usando el real de colors.dart