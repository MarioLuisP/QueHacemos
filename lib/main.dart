// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/providers/favorites_provider.dart';
import 'src/providers/simple_home_provider.dart';
import 'src/themes/themes.dart';
import 'src/navigation/bottom_nav.dart';
import 'src/providers/notifications_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'src/services/notification_service.dart';
import 'src/sync/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_ES';

  // Inicializar timezone
  tz.initializeTimeZones();

  // Inicializar notificaciones
  await NotificationService.initialize();

  // ✅ NUEVO: Verificar y ejecutar primera instalación
  await _ensureFirstInstallation();

  runApp(const MyApp());
}

/// Garantizar que la primera instalación descarga los 10 lotes
/// Solo se ejecuta UNA VEZ en la vida de la app
Future<void> _ensureFirstInstallation() async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstInstall = prefs.getBool('app_initialized') ?? true;

  if (isFirstInstall) {
    print('🚀 Primera instalación detectada - Descargando eventos...');

    try {
      // Forzar descarga de 10 lotes (bypassing shouldSync)
      final syncResult = await SyncService().firstInstallSync();

      if (syncResult.success && syncResult.eventsAdded > 0) {
        // Marcar app como inicializada - NUNCA MÁS sync en startup
        await prefs.setBool('app_initialized', false);
        print('✅ Primera instalación completada: ${syncResult.eventsAdded} eventos descargados');
      } else {
        print('⚠️ Primera instalación sin datos - manteniendo flag para reintentar');
        // No marcar como inicializada si no hay datos
      }

    } catch (e) {
      print('❌ Error en primera instalación: $e');
      // No marcar como inicializada si hay error
    }
  } else {
    print('⚡ App ya inicializada - Startup directo');
    // Zero overhead - directo a UI
  }
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

    // ✅ CAMBIO: Solo inicializar providers UI (ya no sync)
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