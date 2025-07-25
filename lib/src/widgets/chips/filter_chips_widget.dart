import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // NUEVO: agregar provider import
import 'package:quehacemos_cba/src/providers/simple_home_provider.dart'; // NUEVO: cambio de provider
import 'package:quehacemos_cba/src/widgets/chips/event_chip_widget.dart';

class FilterChipsRow extends StatefulWidget {
  // CAMBIO: Sin parámetros - obtiene provider internamente
  const FilterChipsRow({super.key}); // CAMBIO: constructor simplificado

  @override
  State<FilterChipsRow> createState() => _FilterChipsRowState();
}

class _FilterChipsRowState extends State<FilterChipsRow> {
  // Cache para evitar reconstruir la lista de chips constantemente
  List<String>? _cachedCategories;
  Set<String>? _lastActiveFilters;

  @override
  Widget build(BuildContext context) {
    // NUEVO: Obtener provider internamente
    return Consumer<SimpleHomeProvider>(
      builder: (context, provider, child) {
        // CAMBIO: Usar provider local en lugar de widget.prefs
        final currentActiveFilters = provider.activeFilterCategories; // CAMBIO
        final currentCategories = provider.selectedCategories.isEmpty
            ? ['musica', 'teatro', 'cine', 'standup'] // ← RAW
            : provider.selectedCategories.toList();

        final shouldRebuildChips = _cachedCategories == null ||
            !_listEquals(_cachedCategories!, currentCategories) ||
            _lastActiveFilters == null ||
            !_setEquals(_lastActiveFilters!, currentActiveFilters);

        if (shouldRebuildChips) {
          _cachedCategories = currentCategories;
          _lastActiveFilters = Set.from(currentActiveFilters);
        }

        return Row(
          children: [
            // Botón Refresh / Limpiar Filtros (Fijo)
            _RefreshButton(provider: provider), // CAMBIO: solo pasar provider

            // Chips dinámicos (Scroll horizontal)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: shouldRebuildChips
                      ? _buildCategoryChips(context, currentCategories)
                      : _buildCategoryChips(context, _cachedCategories!),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCategoryChips(BuildContext context, List<String> categories) {
    return categories.map((category) {
      return Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: EventChipWidget(
          category: category,
          key: ValueKey(category), // Key para mejor reutilización
        ),
      );
    }).toList();
  }

  // Utilidades para comparar listas y sets eficientemente
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

// Widget separado para el botón refresh - evita rebuilds innecesarios
class _RefreshButton extends StatelessWidget {
  final SimpleHomeProvider provider; // CAMBIO: Solo SimpleHomeProvider

  const _RefreshButton({required this.provider}); // CAMBIO: constructor simplificado

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: SizedBox(
        height: 40,
        width: 40,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          elevation: 2,
          child: InkWell(
            onTap: () {
              // CAMBIO: Solo un método en lugar de 2
              provider.clearActiveFilterCategories(); // CAMBIO: método unificado
            },
            borderRadius: BorderRadius.circular(24),
            child: Icon(
              Icons.refresh,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }
}