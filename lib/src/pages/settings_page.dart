import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/simple_home_provider.dart';
import './../utils/dimens.dart';
import './../utils/colors.dart';
import '../services/notification_service.dart';
import '../widgets/notification_card_widget.dart';
import '../models/user_preferences.dart';
// 🔥 IMPORTS SOLO PARA DESARROLLADOR - ELIMINAR EN PRODUCCIÓN
import '../data/repositories/event_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/daily_task_manager.dart';
import 'package:workmanager/workmanager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<bool> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = UserPreferences.getNotificationsReady();
  }
  static const Map<String, Map<String, String>> _settingsUiDisplay = {
    'musica': {'label': 'Música', 'emoji': '🎶'},
    'teatro': {'label': 'Teatro', 'emoji': '🎭'},
    'standup': {'label': 'StandUp', 'emoji': '😂'},
    'arte': {'label': 'Arte', 'emoji': '🎨'},
    'cine': {'label': 'Cine', 'emoji': '🎬'},
    'mic': {'label': 'Mic', 'emoji': '🎤'},
    'cursos': {'label': 'Cursos', 'emoji': '🛠️'},
    'ferias': {'label': 'Ferias', 'emoji': '🏬'},
    'calle': {'label': 'Calle', 'emoji': '🌆'},
    'redes': {'label': 'Redes', 'emoji': '🤝'},
    'ninos': {'label': 'Niños', 'emoji': '👧'},
    'danza': {'label': 'Danza', 'emoji': '🩰'},
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleHomeProvider>(
      builder: (context, provider, child) {
        final List<String> rawCategories = [
          'musica', 'teatro', 'standup', 'arte', 'cine', 'mic',
          'cursos', 'ferias', 'calle', 'redes', 'ninos', 'danza'
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Configuración'),
            centerTitle: true,
            toolbarHeight: 40.0,
            elevation: 2.0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            children: [
              // ========== CARD 1: TEMAS ==========
              Card(
                elevation: AppDimens.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tema de la app',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppDimens.paddingSmall,
                        crossAxisSpacing: AppDimens.paddingSmall,
                        childAspectRatio: 2.5,
                        children: [
                          _buildThemeButton(context, provider, 'Normal', 'normal'),
                          _buildThemeButton(context, provider, 'Oscuro', 'dark'),
                          _buildThemeButton(context, provider, 'Sepia', 'sepia'),
                          _buildThemeButton(context, provider, 'Pastel', 'pastel'),
                          _buildThemeButton(context, provider, 'Harmony', 'harmony'),
                          _buildThemeButton(context, provider, 'Fluor', 'fluor'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ========== CARD 1.5: NOTIFICACIONES ==========
              const SizedBox(height: AppDimens.paddingMedium),
              const NotificationCard(),

              // ========== CARD 2: CATEGORÍAS ==========
              const SizedBox(height: AppDimens.paddingMedium),
              Card(
                elevation: AppDimens.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categorías favoritas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      Text(
                        'Seleccioná las categorías que te interesan. Todas están activas por defecto.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppDimens.paddingSmall,
                        crossAxisSpacing: AppDimens.paddingSmall,
                        childAspectRatio: 4.5,
                        children: rawCategories.map((rawCategory) {
                          final uiData = _settingsUiDisplay[rawCategory]!;
                          final isSelected = provider.selectedCategories.contains(rawCategory);
                          final color = EventCardColorPalette.getOptimizedColors(provider.theme, rawCategory).base;
                          return _buildCategoryButton(
                            context,
                            provider,
                            rawCategory,
                            uiData['label']!,
                            uiData['emoji']!,
                            color,
                            isSelected,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: provider.resetCategories,
                          child: const Text('Restablecer selección'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ========== CARD 3: GESTIÓN DE DATOS ==========
              const SizedBox(height: AppDimens.paddingMedium),
              Card(
                elevation: AppDimens.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚙️ Gestión de Datos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCleanupColumn(
                              context,
                              provider,
                              'Eventos vencidos',
                              [2, 3, 7, 10],
                              provider.eventCleanupDays,
                              true, // isEvents
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 160,
                            color: Theme.of(context).colorScheme.outline.withAlpha(77),
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppDimens.paddingMedium,
                            ),
                          ),
                          Expanded(
                            child: _buildCleanupColumn(
                              context,
                              provider,
                              'Favoritos vencidos',
                              [3, 7, 10, 30],
                              provider.favoriteCleanupDays,
                              false, // isFavorites
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 🔥 ========== CARD 4: DESARROLLADOR ========== 🔥
              // 🔥 BLOQUE COMPLETO PARA ELIMINAR EN PRODUCCIÓN 🔥
              const SizedBox(height: AppDimens.paddingMedium),
              Card(
                elevation: AppDimens.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔧 Desarrollador',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      _buildDebugButton(
                        context,
                        'RESET PRIMERA INSTALACIÓN',
                        '🔄 Marcar app como no inicializada (4 SP keys)',
                        Colors.blue,
                            () => _resetFirstInstallation(context),
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      _buildDebugButton(
                        context,
                        'LIMPIAR BASE DE DATOS',
                        '⚠️ Borra todos los eventos guardados',
                        Colors.red,
                            () => _clearDatabase(context),
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      _buildDebugButton(
                        context,
                        'VER BASE DE DATOS',
                        '📊 Mostrar eventos guardados y estado de sync',
                        Colors.green,
                            () => _showDatabaseInfo(context),
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      _buildDebugButton(
                        context,
                        'ESTADÍSTICAS',
                        '📈 Conteo por categorías y resumen',
                        Colors.orange,
                            () => _showEventStats(context),
                      ),

                      _buildDebugButton(
                        context,
                        'TEST SYNC WM (+2MIN)',
                        '🧪 Programar one-off sync en WorkManager',
                        Colors.purple,
                            () => _testSyncWorkManager(context),  // ← Ya tienes este método
                      ),

                      _buildDebugButton(
                        context,
                        'MARCAR SYNC VENCIDA',
                        '⏰ Setear timestamp -25h para forzar recovery',
                        Colors.teal,
                            () => _markSyncExpired(context),  // ← Ya tienes este método
                      ),


                      const SizedBox(height: AppDimens.paddingSmall),
                      _buildDebugButton(
                        context,
                        'FORZAR REPROGRAMACIÓN WM',
                        '🔄 Remove daily_check + reprogram WorkManager',
                        Colors.indigo,
                            () => _forceRescheduleWorkManager(context),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
// Picker de hora para sync
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Hora Sync:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: FutureBuilder<String>(
                              future: _getSyncTime(),
                              builder: (context, snapshot) {
                                final currentTime = snapshot.data ?? '01:00';
                                return TextFormField(
                                  initialValue: currentTime,
                                  decoration: const InputDecoration(
                                    hintText: 'HH:MM',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onChanged: (value) => _setSyncTime(value),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      _buildDebugButton(
                        context,
                        'TEST NOTIFIC WM (+2MIN)',           // ← Cambio 1
                        '🧪 Programar one-off notifications en WorkManager',  // ← Cambio 2
                        Colors.purple,
                            () => _testNotificationsWorkManager(context),  // ← Cambio 3
                      ),

                      _buildDebugButton(
                        context,
                        'MARCAR NOTIFIC VENCIDA',            // ← Cambio 1
                        '⏰ Setear timestamp -25h para forzar recovery',
                        Colors.teal,
                            () => _markNotificationsExpired(context),  // ← Cambio 2
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      _buildDebugButton(
                        context,
                        'APLICAR HORARIO SYNC',
                        '⏰ Usar hora del picker para reprogramar WM',
                        Colors.teal,
                            () => _applySyncSchedule(context),
                      ),
                    ],
                  ),
                ),
              ),
              // 🔥 FIN CARD DESARROLLADOR - ELIMINAR HASTA AQUÍ 🔥
            ],
          ),
        );
      },
    );
  }

  // ========== MÉTODOS EXISTENTES ==========
  Widget _buildThemeButton(
      BuildContext context,
      SimpleHomeProvider provider,
      String label,
      String theme,
      ) {
    final isSelected = provider.theme == theme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => provider.setTheme(theme),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
      BuildContext context,
      SimpleHomeProvider provider,
      String rawCategory,
      String displayName,
      String emoji,
      Color color,
      bool isSelected,
      ) {
    bool isLightColor(Color color) {
      return color.computeLuminance() > 0.5;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Material(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await provider.toggleCategory(rawCategory);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.black,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: isSelected
                              ? (isLightColor(color)
                              ? Colors.black
                              : Colors.white)
                              : Colors.black,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check,
                        size: 14,
                        color:
                        isLightColor(color) ? Colors.black : Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== MÉTODOS CARD 3: GESTIÓN DE DATOS ==========
  Widget _buildCleanupColumn(
      BuildContext context,
      SimpleHomeProvider provider,
      String title,
      List<int> options,
      int currentValue,
      bool isEvents,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.paddingSmall),
        ...options
            .map(
              (days) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.paddingSmall),
            child: _buildCleanupButton(
              context,
              provider,
              days,
              currentValue,
              isEvents,
            ),
          ),
        )
            .toList(),
      ],
    );
  }

  Widget _buildCleanupButton(
      BuildContext context,
      SimpleHomeProvider provider,
      int days,
      int currentValue,
      bool isEvents,
      ) {
    final isSelected = days == currentValue;

    return SizedBox(
      width: double.infinity,
      height: 32,
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (isEvents) {
              provider.setEventCleanupDays(days);
            } else {
              provider.setFavoriteCleanupDays(days);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$days días después',
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
// ========== MÉTODOS CARD 1.5: NOTIFICACIONES ==========
  Future<Map<String, dynamic>> _getNotificationStatus() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidImplementation = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? areEnabled = await androidImplementation?.areNotificationsEnabled();

      if (areEnabled == true) {
        return {
          'enabled': true,
          'text': 'Notificaciones activadas',
          'icon': '✅',
          'buttonText': 'Configurado correctamente',
          'buttonEnabled': false,
        };
      } else {
        return {
          'enabled': false,
          'text': 'Notificaciones desactivadas',
          'icon': '⚠️',
          'buttonText': 'Activar notificaciones',
          'buttonEnabled': true,
        };
      }
    } catch (e) {
      return {
        'enabled': false,
        'text': 'Error verificando estado',
        'icon': '❓',
        'buttonText': 'Reintentar',
        'buttonEnabled': true,
      };
    }
  }
  Future<void> _handleNotificationAction(BuildContext context) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidImplementation = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();

      if (granted == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Permisos concedidos')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Permisos denegados')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // 🔥 ========== MÉTODOS CARD 4: DESARROLLADOR ========== 🔥
  // 🔥 ELIMINAR TODOS ESTOS MÉTODOS EN PRODUCCIÓN 🔥
  Widget _buildDebugButton(
      BuildContext context,
      String title,
      String subtitle,
      Color color,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: color.withAlpha(179), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetFirstInstallation(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Reseteando primera instalación...')),
      );

      final prefs = await SharedPreferences.getInstance();

      // Borrar las keys principales
      await prefs.remove('first_install_completed');
      print('🔄 Flag primera instalación borrado');
      await prefs.remove('last_sync_timestamp');
      await prefs.remove('last_notification_timestamp');
      await prefs.remove('workmanager_daily_check');
      await prefs.setBool('app_initialized', false);

      print('🔄 Flag primera instalación borrado');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reset completo - Mata app y abre para probar primera instalación'),
          duration: Duration(seconds: 4),
        ),
      );

      print('🧪 RESET: App marcada como no inicializada');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error en reset: $e')),
      );
    }
  }

  Future<void> _clearDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Limpiar Base de Datos'),
          content: const Text(
            '¿Estás seguro? Se borrarán todos los eventos guardados. Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Borrar Todo'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final repository = EventRepository();
        await repository.clearAllData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Base de datos limpiada')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error limpiando: $e')),
        );
      }
    }
  }

  Future<void> _showDatabaseInfo(BuildContext context) async {
    try {
      final repository = EventRepository();
      final eventos = await repository.getAllEvents();
      final syncInfo = await repository.getSyncInfo();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 Estado de la Base de Datos'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📦 Total eventos: ${eventos.length}'),
                Text(
                  '🕐 Última sync: ${syncInfo?['last_sync'] ?? 'Nunca'}',
                ),
                Text(
                  '🏷️ Versión lote: ${syncInfo?['batch_version'] ?? 'N/A'}',
                ),
                const SizedBox(height: 16),
                const Text(
                  '📋 Últimos 5 eventos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...eventos
                    .take(5)
                    .map(
                      (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${e['title']} (${e['date']})'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _showEventStats(BuildContext context) async {
    try {
      final repository = EventRepository();
      final eventos = await repository.getAllEvents();
      final favoritos = await repository.getAllFavorites();

      final stats = <String, int>{};
      for (var evento in eventos) {
        final tipo = evento['type'] ?? 'sin_tipo';
        stats[tipo] = (stats[tipo] ?? 0) + 1;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📈 Estadísticas'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📊 Total eventos: ${eventos.length}'),
                Text('⭐ Favoritos: ${favoritos.length}'),
                const SizedBox(height: 16),
                const Text(
                  '📋 Por categoría:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...stats.entries.map(
                      (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${entry.key}: ${entry.value} eventos'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  // Justo después de _showEventStats() y antes de los comentarios finales:

  Future<void> _testSyncWorkManager(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🧪 Programando test sync WM en +2min...')),
      );

      // Programar one-off task que se ejecuta en 2 minutos
      await Workmanager().registerOneOffTask(
        'test-sync-wm',
        'daily-sync',  // Usa el mismo callback que sync real
        initialDelay: const Duration(minutes: 2),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Test sync programado - Ejecutará en 2 minutos'),
          duration: Duration(seconds: 4),
        ),
      );

      print('🧪 TEST WM: One-off sync task programada para +2min');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error programando test: $e')),
      );
      print('🧪 ERROR TEST WM: $e');
    }
  }

  Future<void> _markSyncExpired(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏰ Marcando sync como vencida...')),
      );

      await DailyTaskManager().markTaskAsExpired(TaskType.sync);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sync marcada como vencida - Mata app y abre para probar recovery'),
          duration: Duration(seconds: 4),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error marcando sync vencida: $e')),
      );
      print('❌ ERROR EXPIRED: $e');
    }
  }

  Future<void> _forceRescheduleWorkManager(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Forzando reprogramación WM...')),
      );

      final prefs = await SharedPreferences.getInstance();

      // Remove la key que previene reprogramación diaria
      await prefs.remove('workmanager_daily_check');

      // Llamar al método de testing del DailyTaskManager
      await DailyTaskManager().testRescheduleWorkManager();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ WorkManager reprogramado forzosamente'),
          duration: Duration(seconds: 3),
        ),
      );

      print('🧪 REPROGRAM: workmanager_daily_check removida + WM reprogramado');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error reprogramando WM: $e')),
      );
      print('❌ ERROR REPROGRAM: $e');
    }
  }

  Future<String> _getSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('wm_sync_hour') ?? 1;
    final minute = prefs.getInt('wm_sync_min') ?? 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _setSyncTime(String timeString) async {
    try {
      // Limpiar string
      timeString = timeString.trim();
      if (timeString.isEmpty) return;

      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? -1;  // ← tryParse es más seguro
        final minute = int.tryParse(parts[1]) ?? -1;

        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('wm_sync_hour', hour);
          await prefs.setInt('wm_sync_min', minute);
          print('✅ Hora sync actualizada: ${timeString}');
        } else {
          print('⚠️ Hora inválida: $timeString (debe ser HH:MM, 00-23:00-59)');
        }
      }
    } catch (e) {
      print('❌ Error parseando hora: $e');
    }
  }

  Future<void> _applySyncSchedule(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏰ Aplicando horario personalizado...')),
      );

      // Forzar reprogramación con nueva hora
      await _forceRescheduleWorkManager(context);

      final currentTime = await _getSyncTime();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Sync reprogramado para las $currentTime'),
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error aplicando horario: $e')),
      );
    }
  }
  Future<void> _testNotificationsWorkManager(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔔 Programando test de notificaciones en +2min...')),
      );

      await Workmanager().registerOneOffTask(
        'test-notifications-wm',
        'daily-notifications',
        initialDelay: const Duration(minutes: 2),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Test de notificaciones programado - Ejecutará en 2 minutos'),
          duration: Duration(seconds: 4),
        ),
      );

      print('🔔 TEST WM: One-off de notificaciones programado para +2min');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error programando test de notificaciones: $e')),
      );
      print('❌ ERROR TEST NOTIFICATIONS WM: $e');
    }
  }


  Future<void> _markNotificationsExpired(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ Marcando notificaciones como vencidas...')),
      );

      await DailyTaskManager().markTaskAsExpired(TaskType.notifications);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notificaciones marcadas como vencidas - Mata app y abre para probar recovery'),
          duration: Duration(seconds: 4),
        ),
      );

      print('✅ EXPIRED: Notificaciones marcadas como vencidas');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error marcando notificaciones vencidas: $e')),
      );
      print('❌ ERROR EXPIRED NOTIFICATIONS: $e');
    }
  }

