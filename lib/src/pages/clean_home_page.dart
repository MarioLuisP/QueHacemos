// lib/src/pages/clean_home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';
import '../providers/category_constants.dart';
import '../cache/cache_models.dart';
import '../widgets/cards/event_card_widget.dart';
/// HomePage LIMPIA que usa cache + filtros optimizados
// NUEVO: Modelo para items planos
class FlatItem {
  final String type; // 'header' o 'event'
  final String? title; // Para headers
  final EventCacheItem? event; // Para eventos

  FlatItem.header(this.title) : type = 'header', event = null;
  FlatItem.event(this.event) : type = 'event', title = null;
}
/// Zero complejidad, solo mostrar eventos desde memoria
class CleanHomePage extends StatefulWidget {
  const CleanHomePage({super.key});

  @override
  State<CleanHomePage> createState() => _CleanHomePageState();
}

class _CleanHomePageState extends State<CleanHomePage> {
  late SimpleHomeProvider _provider;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = context.read<SimpleHomeProvider>();

    // Inicializar en el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Córdoba - Cache Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SimpleHomeProvider>(
        builder: (context, provider, child) {
          // Loading state
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando cache en memoria...'),
                ],
              ),
            );
          }

          // Error state
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${provider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Success state - mostrar eventos
          return Column(
            children: [
              // Barra de búsqueda + filtros
              _buildSearchAndFilters(provider),

              // Lista de eventos
              Expanded(
                child: _buildEventsList(provider),
              ),

              // Stats bar (para debug)
              _buildStatsBar(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _provider.refresh(),
        child: const Icon(Icons.refresh),
        tooltip: 'Recargar cache',
      ),
    );
  }

  /// Barra de búsqueda y filtros básicos
  Widget _buildSearchAndFilters(SimpleHomeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar eventos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (query) => provider.setSearchQuery(query),
          ),

          const SizedBox(height: 12),

          // Filtros rápidos
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickFilter('Todos', () => provider.clearAllFilters()),
                    _buildQuickFilter('🎨 Arte', () => provider.setCategories({'arte'})),
                    _buildQuickFilter('🎭 Teatro', () => provider.setCategories({'teatro'})),
                    _buildQuickFilter('🛍️ Ferias', () => provider.setCategories({'ferias'})),
                    _buildQuickFilter('🎵 Música', () => provider.setCategories({'musica'})),
                  ],
                ),
              ),
            ],
          ),

          // Info de filtros aplicados
          if (provider.appliedFiltersText != 'Sin filtros')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Filtros: ${provider.appliedFiltersText}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Botón de filtro rápido
  Widget _buildQuickFilter(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.blue[50],
    );
  }

  /// Lista de eventos agrupados por fecha
  Widget _buildEventsList(SimpleHomeProvider provider) {
    if (provider.events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay eventos que mostrar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Prueba cambiar los filtros',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final sortedDates = provider.getSortedDateKeys();

    return ListView.builder(
      itemCount: _getTotalItemCount(provider, sortedDates),
      itemBuilder: (context, index) {
        return _buildListItem(provider, sortedDates, index);
      },
    );
  }

  /// Calcular total de items (headers + eventos)
  int _getTotalItemCount(SimpleHomeProvider provider, List<String> sortedDates) {
    int count = 0;
    for (final date in sortedDates) {
      count++; // Header
      count += provider.groupedEvents[date]?.length ?? 0; // Eventos
    }
    return count;
  }

  /// Construir item de lista (header o evento)
  Widget _buildListItem(SimpleHomeProvider provider, List<String> sortedDates, int index) {
    int currentIndex = 0;

    for (final date in sortedDates) {
      // Header
      if (currentIndex == index) {
        return _buildDateHeader(provider.getSectionTitle(date));
      }
      currentIndex++;

      // Eventos de esta fecha
      final eventsForDate = provider.groupedEvents[date] ?? [];
      for (final event in eventsForDate) {
        if (currentIndex == index) {
          return _buildEventTile(event, provider);
        }
        currentIndex++;
      }
    }

    return const SizedBox.shrink();
  }

  /// Header de fecha
  Widget _buildDateHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue[50],
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  /// Tarjeta de evento usando FastEventCard
  Widget _buildEventTile(EventCacheItem event, SimpleHomeProvider provider) {
    return EventCardWidget(
      event: event,
      provider: provider,
    );
  }

  /// Formatear hora del evento
  String _formatEventTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')} hs';
    } catch (e) {
      return dateString;
    }
  }

  /// Barra de estadísticas (debug)
  Widget _buildStatsBar(SimpleHomeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('📊 ${provider.eventCount} eventos'),
          Text('📅 ${provider.groupedEvents.keys.length} fechas'),
          Text('🔍 ${provider.appliedFiltersText}'),
        ],
      ),
    );
  }
}