import 'package:flutter/material.dart';


// ============ NUEVA ESTRUCTURA: COLORES PRECALCULADOS PARA TARJETAS ============

/// Clase que contiene los 3 colores necesarios para una tarjeta de evento
class EventCardColors {
  final Color base; // Color base de la categoría
  final Color dark; // Color oscuro para gradiente
  final Color text; // Color de texto óptimo

  const EventCardColors({
    required this.base,
    required this.dark,
    required this.text,
  });
}

/// Colores precalculados para tarjetas de eventos
/// 12 categorías × 6 temas = 72 combinaciones precalculadas
/// Cada color de texto está optimizado para máxima legibilidad y personalidad
class EventCardColorPalette {
  static const Map<String, Map<String, EventCardColors>> colors = {
    'normal': {
      'musica': EventCardColors(
        base: Color(0xFFFCA1AE),
        dark: Color(0xFFCA818B), // 20% más oscuro
        text: Color(0xFF3D1A1F),
      ),
      'teatro': EventCardColors(
        base: Color(0xFFD7D26D),
        dark: Color(0xFFACA857), // 20% más oscuro
        text: Color(0xFF2D3D00),
      ),
      'standup': EventCardColors(
        base: Color(0xFF3CCDC7),
        dark: Color(0xFF30A49F), // 20% más oscuro
        text: Color(0xFF002D3D),
      ),
      'arte': EventCardColors(
        base: Color(0xFFFD8977),
        dark: Color(0xFFCA6E5F), // 20% más oscuro
        text: Color(0xFF3D1E00),
      ),
      'cine': EventCardColors(
        base: Color(0xFFEBE7A7),
        dark: Color(0xFFBCB986), // 20% más oscuro
        text: Color(0xFF001B3D),
      ),
      'mic': EventCardColors(
        base: Color(0xFFE1BEE7),
        dark: Color(0xFFB498B9), // 20% más oscuro
        text: Color(0xFF2D003D),
      ),
      'cursos': EventCardColors(
        base: Color(0xFFF5DD7E),
        dark: Color(0xFFC4B165), // 20% más oscuro
        text: Color(0xFF3D2D00),
      ),
      'ferias': EventCardColors(
        base: Color(0xFFFFCDD2),
        dark: Color(0xFFCCA4A8), // 20% más oscuro
        text: Color(0xFF3D000F),
      ),
      'calle': EventCardColors(
        base: Color(0xFFB3E5FC),
        dark: Color(0xFF8FB7CA), // 20% más oscuro
        text: Color(0xFF001E3D),
      ),
      'redes': EventCardColors(
        base: Color(0xFFC8E6C9),
        dark: Color(0xFFA0B8A1), // 20% más oscuro
        text: Color(0xFF002D0F),
      ),
      'ninos': EventCardColors(
        base: Color(0xFFD6CBAE),
        dark: Color(0xFFABA28B), // 20% más oscuro
        text: Color(0xFF3D2814),
      ),
      'danza': EventCardColors(
        base: Color(0xFFFDA673),
        dark: Color(0xFFCA855C), // 20% más oscuro
        text: Color(0xFF2D1400),
      ),
    },

    'dark': {
      'musica': EventCardColors(
        base: Color(0xFF7E5157),
        dark: Color(0xFF654146),
        text: Color(0xFFFFEBF5), // Rosa muy claro
      ),
      'teatro': EventCardColors(
        base: Color(0xFF6C6937),
        dark: Color(0xFF56542C),
        text: Color(0xFFF5FFDC), // Verde muy claro
      ),
      'standup': EventCardColors(
        base: Color(0xFF1E6764),
        dark: Color(0xFF185250),
        text: Color(0xFFDCFFFF), // Cian muy claro
      ),
      'arte': EventCardColors(
        base: Color(0xFF7F453C),
        dark: Color(0xFF663730),
        text: Color(0xFFFFF8F0), // Crema cálido
      ),
      'cine': EventCardColors(
        base: Color(0xFF767454),
        dark: Color(0xFF5E5D43),
        text: Color(0xFFFFFCE6), // Amarillo muy claro
      ),
      'mic': EventCardColors(
        base: Color(0xFF715F74),
        dark: Color(0xFF5A4C5D),
        text: Color(0xFFFAF0FF), // Lavanda muy claro
      ),
      'cursos': EventCardColors(
        base: Color(0xFF7B6F3F),
        dark: Color(0xFF625932),
        text: Color(0xFFFFFADC), // Dorado muy claro
      ),
      'ferias': EventCardColors(
        base: Color(0xFF806769),
        dark: Color(0xFF665254),
        text: Color(0xFFFFF5F8), // Rosa muy claro
      ),
      'calle': EventCardColors(
        base: Color(0xFF5A737E),
        dark: Color(0xFF485C65),
        text: Color(0xFFF0F8FF), // Azul muy claro
      ),
      'redes': EventCardColors(
        base: Color(0xFF647365),
        dark: Color(0xFF505C51),
        text: Color(0xFFF0FFF5), // Verde muy claro
      ),
      'ninos': EventCardColors(
        base: Color(0xFF6B6657),
        dark: Color(0xFF565246),
        text: Color(0xFFFAF8F5), // Beige muy claro
      ),
      'danza': EventCardColors(
        base: Color(0xFF7F533A),
        dark: Color(0xFF66422E),
        text: Color(0xFFFFF0E4), // Durazno muy claro
      ),
    },

    'fluor': {
      'musica': EventCardColors(
        base: Color(0xFFFFC1D1),
        dark: Color(0xFFCC9AA7),
        text: Color(0xFF3D1A1F), // Chocolate bordeaux
      ),
      'teatro': EventCardColors(
        base: Color(0xFFFFFC83),
        dark: Color(0xFFCCCA69),
        text: Color(0xFF2D3D00), // Verde oliva oscuro
      ),
      'standup': EventCardColors(
        base: Color(0xFF48F6EF),
        dark: Color(0xFF3AC5BF),
        text: Color(0xFF002D3D), // Azul petróleo
      ),
      'arte': EventCardColors(
        base: Color(0xFFFFA48F),
        dark: Color(0xFFCC8372),
        text: Color(0xFF3D1E00), // Marrón terracota
      ),
      'cine': EventCardColors(
        base: Color(0xFFFFFC8),
        dark: Color(0xFFCCCCA0),
        text: Color(0xFF001B3D), // Azul marino
      ),
      'mic': EventCardColors(
        base: Color(0xFFFFE4FF),
        dark: Color(0xFFCCB6CC),
        text: Color(0xFF2D003D), // Púrpura oscuro
      ),
      'cursos': EventCardColors(
        base: Color(0xFFFFFF97),
        dark: Color(0xFFCCCC79),
        text: Color(0xFF3D2D00), // Dorado oscuro
      ),
      'ferias': EventCardColors(
        base: Color(0xFFFFF6FC),
        dark: Color(0xFFCCC5CA),
        text: Color(0xFF3D000F), // Rojo oscuro
      ),
      'calle': EventCardColors(
        base: Color(0xFFD7FFFF),
        dark: Color(0xFFACCCCC),
        text: Color(0xFF001E3D), // Azul cielo oscuro
      ),
      'redes': EventCardColors(
        base: Color(0xFFF0FFF1),
        dark: Color(0xFFC0CCC1),
        text: Color(0xFF002D0F), // Verde bosque
      ),
      'ninos': EventCardColors(
        base: Color(0xFFFFF4D1),
        dark: Color(0xFFCCC3A7),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'danza': EventCardColors(
        base: Color(0xFFFFC78A),
        dark: Color(0xFFCC9F6E),
        text: Color(0xFF2D1400), // Naranja chocolate
      ),
    },

    'harmony': {
      'musica': EventCardColors(
        base: Color(0xFFFCAAB6),
        dark: Color(0xFFCA8892),
        text: Color(0xFF3D1A1F), // Chocolate bordeaux
      ),
      'teatro': EventCardColors(
        base: Color(0xFFDBD77C),
        dark: Color(0xFFAFAC63),
        text: Color(0xFF2D3D00), // Verde oliva oscuro
      ),
      'standup': EventCardColors(
        base: Color(0xFF50D2CD),
        dark: Color(0xFF40A8A4),
        text: Color(0xFF002D3D), // Azul petróleo
      ),
      'arte': EventCardColors(
        base: Color(0xFFFD9585),
        dark: Color(0xFFCA776A),
        text: Color(0xFF3D1E00), // Marrón terracota
      ),
      'cine': EventCardColors(
        base: Color(0xFFEDE9B0),
        dark: Color(0xFFBEBA8D),
        text: Color(0xFF001B3D), // Azul marino
      ),
      'mic': EventCardColors(
        base: Color(0xFFE4C5E9),
        dark: Color(0xFFB69EBA),
        text: Color(0xFF2D003D), // Púrpura oscuro
      ),
      'cursos': EventCardColors(
        base: Color(0xFFF6E08B),
        dark: Color(0xFFC5B36F),
        text: Color(0xFF3D2D00), // Dorado oscuro
      ),
      'ferias': EventCardColors(
        base: Color(0xFFFFD2D7),
        dark: Color(0xFFCCA8AC),
        text: Color(0xFF3D000F), // Rojo oscuro
      ),
      'calle': EventCardColors(
        base: Color(0xFFBBE8FC),
        dark: Color(0xFF96BACA),
        text: Color(0xFF001E3D), // Azul cielo oscuro
      ),
      'redes': EventCardColors(
        base: Color(0xFFCEE9CE),
        dark: Color(0xFFA5BAA5),
        text: Color(0xFF002D0F), // Verde bosque
      ),
      'ninos': EventCardColors(
        base: Color(0xFFDAD0B6),
        dark: Color(0xFFAEA692),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'danza': EventCardColors(
        base: Color(0xFFFDAF81),
        dark: Color(0xFFCA8C67),
        text: Color(0xFF2D1400), // Naranja chocolate
      ),
    },

    'sepia': {
      'musica': EventCardColors(
        base: Color(0xFFF5EBD0),
        dark: Color(0xFFC4BCA6),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'teatro': EventCardColors(
        base: Color(0xFFEAD8B0),
        dark: Color(0xFFBBAD8D),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'standup': EventCardColors(
        base: Color(0xFFF3E1D2),
        dark: Color(0xFFC2B4A8),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'arte': EventCardColors(
        base: Color(0xFFD5B59B),
        dark: Color(0xFFAA917C),
        text: Color(0xFF3D1E00), // Marrón terracota
      ),
      'cine': EventCardColors(
        base: Color(0xFFC4A484),
        dark: Color(0xFF9D836A),
        text: Color(0xFF3D1E00), // Marrón terracota
      ),
      'mic': EventCardColors(
        base: Color(0xFFB68E72),
        dark: Color(0xFF92725B),
        text: Color(0xFF3D1E00), // Marrón terracota
      ),
      'cursos': EventCardColors(
        base: Color(0xFFD9B08C),
        dark: Color(0xFFAE8D70),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'ferias': EventCardColors(
        base: Color(0xFFD6CFC6),
        dark: Color(0xFFABA69E),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'calle': EventCardColors(
        base: Color(0xFFE4C1A1),
        dark: Color(0xFFB69A81),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'redes': EventCardColors(
        base: Color(0xFFA38C7A),
        dark: Color(0xFF827062),
        text: Color(0xFFFAF8F5), // Beige muy claro
      ),
      'ninos': EventCardColors(
        base: Color(0xFFF0E9E2),
        dark: Color(0xFFC0BAB5),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'danza': EventCardColors(
        base: Color(0xFF7C5E48),
        dark: Color(0xFF634B3A),
        text: Color(0xFFFFF0E4), // Durazno muy claro
      ),
    },

    'pastel': {
      'musica': EventCardColors(
        base: Color(0xFFFEE3E7),
        dark: Color(0xFFCBB6B9),
        text: Color(0xFF3D1A1F), // Chocolate bordeaux
      ),
      'teatro': EventCardColors(
        base: Color(0xFFF3F2D3),
        dark: Color(0xFFC2C2A9),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'standup': EventCardColors(
        base: Color(0xFFC5F0EE),
        dark: Color(0xFF9EC0BE),
        text: Color(0xFF002D3D), // Azul petróleo
      ),
      'arte': EventCardColors(
        base: Color(0xFFFEDCD6),
        dark: Color(0xFFCBB0AB),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'cine': EventCardColors(
        base: Color(0xFFF9F8E5),
        dark: Color(0xFFC7C6B7),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'mic': EventCardColors(
        base: Color(0xFFF6ECF8),
        dark: Color(0xFFC5BDC6),
        text: Color(0xFF3D1A1F), // Chocolate bordeaux
      ),
      'cursos': EventCardColors(
        base: Color(0xFFFCF5D8),
        dark: Color(0xFFCAC4AD),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'ferias': EventCardColors(
        base: Color(0xFFFFF0F2),
        dark: Color(0xFFCCC0C2),
        text: Color(0xFF3D1A1F), // Chocolate bordeaux
      ),
      'calle': EventCardColors(
        base: Color(0xFFE8F7FE),
        dark: Color(0xFFBAC6CB),
        text: Color(0xFF001E3D), // Azul cielo oscuro
      ),
      'redes': EventCardColors(
        base: Color(0xFFEFF8EF),
        dark: Color(0xFFBFC6BF),
        text: Color(0xFF002D0F), // Verde bosque
      ),
      'ninos': EventCardColors(
        base: Color(0xFFF3EFE7),
        dark: Color(0xFFC2BFB9),
        text: Color(0xFF3D2814), // Marrón suave
      ),
      'danza': EventCardColors(
        base: Color(0xFFFEE4D5),
        dark: Color(0xFFCBB6AA),
        text: Color(0xFF2D1400), // Naranja chocolate
      ),
    }, // ← Cerrar aquí después de pastel
  };

  /// Obtiene los colores optimizados para una categoría y tema específicos
  static EventCardOptimizedColors getOptimizedColors(String theme, String category) {
    // Fallback al tema normal si no se encuentra el tema
    final themeColors = colors[theme] ?? colors['normal']!;

    // Fallback a color por defecto si no se encuentra la categoría
    final baseColors = themeColors[category] ??
        const EventCardColors(
          base: Color(0xFFE0E0E0),
          dark: Color(0xFFB4B4B4),
          text: Colors.black87,
        );

    return EventCardOptimizedColors.fromBase(baseColors);
  }
}
class AppColors {
  static const textDark = Colors.black87;
  static const textLight = Colors.white70;
  static const defaultColor = Color(0xFFE0E0E0);
}
/// Nombres de categorías con emojis (movido desde EventDataBuilder)
/// Evita recalcular en cada build() del widget
class CategoryDisplayNames {
  static const Map<String, String> withEmojis = {
    'musica': '🎵 Música en vivo',
    'teatro': '🎭 Teatro y Performance',
    'standup': '🎤 StandUp y Humor',
    'arte': '🎨 Arte y Exposiciones',
    'cine': '🎬 Cine y Proyecciones',
    'mic': '🎙️ Mic abierto y Poesía',
    'cursos': '📚 Cursos y Talleres',
    'ferias': '🛍️ Ferias artesanales',
    'calle': '🌳 Eventos al Aire Libre',
    'redes': '📱 Eventos Digitales',
    'ninos': '👶 Niños y Familia',
    'danza': '💃 Danza y Movimientos',
  };

  static String getCategoryWithEmoji(String type) {
    return withEmojis[type.toLowerCase()] ?? type;
  }
}


extension ColorBrightness on Color {
  Color withBrightness(double factor) {
    final r = (red * factor).clamp(0, 255).toInt();
    final g = (green * factor).clamp(0, 255).toInt();
    final b = (blue * factor).clamp(0, 255).toInt();
    return Color.fromARGB(alpha, r, g, b);
  }
}
/// Versión con opacities pre-calculadas usando withAlpha
class EventCardOptimizedColors extends EventCardColors {
  final Color textFaded90;
  final Color textFaded70;
  final Color textFaded30;

  const EventCardOptimizedColors({
    required super.base,
    required super.dark,
    required super.text,
    required this.textFaded90,
    required this.textFaded70,
    required this.textFaded30,
  });

  factory EventCardOptimizedColors.fromBase(EventCardColors colors) {
    return EventCardOptimizedColors(
      base: colors.base,
      dark: colors.dark,
      text: colors.text,
      textFaded90: colors.text.withAlpha(229), // 0.9 * 255
      textFaded70: colors.text.withAlpha(179), // 0.7 * 255
      textFaded30: colors.text.withAlpha(77),  // 0.3 * 255
    );
  }
}