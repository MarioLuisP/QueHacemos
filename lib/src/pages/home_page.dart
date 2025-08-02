// lib/src/pages/home_page.dart - OPTIMIZADO

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';
import '../widgets/chips/filter_chips_widget.dart';
import '../cache/cache_models.dart';
import '../widgets/cards/event_card_widget.dart';
import '../widgets/app_bars/main_app_bar.dart';

class HomePage extends StatefulWidget {
  final DateTime? selectedDate;
  final VoidCallback? onReturnToCalendar;

  const HomePage({
    super.key,
    this.selectedDate,
    this.onReturnToCalendar,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late SimpleHomeProvider _provider;

  // NUEVO: Estado local para filtros (no afecta provider)
  Set<String> _localActiveCategories = {};

  @override
  void initState() {
    super.initState();
    _provider = context.read<SimpleHomeProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.setSelectedDate(widget.selectedDate);
    });
  }

  // NUEVO: Filtrado local sin afectar provider
  Map<String, List<EventCacheItem>> _getFilteredGroupedEvents(
      Map<String, List<EventCacheItem>> allGroupedEvents,
      ) {
    if (_localActiveCategories.isEmpty) {
      return allGroupedEvents;
    }

    final filtered = <String, List<EventCacheItem>>{};

    allGroupedEvents.forEach((date, events) {
      final filteredEvents = events.where((event) {
        return _localActiveCategories.contains(event.type.toLowerCase());
      }).toList();

      if (filteredEvents.isNotEmpty) {
        filtered[date] = filteredEvents;
      }
    });

    return filtered;
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
    return Scaffold(
      appBar: const MainAppBar.home(),
      body: Selector<SimpleHomeProvider, ({
      bool isLoading,
      String? errorMessage,
      Map<String, List<EventCacheItem>> groupedEvents,
      Set<String> availableCategories,
      String theme,
      })>(
        selector: (context, provider) => (
        isLoading: provider.isLoading,
        errorMessage: provider.errorMessage,
        groupedEvents: provider.groupedEvents,
        availableCategories: provider.selectedCategories,
        theme: provider.theme,
        ),
        builder: (context, data, child) {
          // Loading state
          if (data.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando eventos...'),
                ],
              ),
            );
          }

          // Error state
          if (data.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${data.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _provider.refresh(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Success state - aplicar filtros locales
          final filteredGroupedEvents = _getFilteredGroupedEvents(data.groupedEvents);

          return Column(
            children: [
              // NUEVO: Filter chips con estado local
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                ),
                child: FilterChipsRow(
                  availableCategories: data.availableCategories.toList(),
                  activeCategories: _localActiveCategories,
                  onToggleCategory: _toggleLocalCategory,
                  onClearAll: _clearLocalCategories,
                  currentTheme: data.theme,
                ),
              ),

              // Lista de eventos optimizada
              Expanded(
                child: _buildEventsList(filteredGroupedEvents),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Lista de eventos optimizada con máxima eficiencia
  Widget _buildEventsList(Map<String, List<EventCacheItem>> groupedEvents) {
    if (groupedEvents.isEmpty) {
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

    final sortedDates = _provider.getSortedDateKeys()
        .where((date) => groupedEvents.containsKey(date))
        .toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        for (final date in sortedDates) ...[
          // Header del día - Widget estático
          SliverToBoxAdapter(
            child: _buildDateHeader(_provider.getSectionTitle(date)),
          ),

          // Eventos de ese día con máxima eficiencia
          SliverFixedExtentList(
            itemExtent: 249.0, // 237px tarjeta + 12px gap
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final eventsForDate = groupedEvents[date]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: EventCardWidget(
                    event: eventsForDate[index],
                    provider: _provider,
                    key: ValueKey(eventsForDate[index].id),
                  ),
                );
              },
              childCount: groupedEvents[date]?.length ?? 0,
            ),
          ),
        ],
      ],
    );
  }

  /// Header de fecha - Widget estático
  Widget _buildDateHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primary.withAlpha(30),  // ← Respeta theme
      child: Text(
        title,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,  // ← Respeta theme
        ),
      ),
    );
  }
}