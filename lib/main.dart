// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'src/providers/favorites_provider.dart';
import 'src/providers/simple_home_provider.dart';
import 'src/themes/themes.dart';
import 'src/navigation/bottom_nav.dart';
import 'src/providers/notifications_provider.dart';

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
        // Provider principal para cache/filtros/tema
        ChangeNotifierProvider(
          create: (context) => SimpleHomeProvider(),
        ),
        // Otros providers
        ChangeNotifierProvider(
          create: (context) => FavoritesProvider(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: const _AppContent(),
    );
  }
}

/// Contenido de la app que maneja inicialización y tema
class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final simpleHomeProvider = Provider.of<SimpleHomeProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    // Inicializar providers
    await simpleHomeProvider.initialize();
    await favoritesProvider.init();

    // Conectar sync entre providers
    simpleHomeProvider.setupFavoritesSync(favoritesProvider);

    setState(() {
      _isInitialized = true;
    });

    print('🎉 App completamente inicializada con sync de favoritos');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return Consumer<SimpleHomeProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', ''), Locale('en', '')],
          title: 'Eventos Córdoba - Cache Test',
          theme: AppThemes.themes[provider.theme] ?? AppThemes.themes['normal']!,
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}