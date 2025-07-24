// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'src/providers/favorites_provider.dart';
import 'src/providers/simple_home_provider.dart';
import 'src/providers/preferences_provider.dart'; // NUEVO: import nuevo provider
import 'src/pages/home_page.dart';
import 'src/themes/themes.dart';
import 'src/navigation/bottom_nav.dart';
import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_ES';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // NUEVO: PreferencesProvider para temas
        ChangeNotifierProvider(
          create: (context) => PreferencesProvider(),
        ),

        // Provider principal para cache/filtros
        ChangeNotifierProvider(
          create: (context) => SimpleHomeProvider(),
        ),

        // Otros providers
        ChangeNotifierProvider(create: (context) => FavoritesProvider()),
      ],
      child: Consumer<PreferencesProvider>( // CAMBIO: ahora usa PreferencesProvider
        builder: (context, preferencesProvider, child) {
          return FutureBuilder(
            // NUEVO: Inicializar PreferencesProvider
            future: preferencesProvider.initialize(),
            builder: (context, snapshot) {
              return MaterialApp(
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('es', ''), Locale('en', '')],
                title: 'Eventos Córdoba - Cache Test',
                // CAMBIO: usa preferencesProvider.theme en lugar de provider.theme
                theme: AppThemes.themes[preferencesProvider.theme] ?? AppThemes.themes['normal']!,
                home: const MainScreen(),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}