// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/providers/favorites_provider.dart';
import 'src/providers/simple_home_provider.dart';
import 'src/providers/auth_provider.dart'; // NUEVO
import 'src/themes/themes.dart';
import 'src/navigation/bottom_nav.dart';
import 'src/providers/notifications_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'src/services/notification_service.dart';
import 'src/sync/sync_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_ES';
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // NUEVO: Inicializar autenticación anónima
  await _initializeAnonymousAuth();

  // Inicializar timezone
  tz.initializeTimeZones();

  // Inicializar notificaciones
  await NotificationService.initialize();

  // ✅ NUEVO: Verificar y ejecutar primera instalación
  await _ensureFirstInstallation();

  runApp(const MyApp());
}

/// NUEVO: Inicializar usuario anónimo automáticamente
Future<void> _initializeAnonymousAuth() async {
  try {
    // Solo inicialización básica aquí
    // El AuthProvider manejará el estado completo
    print('🔐 Preparando autenticación...');
  } catch (e) {
    print('⚠️ Error preparando auth: $e');
    // App continúa funcionando normal sin auth
  }
}
/// Garantizar que la primera instalación descarga los 10 lotes
/// Solo se ejecuta UNA VEZ en la vida de la app
Future<void> _ensureFirstInstallation() async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstInstall = prefs.getBool('app_initialized') ?? true;

  if (isFirstInstall) {
    print('🚀 Primera instalación detectada - Iniciando sync...');

    // CAMBIO: Solo delegación sin evaluar resultado
    SyncService().firstInstallSync(); // CAMBIO: Sin await para no bloquear

    print('✅ Sync de primera instalación iniciado en background'); // NUEVO
  } else {
    print('⚡ App ya inicializada - Startup directo');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // NUEVO: AuthProvider - Primer provider para que esté disponible para todos
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
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
    _initializeAuthInBackground(); // NUEVO: Auth no-bloqueante en background
  }

  Future<void> _initializeApp() async {
    final simpleHomeProvider = Provider.of<SimpleHomeProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    try {
      // NUEVO: Removido await authProvider.initializeAnonymousAuth() - ahora corre en background
      await simpleHomeProvider.initialize();
      await favoritesProvider.init();

      // Conectar sync entre providers
      simpleHomeProvider.setupFavoritesSync(favoritesProvider);

      setState(() {
        _isInitialized = true;
      });

      print('🎉 App completamente inicializada'); // NUEVO: Mensaje simplificado
    } catch (e) {
      print('❌ Error crítico en inicialización: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  // NUEVO: Auth inicialización no-bloqueante
  void _initializeAuthInBackground() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // NUEVO: Firebase authStateChanges ya maneja la restauración automática
    // NUEVO: Si no hay usuario, intenta anonymous (pero no bloquea la app)
    authProvider.initializeAuth();// NUEVO: Sin await - corre en background
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
        return GestureDetector(  // AGREGAR ESTO
          onTap: () => FocusScope.of(context).unfocus(),
          child: MaterialApp(
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
          ),
        );  // CERRAR GestureDetector
      },
    );
  }
}