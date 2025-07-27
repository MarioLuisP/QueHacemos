import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';
import '../widgets/cards/event_card_widget.dart';
import '../widgets/chips/filter_chips_widget.dart';
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

  // NUEVO: Filtros locales independientes
  Set<String> _localActiveCategories = {};

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<SimpleHomeProvider>(context, listen: false);
  }

  // NUEVO: Toggle filtro local
  void _toggleLocalCategory(String category) {
    setState(() {
      if (_localActiveCategories.contains(category)) {
        _localActiveCategories.remove(category);
      } else {
        _localActiveCategories.add(category);
      }
    });
  }

  // NUEVO: Limpiar filtros locales
  void _clearLocalCategories() {
    setState(() {
      _localActiveCategories.clear();
    });
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
                // FilterChipsRow genérico
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: FilterChipsRow(
                    availableCategories: provider.selectedCategories.toList(),
                    activeCategories: _localActiveCategories,
                    onToggleCategory: _toggleLocalCategory,
                    onClearAll: _clearLocalCategories,
                    currentTheme: provider.theme,
                  ),
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

  // Filtrar eventos por fecha y categorías locales
  List<EventCacheItem> _getFilteredEventsForDate(SimpleHomeProvider provider) {
    // CAMBIO: Usar provider.events con themes dinámicos
    final dateString = "${widget.selectedDate.year.toString().padLeft(4, '0')}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}";
    final allEventsForDate = provider.events.where((event) =>
        event.date.startsWith(dateString)
    ).toList();

    // Aplicar filtros LOCALES (no globales)
    if (_localActiveCategories.isEmpty) {
      return allEventsForDate; // Mostrar todos si no hay filtros locales
    }

    return allEventsForDate.where((event) {
      return _localActiveCategories.contains(event.type.toLowerCase());
    }).toList();
  }

  Widget _buildDateEventsList(SimpleHomeProvider provider) {
    // CAMBIO: Llamada directa sincrónica
    final eventsForDate = _getFilteredEventsForDate(provider);

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
                onPressed: _clearLocalCategories,
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
        // Header con información de filtros
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

        // Lista de eventos
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