// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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
  //await NotificationService.initialize();

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

  // 🆕 NUEVO: Estado para primera instalación
  bool _isFirstInstallCompleted = false;
  bool _isFirstInstallRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuthInBackground();
    });
  }

  // 🆕 NUEVO: Método principal de inicialización con FirstInstallService
  Future<void> _initializeApp() async {
    try {
      // 🆕 PASO 1: Verificar si necesita primera instalación
      final firstInstallService = FirstInstallService();
      final needsFirstInstall = await firstInstallService.needsFirstInstall();

      if (needsFirstInstall) {
        print('🚀 Primera instalación detectada - ejecutando FirstInstallService...');
        setState(() {
          _isFirstInstallRunning = true;
        });

        // 🆕 Ejecutar primera instalación completa
        final result = await firstInstallService.performFirstInstall();

        if (result.success) {
          print('✅ Primera instalación completada exitosamente');
          setState(() {
            _isFirstInstallCompleted = true;
            _isFirstInstallRunning = false;
          });
        } else {
          print('❌ Primera instalación falló: ${result.error}');
          setState(() {
            _isFirstInstallRunning = false;
          });
          // Continuar con flujo normal aunque haya fallado
        }
      } else {
        print('✅ Primera instalación ya completada previamente');
        setState(() {
          _isFirstInstallCompleted = true;
        });
      }

      // 🆕 PASO 2: Inicialización normal (como siempre)
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

      final dailyTaskManager = DailyTaskManager();
      await dailyTaskManager.initialize();
      // ⌛ REMOVER: DailyTaskManager().checkOnAppOpen();

      simpleHomeProvider.setupFavoritesSync(favoritesProvider);

      setState(() {
        _isInitialized = true;
      });

      // ✅ AGREGAR: Ejecutar después del build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dailyTaskManager.checkOnAppOpen();
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
    // 🆕 NUEVO: Mostrar loading específico durante primera instalación
    if (_isFirstInstallRunning) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.blueGrey[50],
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
                SizedBox(height: 24),
                Text(
                  '🎭 Configurando eventos de Córdoba...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple[700],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Descargando contenido inicial',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    // 🆕 NUEVO: Loading normal para el resto de la inicialización
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                if (_isFirstInstallCompleted) ...[
                  SizedBox(height: 16),
                  Text(
                    '✅ Configuración completada',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ]
              ],
            ),
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