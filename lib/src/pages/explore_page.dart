import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/widgets/chips/filter_chips_widget.dart';
import 'package:quehacemos_cba/src/widgets/cards/fast_event_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  // 🚀 OPTIMIZACIÓN: Variables para evitar rebuilds innecesarios
  Set<String> _lastAppliedFilters = {};

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.initialize();
    _searchController.addListener(() {
      _viewModel.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  // 🎯 FUNCIÓN DE OPTIMIZACIÓN: Chequea si realmente necesitamos aplicar filtros
  bool _needsFilterUpdate(Set<String> currentFilters) {
    if (_lastAppliedFilters.length != currentFilters.length) return true;
    for (String filter in currentFilters) {
      if (!_lastAppliedFilters.contains(filter)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _viewModel)],
      child: Consumer2<HomeViewModel, PreferencesProvider>(
        builder: (context, viewModel, prefs, _) {
          // 🔥 OPTIMIZACIÓN: Solo aplicar filtros cuando REALMENTE cambien
          if (_needsFilterUpdate(prefs.activeFilterCategories)) {
            _lastAppliedFilters = Set.from(prefs.activeFilterCategories);
            // ✅ CORREGIDO: Diferir la actualización para evitar setState durante build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              viewModel.applyCategoryFilters(prefs.activeFilterCategories);
            });
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('Explorar Eventos'),
              centerTitle: true,
              toolbarHeight: 40.0,
              elevation: 2.0,
            ),
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
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.primary,
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

                // Fila de chips + refresh
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FilterChipsRow(prefs: prefs, viewModel: viewModel),
                ),

                const SizedBox(height: 8.0),

                // ✅ CORREGIDO: Lista optimizada SIN headers usando filteredEvents
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : viewModel.hasError
                      ? Center(
                    child: Text('Error: ${viewModel.errorMessage}'),
                  )
                      : viewModel.filteredEvents.isEmpty
                      ? const Center(child: Text('No hay eventos.'))
                      : _buildOptimizedEventsList(viewModel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ CORREGIDO: Método optimizado usando filteredEvents (SIN headers)
  Widget _buildOptimizedEventsList(HomeViewModel viewModel) {
    // ✅ USAR: filteredEvents en lugar de getFlatItemsForHomePage
    final limitedEvents = viewModel.filteredEvents.take(20).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 8.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final event = limitedEvents[index];

                // ✅ SOLO tarjetas con altura fija - SIN headers
                return SizedBox(
                  height: 230.0, // ✅ Altura fija optimizada
                  child: FastEventCard(
                    event: event,
                    key: ValueKey(event['id']),
                    viewModel: viewModel,
                  ),
                );
              },
              childCount: limitedEvents.length,
            ),
          ),
        ),
      ],
    );
  }
}