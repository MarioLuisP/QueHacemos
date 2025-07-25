import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/simple_home_provider.dart';
import './../utils/dimens.dart';
import './../utils/colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
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
      builder: (context, provider, child) {//ahora recibe ambos providers
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
                        // NUEVO - AGREGAR:
                        children: rawCategories.map((rawCategory) {
                          final uiData = _settingsUiDisplay[rawCategory]!;
                          final isSelected = provider.selectedCategories.contains(rawCategory);
                          final color = EventCardColorPalette.getOptimizedColors(provider.theme, rawCategory).base;
                          return _buildCategoryButton(
                            context,
                            provider,
                            rawCategory,        // ← Lógica usa RAW
                            uiData['label']!,   // ← Display usa mapeo
                            uiData['emoji']!,   // ← Display usa mapeo
                            color,
                            isSelected,
                          );
                        }).toList(),

                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: provider.resetCategories, // CAMBIO: sigue usando homeProvider para categorías
                          child: const Text('Restablecer selección'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== MÉTODOS ==========
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
      String rawCategory,     // ← NUEVO: categoría para lógica
      String displayName,     // ← NUEVO: nombre para UI
      String emoji,           // ← Mismo
      Color color,            // ← Mismo
      bool isSelected,        // ← Mismo
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
            await provider.toggleCategory(rawCategory);  // ← Usa RAW para lógica
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
}