import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:quehacemos_cba/src/utils/styles.dart';
import 'package:quehacemos_cba/src/utils/colors.dart';

// NUEVO: Mapeo exclusivo para UI de chips (sin emoji, cortos)
const Map<String, String> _chipLabels = {
  'musica': 'Música',
  'teatro': 'Teatro',
  'standup': 'StandUp',
  'arte': 'Arte',
  'cine': 'Cine',
  'mic': 'Mic',
  'cursos': 'Cursos',
  'ferias': 'Ferias',
  'calle': 'Calle',
  'redes': 'Redes',
  'ninos': 'Niños',
  'danza': 'Danza',
};

class EventChipWidget extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;
  final String? currentTheme; // Para obtener colores, null = auto-detect

  const EventChipWidget({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Obtener theme: usar parámetro o detectar automáticamente
    final theme = currentTheme ?? (isDark ? 'dark' : 'normal');

    final colors = EventCardColorPalette.getOptimizedColors(theme, category);
    final inactiveBackground = isDark ? Colors.black : Colors.white;
    final inactiveTextColor = isDark ? Colors.white : Colors.black;

    return ChipTheme(
      data: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        ),
        backgroundColor: Colors.transparent,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? colors.base : inactiveBackground,
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
          border: Border.all(
            color: isSelected ? colors.base : inactiveTextColor,
            width: 0.5,
          ),
        ),
        height: AppDimens.chipHeight,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  Text(
                    _chipLabels[category] ?? category,
                    style: AppStyles.chipLabel.copyWith(
                      color: isSelected ? AppColors.textDark : inactiveTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}