import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/simple_home_provider.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart'; // NUEVO: import nuevo provider
import './../utils/dimens.dart';
import './../utils/colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SimpleHomeProvider, PreferencesProvider>( // CAMBIO: Consumer2 para ambos providers
      builder: (context, homeProvider, preferencesProvider, child) { // CAMBIO: ahora recibe ambos providers
        final List<Map<String, dynamic>> categories = [
          {'name': 'Música', 'emoji': '🎶', 'color': AppColors.musica},
          {'name': 'Teatro', 'emoji': '🎭', 'color': AppColors.teatro},
          {'name': 'StandUp', 'emoji': '😂', 'color': AppColors.standup},
          {'name': 'Arte', 'emoji': '🎨', 'color': AppColors.arte},
          {'name': 'Cine', 'emoji': '🎬', 'color': AppColors.cine},
          {'name': 'Mic', 'emoji': '🎤', 'color': AppColors.mic},
          {'name': 'Cursos', 'emoji': '🛠️', 'color': AppColors.cursos},
          {'name': 'Ferias', 'emoji': '🏬', 'color': AppColors.ferias},
          {'name': 'Calle', 'emoji': '🌆', 'color': AppColors.calle},
          {'name': 'Redes', 'emoji': '🤝', 'color': AppColors.redes},
          {'name': 'Niños', 'emoji': '👧', 'color': AppColors.ninos},
          {'name': 'Danza', 'emoji': '🩰', 'color': AppColors.danza},
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
                          _buildThemeButton(context, preferencesProvider, 'Normal', 'normal'), // CAMBIO: usa preferencesProvider
                          _buildThemeButton(context, preferencesProvider, 'Oscuro', 'dark'),   // CAMBIO: usa preferencesProvider
                          _buildThemeButton(context, preferencesProvider, 'Sepia', 'sepia'),   // CAMBIO: usa preferencesProvider
                          _buildThemeButton(context, preferencesProvider, 'Pastel', 'pastel'), // CAMBIO: usa preferencesProvider
                          _buildThemeButton(context, preferencesProvider, 'Harmony', 'harmony'), // CAMBIO: usa preferencesProvider
                          _buildThemeButton(context, preferencesProvider, 'Fluor', 'fluor'),   // CAMBIO: usa preferencesProvider
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
                        children: categories.map((category) {
                          final isSelected = homeProvider.selectedCategories // CAMBIO: sigue usando homeProvider para categorías
                              .contains(category['name']);
                          final color = AppColors.adjustForTheme(
                            context,
                            category['color'] as Color,
                          );

                          return _buildCategoryButton(
                            context,
                            homeProvider, // CAMBIO: sigue usando homeProvider para categorías
                            category['name'] as String,
                            category['emoji'] as String,
                            color,
                            isSelected,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: homeProvider.resetCategories, // CAMBIO: sigue usando homeProvider para categorías
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
      PreferencesProvider preferencesProvider, // CAMBIO: tipo específico PreferencesProvider
      String label,
      String theme,
      ) {
    final isSelected = preferencesProvider.theme == theme; // CAMBIO: usa preferencesProvider.theme

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
          onTap: () => preferencesProvider.setTheme(theme), // CAMBIO: usa preferencesProvider.setTheme
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
      SimpleHomeProvider homeProvider, // MANTIENE: SimpleHomeProvider para categorías
      String name,
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
            await homeProvider.toggleCategory(name); // MANTIENE: homeProvider para categorías
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
                        name,
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