import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/simple_home_provider.dart'; // CAMBIO: nuevo provider
import 'package:quehacemos_cba/src/widgets/chips/filter_chips_widget.dart';
import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart'; // CAMBIO: nueva tarjeta
import '../widgets/cards/event_card_widget.dart'; // NUEVO: widget actualizado

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late SimpleHomeProvider _provider; // CAMBIO: SimpleHomeProvider
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<SimpleHomeProvider>(context, listen: false);

    _searchController.addListener(() {
      _provider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // CAMBIO: No dispose del provider (es singleton)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CAMBIO: Consumer simple en lugar de MultiProvider
    return Consumer<SimpleHomeProvider>(
      builder: (context, provider, _) {
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
                    suffixIcon: _searchController.text.isNotEmpty // NUEVO: botón clear
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery(''); // NUEVO: limpiar búsqueda
                      },
                    )
                        : null,
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

              // CAMBIO: FilterChipsRow sin parámetros (ya migrado)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: FilterChipsRow(), // CAMBIO: sin parámetros
              ),

              const SizedBox(height: 8.0),

              // CAMBIO: Lista simplificada usando SimpleHomeProvider
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.errorMessage != null
                    ? Center(
                  child: Text('Error: ${provider.errorMessage}'),
                )
                    : provider.getEventsWithoutDateFilter().isEmpty
                    ? const Center(child: Text('No hay eventos.'))
                    : _buildOptimizedEventsList(provider), // CAMBIO: pasar provider
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptimizedEventsList(SimpleHomeProvider provider) {
    final limitedEvents = provider.getEventsWithoutDateFilter().take(20).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverFixedExtentList( // CAMBIO: Directo sin SliverPadding
          itemExtent: 253.0, // CAMBIO: 237px widget + 12px gap real
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return Padding( // NUEVO: Gap con Padding
                padding: const EdgeInsets.only(bottom: 16.0), // NUEVO: Gap real entre tarjetas
                child: EventCardWidget( // CAMBIO: Sin SizedBox redundant
                  event: limitedEvents[index],
                  provider: provider,
                  key: ValueKey(limitedEvents[index].id),
                ),
              );
            },
            childCount: limitedEvents.length,
          ),
        ),
      ],
    );
  }
}