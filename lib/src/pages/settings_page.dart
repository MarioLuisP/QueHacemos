import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/simple_home_provider.dart';
import './../utils/dimens.dart';
import './../utils/colors.dart';
import '../widgets/notification_card_widget.dart';
import '../models/user_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

// 🔥 FIN MÉTODOS DESARROLLADOR - ELIMINAR HASTA AQUÍ 🔥
}
