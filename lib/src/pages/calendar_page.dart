import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart'; // NUEVO: provider actualizado
import '../widgets/cards/event_card_widget.dart'; // NUEVO: widget actualizado
import '../cache/cache_models.dart'; // NUEVO: modelos de cache
// ELIMINADO: home_viewmodel, fast_event_card, event_service, event_repository

class CalendarPage extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  const CalendarPage({super.key, this.onDateSelected});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late SimpleHomeProvider _homeProvider; // CAMBIO: nuevo provider
  final Map<DateTime, int> _eventCountsCache = {}; // MANTENER: igual
  // ELIMINADO: _eventRepository - ahora usamos cache directo
  final GlobalKey _calendarKey = GlobalKey();
  double _calendarHeight = 0.0; // Altura por defecto

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _homeProvider = context.read<SimpleHomeProvider>(); // CAMBIO: obtener provider del context
    _initializeProvider(); // CAMBIO: nombre de método
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCalendarHeight();
    });
    print('Calendario inicializado: $_focusedDay');
  }

  Future<void> _initializeProvider() async { // CAMBIO: nombre
    await _homeProvider.initialize(); // CAMBIO: usar nuevo provider
    await _preloadEventCounts();
    // ELIMINADO: _eventRepository - no se usa más
  }

  Future<void> _preloadEventCounts() async {
    // Calcular rango: mes anterior, actual, siguiente
    final now = _focusedDay;
    final startMonth = DateTime(now.year, now.month - 1, 1);
    final endMonth = DateTime(now.year, now.month + 2, 0); // Último día del mes siguiente

    // CAMBIO: Obtener counts desde cache O(1)
    final counts = _homeProvider.getEventCountsForDateRange(startMonth, endMonth);

    // CAMBIO: Actualizar cache local directamente
    _eventCountsCache.clear();
    _eventCountsCache.addAll(counts);

    if (mounted) setState(() {});
  }

  // ✅ NUEVO: Método para obtener altura real del calendario
  void _updateCalendarHeight() {
    // ✅ Delay más largo para asegurar que TableCalendar terminó de renderizar
    Future.delayed(Duration(milliseconds: 150), () {
      final RenderBox? renderBox = _calendarKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final newHeight = renderBox.size.height + 16.0;
        if ((newHeight - _calendarHeight).abs() > 1.0) {
          setState(() {
            _calendarHeight = newHeight;
          });
        }
      }
    });
  }

  Future<List<EventCacheItem>> _getEventsForDay(DateTime day) async { // CAMBIO: retorna EventCacheItem
    return await _homeProvider.getEventsForDate(day); // CAMBIO: usar nuevo provider
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    print('Día seleccionado: $selectedDay');
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    if (widget.onDateSelected != null) {
      widget.onDateSelected!(selectedDay);
    }
  }

  @override
  void dispose() {
    // ELIMINADO: _homeProvider.dispose() - se maneja automáticamente por Provider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleHomeProvider>( // CAMBIO: Consumer directo, sin ChangeNotifierProvider.value
      builder: (context, provider, child) { // CAMBIO: provider en lugar de viewModel
          return Scaffold(
            appBar: AppBar(
              title: const Text('Elije el Día'),
              centerTitle: true,
              toolbarHeight: 40.0,
              elevation: 2.0,
              actions: [],
            ),
            body: Stack(
              children: [
                // ✅ CONTENIDO SCROLLEABLE (tarjetas) - va detrás
                _buildScrollableContent(),

                // ✅ CALENDAR FLOTANTE - va adelante
                _buildFloatingCalendar(),
              ],
            ),
          );
      }  // CAMBIO: eliminar el ; después de }
    );   // AGREGAR: cierra Consumer
  }      // MANTENER: cierra método build

  // ✅ CORREGIDO: FutureBuilder limpio sin duplicación
  Widget _buildEventsForSelectedDay() {
    return FutureBuilder<List<EventCacheItem>>( // CAMBIO: tipo de datos
      future: _getEventsForDay(_selectedDay!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final eventsForDay = snapshot.data ?? [];

        if (eventsForDay.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No hay eventos para esta fecha.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        // ✅ SOLUCIÓN: CustomScrollView con padding inicial como SliverToBoxAdapter
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ✅ Espacio inicial fijo que permite overscroll
            SliverToBoxAdapter(
              child: SizedBox(height: _calendarHeight + 24.0),
            ),

            // ✅ Lista con solo padding horizontal
            SliverPadding(
              padding: const EdgeInsets.only(left: 0.0, right: 0.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = eventsForDay[index];
                        return SizedBox(
                          height: 237.0, // CAMBIO: altura ajustada para EventCardWidget
                          child: EventCardWidget( // CAMBIO: nuevo widget
                            event: event, // CAMBIO: ya es EventCacheItem
                            provider: _homeProvider, // CAMBIO: nuevo provider
                            key: ValueKey(event.id), // CAMBIO: acceso directo a id
                          ),
                    );
                  },
                  childCount: eventsForDay.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildScrollableContent() {
    if (_selectedDay == null) {
      return Container();
    }

    // ✅ CustomScrollView directo sin padding del padre
    return _buildEventsForSelectedDay();
  }

  Widget _buildFloatingCalendar() {
    return Positioned(
      top: 8.0,
      left: 20.0,
      right: 20.0,
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.7),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: TableCalendar(
            locale: 'es_ES',
            key: _calendarKey, // ✅ AGREGAR esto
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateCalendarHeight();
                });
              }
            },
            onPageChanged: (focusedDay) {
              print('Mes cambiado: $focusedDay');
              setState(() => _focusedDay = focusedDay);
              _preloadEventCounts(); // ✅ CORREGIDO
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateCalendarHeight();
                setState(() {}); // Fuerza rebuild completo
              });
            },
            daysOfWeekHeight: 20,
            rowHeight: 30,
            sixWeekMonthsEnforced: false,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.circular(8.0),
              ),
              defaultDecoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              weekendDecoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              outsideDecoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              defaultTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              outsideTextStyle: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              todayTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              selectedTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),

            calendarBuilders: CalendarBuilders(
              // ✅ CORREGIDO: Today builder con eventCount
              todayBuilder: (context, day, focusedDay) {
                final isSelected = isSameDay(_selectedDay, day);
                final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;

                return Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue[400]
                          : (eventCount > 0 ? Colors.orange[300] : Colors.blue[200]), // ✅ CORREGIDO
                      borderRadius: BorderRadius.circular(8.0),
                      border: isSelected ? null : Border.all(color: Colors.blue[600]!, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },

              // ✅ CORREGIDO: Selected builder con eventCount
              selectedBuilder: (context, day, focusedDay) {
                if (isSameDay(day, DateTime.now())) {
                  return null; // Dejar que todayBuilder maneje
                }

                final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;
                return Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: eventCount > 0 ? Colors.purple[300] : Colors.blue[400], // ✅ CORREGIDO
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },

              // ✅ CORREGIDO: Default builder con eventCount
              defaultBuilder: (context, day, focusedDay) {
                final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;
                if (eventCount > 0) { // ✅ CORREGIDO
                  return Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                        color: Colors.green[200], // Días con eventos
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },

              // ✅ CORREGIDO: Marker builder usando cache
              markerBuilder: (context, date, events) {
                final eventCount = _eventCountsCache[DateTime(date.year, date.month, date.day)] ?? 0;
                if (eventCount > 0) { // ✅ CORREGIDO
                  return Positioned(
                    left: 0,
                    bottom: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.deepPurple[700]!, width: 1),
                      ),
                      width: 18,
                      height: 18,
                      child: Center(
                        child: Text(
                          eventCount.toString(), // ✅ CORREGIDO
                          //'${eventCount > 0 ? 68 : 0}',
                          style: TextStyle(
                            color: Colors.deepPurple[700],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),

            eventLoader: (day) {
              // ✅ CORREGIDO: Simple loader para TableCalendar
              final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;
              return List.generate(eventCount, (index) => 'evento_$index');
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              formatButtonShowsNext: false,
              formatButtonTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
              formatButtonDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              titleCentered: true,
              titleTextStyle: const TextStyle(fontSize: 16),
              leftChevronPadding: const EdgeInsets.all(4),
              rightChevronPadding: const EdgeInsets.all(4),
            ),
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mes',
              CalendarFormat.twoWeeks: '2 Semanas',
              CalendarFormat.week: 'Semana',
            },
          ),  // CAMBIO: cierra TableCalendar
        ),    // MANTENER: cierra Padding
      ),      // MANTENER: cierra Container
    );        // MANTENER: cierra Positioned
  }           // MANTENER: cierra método
}