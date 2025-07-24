// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';  // NUEVO: agregar esta línea
import 'src/providers/favorites_provider.dart';
import 'src/providers/simple_home_provider.dart';
import 'src/pages/home_page.dart';
import 'src/navigation/bottom_nav.dart';
import 'dart:ui' as ui;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Aquí irá Firebase cuando sea necesario
  // await Firebase.initializeApp();
  Intl.defaultLocale = 'es_ES';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider principal - SÚPER simple
        ChangeNotifierProvider(
          create: (context) => SimpleHomeProvider(),
        ),

        // TODO: Otros providers cuando sean necesarios
        ChangeNotifierProvider(create: (context) => FavoritesProvider()),
        // ChangeNotifierProvider(create: (context) => PreferencesProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', ''), Locale('en', '')],
        title: 'Eventos Córdoba - Cache Test',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}