// 🔥 FIN MÉTODOS DESARROLLADOR - ELIMINAR HASTA AQUÍ 🔥
}

// 🔥 ========== INSTRUCCIONES PARA PRODUCCIÓN ========== 🔥
//
// Para eliminar la Card de Desarrollador en producción:
//
// 1. **ELIMINAR IMPORTS** (líneas 6-7):
//    - import '../services/sync_service.dart';
//    - import '../data/repositories/event_repository.dart';
//
// 2. **ELIMINAR CARD COMPLETA** (buscar comentarios 🔥):
//    - Desde: "// 🔥 ========== CARD 4: DESARROLLADOR ========== 🔥"
//    - Hasta: "// 🔥 FIN CARD DESARROLLADOR - ELIMINAR HASTA AQUÍ 🔥"
//
// 3. **ELIMINAR MÉTODOS** (buscar comentarios 🔥):
//    - Desde: "// 🔥 ========== MÉTODOS CARD 4: DESARROLLADOR ========== 🔥"
//    - Hasta: "// 🔥 FIN MÉTODOS DESARROLLADOR - ELIMINAR HASTA AQUÍ 🔥"
//
// 4. **ELIMINAR ESTOS COMENTARIOS** completos al final del archivo
//
// ✅ **MANTENER**: Cards 1, 2, 3 y sus métodos asociados
// ❌ **ELIMINAR**: Todo lo marcado con 🔥
/*🔥 LO QUE SÍ SE ELIMINA:
Solo el código dentro de settings_page.dart:

Los imports de SyncService y EventRepository y shared_preferences.dart'

La Card 4 completa (HTML/UI)
Los 4 métodos helper (_buildDebugButton, _forceSyncDatabase,
_clearDatabase, _showDatabaseInfo, _showEventStats)
 */