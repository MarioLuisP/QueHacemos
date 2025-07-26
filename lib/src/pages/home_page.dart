// lib/src/pages/clean_home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';

import '../cache/cache_models.dart';
import '../widgets/cards/event_card_widget.dart';

class HomePage extends StatefulWidget { // CAMBIO: nombre correcto
  final DateTime? selectedDate;          // NUEVO: parámetro del calendario
  final VoidCallback? onReturnToCalendar; // NUEVO: callback para volver

  const HomePage({                       // CAMBIO: nombre correcto
    super.key,
    this.selectedDate,                   // NUEVO: parámetro opcional
    this.onReturnToCalendar,            // NUEVO: callback opcional
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late SimpleHomeProvider _provider;


  @override
  void initState() {
    super.initState();
    _provider = context.read<SimpleHomeProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Siempre sincronizar selectedDate con provider
      _provider.setSelectedDate(widget.selectedDate);
    });
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


              // Lista de eventos
              Expanded(
                child: _buildEventsList(provider),
              ),

              // Stats bar (para debug)

            ],
          );
        },
      ),
    );
  }

  /// Lista de eventos optimizada con máxima eficiencia
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

    final sortedDates = provider.getSortedDateKeys(); // NUEVO: Fechas ordenadas

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        for (final date in sortedDates) ...[  // NUEVO: Loop por cada fecha
          // Header del día
          SliverToBoxAdapter( // NUEVO: Header como sliver separado
            child: _buildDateHeader(provider.getSectionTitle(date)),
          ),
          // Eventos de ese día con máxima eficiencia
          SliverFixedExtentList( // NUEVO: Lista super eficiente para eventos
            itemExtent: 249.0, // NUEVO: 237px tarjeta + 12px gap
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final eventsForDate = provider.groupedEvents[date]!; // NUEVO: Eventos de esta fecha
                return Padding( // NUEVO: Gap real entre tarjetas
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: EventCardWidget( // CAMBIO: Sin SizedBox redundante
                    event: eventsForDate[index],
                    provider: provider,
                    key: ValueKey(eventsForDate[index].id),
                  ),
                );
              },
              childCount: provider.groupedEvents[date]?.length ?? 0, // NUEVO: Count específico por fecha
            ),
          ),
        ],
      ],
    );
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
}