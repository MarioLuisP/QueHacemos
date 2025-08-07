import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/simple_home_provider.dart';
import 'package:quehacemos_cba/src/widgets/chips/filter_chips_widget.dart';
import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart';
import 'package:quehacemos_cba/src/cache/cache_models.dart';
import '../widgets/app_bars/main_app_bar.dart';


class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late SimpleHomeProvider _provider;
  final TextEditingController _searchController = TextEditingController();

  // NUEVO: Estado local para filtros (temporal, no persiste)
  Set<String> _localActiveCategories = {};

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<SimpleHomeProvider>(context, listen: false);

    _searchController.addListener(() {
      // CAMBIO: No afectar provider global, solo rebuild local
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // NUEVO: Aplicar filtros localmente sin afectar provider
  List<EventCacheItem> _getFilteredEvents() {
    final allEvents = _provider.getEventsWithoutDateFilter();

    if (_searchController.text.isEmpty && _localActiveCategories.isEmpty) {
      return allEvents.take(20).toList();
    }

    // Filtrar manualmente por búsqueda y categorías
    var filtered = allEvents;

    // Filtro por búsqueda
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((event) =>
      event.title.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.district.toLowerCase().contains(query)
      ).toList();
    }

    // Filtro por categorías
    if (_localActiveCategories.isNotEmpty) {
      filtered = filtered.where((event) =>
          _localActiveCategories.contains(event.type.toLowerCase())
      ).toList();
    }

    return filtered.take(20).toList();
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
    return Consumer<SimpleHomeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: ExploreAppBar(),
          body: Column(
            children: [
              // Campo de búsqueda
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Busca eventos (ej. payasos)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {}); // CAMBIO: Solo rebuild local
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: Colors.black, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: Colors.black, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
              ),

              // CAMBIO: FilterChipsRow con estado local
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FilterChipsRow(
                  availableCategories: provider.selectedCategories.toList(),
                  activeCategories: _localActiveCategories,
                  onToggleCategory: _toggleLocalCategory,
                  onClearAll: _clearLocalCategories,
                  currentTheme: provider.theme,
                ),
              ),

              const SizedBox(height: 8.0),

              // Lista con filtros locales aplicados
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.errorMessage != null
                    ? Center(
                  child: Text('Error: ${provider.errorMessage}'),
                )
                    : _buildOptimizedEventsList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptimizedEventsList() {
    final filteredEvents = _getFilteredEvents(); // CAMBIO: Usar filtros locales

    if (filteredEvents.isEmpty) {
      return const Center(child: Text('No hay eventos.'));
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverFixedExtentList(
          itemExtent: 253.0,
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: EventCardWidget(
                  event: filteredEvents[index],
                  provider: _provider, // CAMBIO: Usar _provider directo
                  key: ValueKey(filteredEvents[index].id),
                ),
              );
            },
            childCount: filteredEvents.length,
          ),
        ),
      ],
    );
  }
}