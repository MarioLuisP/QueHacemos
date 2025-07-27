import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/simple_home_provider.dart';
import 'package:quehacemos_cba/src/widgets/chips/event_chip_widget.dart';

class FilterChipsRow extends StatefulWidget {
  final List<String> availableCategories;
  final Set<String> activeCategories;
  final Function(String) onToggleCategory;
  final VoidCallback onClearAll;
  final String? currentTheme; // Para pasar a los chips

  const FilterChipsRow({
    super.key,
    required this.availableCategories,
    required this.activeCategories,
    required this.onToggleCategory,
    required this.onClearAll,
    this.currentTheme,
  });

  @override
  State<FilterChipsRow> createState() => _FilterChipsRowState();
}

class _FilterChipsRowState extends State<FilterChipsRow> {
  // Cache para evitar reconstruir la lista de chips constantemente
  List<String>? _cachedCategories;
  Set<String>? _lastActiveFilters;

  @override
  Widget build(BuildContext context) {
    final currentActiveFilters = widget.activeCategories;
    final currentCategories = widget.availableCategories.isEmpty
        ? ['musica', 'teatro', 'cine', 'standup'] // Fallback por defecto
        : widget.availableCategories;

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
        _RefreshButton(onClear: widget.onClearAll),

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
  }

  List<Widget> _buildCategoryChips(BuildContext context, List<String> categories) {
    return categories.map((category) {
      return Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: EventChipWidget(
          category: category,
          isSelected: widget.activeCategories.contains(category),
          onTap: () => widget.onToggleCategory(category),
          currentTheme: widget.currentTheme,
          key: ValueKey(category),
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
  final VoidCallback onClear;

  const _RefreshButton({required this.onClear});

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
            onTap: onClear,
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