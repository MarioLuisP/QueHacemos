// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'src/providers/favorites_provider.dart';
import 'src/providers/simple_home_provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/themes/themes.dart';
import 'src/navigation/bottom_nav.dart';
import 'src/providers/notifications_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'src/services/daily_task_manager.dart';
import 'src/services/first_install_service.dart'; // 🆕 NUEVO IMPORT
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/sync/sync_service.dart';
import 'src/models/user_preferences.dart';
import 'src/services/notification_service.dart';
import 'src/services/notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['action'] == 'daily_recovery') {
    print("Data message recibido - ejecutando recovery directamente");

    try {
      await NotificationManager().executeRecovery();
      print("Recovery ejecutado exitosamente desde background");
    } catch (e) {
      print("Error ejecutando recovery desde background: $e");
    }
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_ES';
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // NUEVO: Inicializar autenticación anónima
  await _initializeAnonymousAuth();

  tz.initializeTimeZones();

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

class _AppContentState extends State<_AppContent> with WidgetsBindingObserver {
  bool _isInitialized = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuthInBackground();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Solo verificar flag permanente - sin tracking manual
      final firstInstallService = FirstInstallService();
      final needsFirstInstall = await firstInstallService.needsFirstInstall();

      if (needsFirstInstall) {
        print('🚀 Primera instalación detectada - ejecutando FirstInstallService...');
        // Ejecutar y olvidar - FirstInstallService maneja todo
        await firstInstallService.performFirstInstall();
      }

      // Inicialización normal unificada
      await _performNormalInitialization();

    } catch (e) {
      print('❌ Error en inicialización: $e');
      // Continuar con inicialización normal como fallback
      await _performNormalInitialization();
    }
  }

  // 🆕 NUEVO: Inicialización normal (código existente separado)
  Future<void> _performNormalInitialization() async {
    //NotificationService.initialize();
    final simpleHomeProvider = Provider.of<SimpleHomeProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    try {
      await simpleHomeProvider.initialize();
      await favoritesProvider.init();
    // Programar inicialización de notificaciones DESPUÉS del primer frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final isConfigured = await UserPreferences.getNotificationsReady();
        if (isConfigured) {
          await NotificationService.initialize();
          print('Notificaciones inicializadas en background - sistema listo');
        }
      });

      final dailyTaskManager = DailyTaskManager();
      await dailyTaskManager.initialize();
      // ⌛ REMOVER: DailyTaskManager().checkOnAppOpen();

      simpleHomeProvider.setupFavoritesSync(favoritesProvider);
      SyncService().setHomeProvider(simpleHomeProvider);
      setState(() {
        _isInitialized = true;
      });

      // ✅ AGREGAR: Ejecutar después del build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🔧 Ejecutando DailyTaskManager recovery check...');
        DailyTaskManager().checkOnAppOpen();
        print('🔔 Ejecutando NotificationManager recovery check...');
        NotificationManager().checkOnAppOpen(); // ← ESTA LÍNEA
      });

      print('🎉 App completamente inicializada');
    } catch (e) {
      print('⌛ Error crítico en inicialización: $e');
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DailyTaskManager().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      DailyTaskManager().checkOnAppOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
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