import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';
import 'package:quehacemos_cba/src/utils/colors.dart';
import '../widgets/cards/event_card_widget.dart';
import '../cache/cache_models.dart';
import '../navigation/bottom_nav.dart';

class DateEventsPage extends StatefulWidget {
  final DateTime selectedDate;

  const DateEventsPage({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DateEventsPage> createState() => _DateEventsPageState();
}

class _DateEventsPageState extends State<DateEventsPage> {
  late SimpleHomeProvider _provider;

  // NUEVO: Filtros locales independientes del provider global
  Set<String> _localActiveCategories = {};

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<SimpleHomeProvider>(context, listen: false);

    // NUEVO: Limpiar filtros globales al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearGlobalFilters();
    });
  }

  // NUEVO: Limpiar filtros globales para mostrar TODOS los eventos del día
  Future<void> _clearGlobalFilters() async {
    await _provider.clearActiveFilterCategories();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          Navigator.pop(context, widget.selectedDate);
        }
      },
      child: Consumer<SimpleHomeProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Eventos - ${_formatDate(widget.selectedDate)}'),
              centerTitle: true,
              toolbarHeight: 40.0,
              elevation: 2.0,
            ),
            body: Column(
              children: [
                // MODIFICADO: FilterChips que manejan filtros locales
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: _buildLocalFilterChips(provider),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.errorMessage != null
                      ? Center(child: Text('Error: ${provider.errorMessage}'))
                      : _buildDateEventsList(provider),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          );
        },
      ),
    );
  }

  // NUEVO: FilterChips locales que replican exactamente el estilo de explore
  Widget _buildLocalFilterChips(SimpleHomeProvider provider) {
    final currentCategories = provider.selectedCategories.isEmpty
        ? ['musica', 'teatro', 'cine', 'standup'] // Default como en explore
        : provider.selectedCategories.toList();

    return Row(
      children: [
        // Botón Refresh / Limpiar Filtros (idéntico al de explore)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: SizedBox(
            height: 30,
            width: 40,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
              elevation: 2,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _localActiveCategories.clear();
                  });
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
        ),

        // Chips scrolleables (idéntico al de explore)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: currentCategories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: _buildLocalEventChip(category),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // NUEVO: EventChip local que replica el comportamiento exacto
  Widget _buildLocalEventChip(String category) {
    final provider = Provider.of<SimpleHomeProvider>(context);
    final isSelected = _localActiveCategories.contains(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final theme = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'normal';

    final colors = EventCardColorPalette.getOptimizedColors(theme, category);
    final adjustedColor = colors.base;
    final inactiveBackground = isDark ? Colors.black : Colors.white;
    final inactiveTextColor = isDark ? Colors.white : Colors.black;
    final inactiveBorderColor = inactiveTextColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 28.0, //
      decoration: BoxDecoration(
        color: isSelected ? colors.base : inactiveBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isSelected ? colors.base : inactiveBackground,
          width: 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          setState(() {
            if (isSelected) {
              _localActiveCategories.remove(category);
            } else {
              _localActiveCategories.add(category);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 4.0),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              Text(
                _getChipLabel(category),
                style: TextStyle(
                  color: isSelected ? Colors.black : inactiveTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }



  // NUEVO: Labels para chips (mismo mapeo que explore)
  String _getChipLabel(String category) {
    const chipLabels = {
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
    return chipLabels[category] ?? category;
  }

  // MODIFICADO: Aplicar filtros locales en lugar de globales
  Future<List<EventCacheItem>> _getFilteredEventsForDate(SimpleHomeProvider provider) async {
    // SIEMPRE obtener TODOS los eventos del día
    final allEventsForDate = await provider.getEventsForDate(widget.selectedDate);

    // Aplicar filtros LOCALES (no globales)
    if (_localActiveCategories.isEmpty) {
      return allEventsForDate; // Mostrar todos si no hay filtros locales
    }

    return allEventsForDate.where((event) {
      return _localActiveCategories.contains(event.type.toLowerCase());
    }).toList();
  }

  Widget _buildDateEventsList(SimpleHomeProvider provider) {
    return FutureBuilder<List<EventCacheItem>>(
      future: _getFilteredEventsForDate(provider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final eventsForDate = snapshot.data ?? [];

        if (eventsForDate.isEmpty) {
          final hasLocalFilters = _localActiveCategories.isNotEmpty;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasLocalFilters
                      ? 'No hay eventos de las categorías seleccionadas para esta fecha.'
                      : 'No hay eventos para esta fecha.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (hasLocalFilters) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _localActiveCategories.clear();
                      });
                    },
                    child: const Text('Ver todos los eventos'),
                  ),
                ],
              ],
            ),
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // NUEVO: Header con información de filtros
            if (_localActiveCategories.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    'Mostrando ${eventsForDate.length} eventos de ${_localActiveCategories.length} categoría${_localActiveCategories.length > 1 ? 's' : ''} seleccionada${_localActiveCategories.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            SliverFixedExtentList(
              itemExtent: 253.0,
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: EventCardWidget(
                      event: eventsForDate[index],
                      provider: provider,
                      key: ValueKey(eventsForDate[index].id),
                    ),
                  );
                },
                childCount: eventsForDate.length,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
      ],
      onTap: (index) {
        if (index == 2) {
          Navigator.pop(context);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainScreen(initialIndex: index),
            ),
                (route) => false,
          );
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Hoy';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Mañana';
    } else {
      return '${weekdays[date.weekday]} ${date.day} ${months[date.month]}';
    }
  }

}