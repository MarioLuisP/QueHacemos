import 'package:flutter/material.dart';

class AppThemes {
  // ============ TEMAS QUE YA FUNCIONAN BIEN ============

  static final ThemeData normalTheme = (() {
    final Color baseAppBarColor = Color(0xFFE48832); // marrón
    final Color secondaryLerped = Color(0xFFF0E2D7); // Ya calculado: Color.lerp(baseAppBarColor, Colors.white, 0.35)

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFF5E3011),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFF7F2DB),
        secondary: secondaryLerped,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Color(0xFFF0E2D7),
      appBarTheme: AppBarTheme(
        backgroundColor: baseAppBarColor,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  })();

  static final ThemeData darkTheme = (() {
    final Color baseAppBarColor = Colors.grey[900]!;
    final Color secondaryLerped = Color(0xFF595959); // Ya calculado: Color.lerp(baseAppBarColor, Colors.white, 0.35)

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.blueGrey,
      colorScheme: ColorScheme.dark(
        primary: Colors.blueGrey,
        secondary: secondaryLerped,
        surface: Colors.grey[900]!,
      ),
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: baseAppBarColor,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey,
      ),
    );
  })();

  static final ThemeData sepiaTheme = (() {
    final Color baseAppBarColor = const Color(0xFF6B4E31);
    final Color secondaryLerped = Color(0xFF9C8A7A); // Ya calculado: Color.lerp(baseAppBarColor, Colors.white, 0.35)

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: baseAppBarColor,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFF1E2C2),
        secondary: secondaryLerped,
        surface: const Color(0xFFF8F1E9),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F1E9),
      appBarTheme: AppBarTheme(
        backgroundColor: baseAppBarColor,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFFA38C7A),
        unselectedItemColor: Colors.grey,
      ),
    );
  })();

  // ============ TEMAS NORMALIZADOS CON VALORES FIJOS ============

  static final ThemeData fluorTheme = (() {
    final Color baseAppBarColor = Colors.black;
    final Color secondaryLerped = Color(0xFF595959); // Calculado: Color.lerp(Colors.black, Colors.white, 0.35)

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.pinkAccent,
      colorScheme: ColorScheme.dark(
        primary: Colors.pinkAccent,
        secondary: secondaryLerped,
        surface: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: baseAppBarColor,
        foregroundColor: Colors.cyanAccent,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
        bodyMedium: TextStyle(color: Colors.limeAccent),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
      ),
    );
  })();

  static final ThemeData harmonyTheme = (() {
    final Color baseAppBarColor = CustomColors.peach; // Color(0xFFFFE4B5)
    final Color secondaryLerped = Color(0xFFFFEDCF); // Calculado: Color.lerp(peach, Colors.white, 0.35)

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: CustomColors.peach,
      colorScheme: ColorScheme.light(
        primary: CustomColors.peach,
        secondary: secondaryLerped,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: baseAppBarColor,
        foregroundColor: Colors.black87,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: CustomColors.mint,
        unselectedItemColor: Colors.grey,
      ),
    );
  })();

  static final ThemeData pastelTheme = (() {
    final Color baseAppBarColor = Color(0xFFF4EBE0); // Calculado: Color.lerp(Color(0xFFE4CDB2), Colors.white, 0.6)
    final Color secondaryLerped = Color(0xFFF8F2EB); // Calculado: Color.lerp(baseAppBarColor, Colors.white, 0.35)

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFFBCE0FB), // Calculado: Color.lerp(Colors.blue, Colors.white, 0.7)
      colorScheme: ColorScheme.light(
        primary: Color(0xFFFBEFBC), // Calculado: Color.lerp(Colors.blue, Colors.white, 0.7)
        secondary: secondaryLerped,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Color(0xFFD6AF82), // Calculado: Color.lerp(Color.fromARGB(255, 196, 140, 76), Colors.white, 0.3)
      appBarTheme: AppBarTheme(
        backgroundColor: baseAppBarColor,
        foregroundColor: Colors.black87,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF7AC0F8), // Calculado: Color.lerp(Colors.blue, Colors.white, 0.4)
        unselectedItemColor: Colors.grey,
      ),
    );
  })();

  // ============ MAPA DE TEMAS ============

  static Map<String, ThemeData> themes = {
    'normal': normalTheme,
    'dark': darkTheme,
    'fluor': fluorTheme,
    'harmony': harmonyTheme,
    'sepia': sepiaTheme,
    'pastel': pastelTheme,
  };
}

class CustomColors {
  static const peach = Color(0xFFFFE4B5);
  static const mint = Color(0xFF98FF98);
}