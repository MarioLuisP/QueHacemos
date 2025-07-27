import 'package:flutter/material.dart';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';
import '../widgets/cards/event_card_widget.dart';
import '../cache/cache_models.dart';
import '../pages/date_events_page.dart';

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

  // LIMPIEZA: Cache local para counts (eficiencia)
  final Map<DateTime, int> _eventCountsCache = {};
  final GlobalKey _calendarKey = GlobalKey();
  double _calendarHeight = 0.0;

  // LIMPIEZA: Navegación con debounce para evitar crashes
  Timer? _navigationTimer;

  // LIMPIEZA: Provider getter - acceso lazy sin initialize()
  SimpleHomeProvider get _provider => context.read<SimpleHomeProvider>();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // ELIMINADO: _homeProvider = context.read<SimpleHomeProvider>();
    // ELIMINADO: _initializeProvider() - patrón peligroso del informe

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCalendarHeight();
      _loadEventCounts(); // CAMBIO: método simplificado
    });

    print('📅 Calendario inicializado limpio: $_focusedDay');
  }

  // LIMPIEZA: Método simplificado sin initialize()
  Future<void> _loadEventCounts() async {
    final now = _focusedDay;
    final startMonth = DateTime(now.year, now.month - 1, 1);
    final endMonth = DateTime(now.year, now.month + 2, 0);

    // SEGURO: Provider ya auto-inicializado, solo obtener counts
    final counts = _provider.getEventCountsForDateRange(startMonth, endMonth);

    _eventCountsCache.clear();
    _eventCountsCache.addAll(counts);

    if (mounted) setState(() {});
  }

  void _updateCalendarHeight() {
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

  // LIMPIEZA: Navegación segura con debounce
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final eventCount = _eventCountsCache[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)] ?? 0;

    if (eventCount > 0) {
      // REMOVIDO: setState antes de navegación
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DateEventsPage(selectedDate: selectedDay),
        ),
      ).then((returnedDate) {
        if (returnedDate != null && mounted) {
          setState(() {
            _selectedDay = returnedDate;
            _focusedDay = returnedDate;
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay eventos para ${_formatDate(selectedDay)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    print('📅 Día seleccionado: $selectedDay');
  }

  @override
  void dispose() {
    _navigationTimer?.cancel(); // LIMPIEZA: Cancelar timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // LIMPIEZA: Consumer único y directo
    return Consumer<SimpleHomeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Elije el Día'),
            centerTitle: true,
            toolbarHeight: 40.0,
            elevation: 2.0,
          ),
          body: Stack(
            children: [
              _buildScrollableContent(provider), // CAMBIO: Pasar provider como parámetro
              _buildFloatingCalendar(),
            ],
          ),
        );
      },
    );
  }

  // LIMPIEZA: Contenido simplificado sin FutureBuilder anidado
  Widget _buildScrollableContent(SimpleHomeProvider provider) { // CAMBIO: Recibir provider como parámetro
    if (_selectedDay == null) return Container();

    // REMOVIDO: Consumer anidado innecesario
    final dateString = "${_selectedDay!.year.toString().padLeft(4, '0')}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}";
    final eventsForDay = provider.events.where((event) =>
        event.date.startsWith(dateString)
    ).toList();

    // NUEVO DEBUG
    print('📅 Calendar - dateString: $dateString');
    print('📅 Calendar - provider.events.length: ${provider.events.length}');
    print('📅 Calendar - fechas disponibles: ${provider.events.map((e) => e.date).toList()}');
    print('📅 Calendar - eventsForDay.length: ${eventsForDay.length}');

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

    return CustomScrollView( // REMOVIDO: Consumer wrapper
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: _calendarHeight + 24.0),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(left: 0.0, right: 0.0),
          sliver: SliverFixedExtentList(
            itemExtent: 249.0,
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final event = eventsForDay[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: EventCardWidget(
                    event: event,
                    provider: provider, // CAMBIO: usar provider del parámetro
                    key: ValueKey(event.id),
                  ),
                );
              },
              childCount: eventsForDay.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingCalendar() {
    return Positioned(
      top: 8.0,
      left: 20.0,
      right: 20.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.7),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: TableCalendar(
            locale: 'es_ES',
            key: _calendarKey,
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
              // LIMPIEZA: Sin múltiples setState
              setState(() => _focusedDay = focusedDay);
              _loadEventCounts();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateCalendarHeight();
              });

              print('📅 Mes cambiado: $focusedDay');
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
                          : (eventCount > 0 ? Colors.orange[300] : Colors.blue[200]),
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
              selectedBuilder: (context, day, focusedDay) {
                if (isSameDay(day, DateTime.now())) {
                  return null;
                }

                final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;
                return Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: eventCount > 0 ? Colors.purple[300] : Colors.blue[400],
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
              defaultBuilder: (context, day, focusedDay) {
                final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;
                if (eventCount > 0) {
                  return Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                        color: Colors.green[200],
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
              markerBuilder: (context, date, events) {
                final eventCount = _eventCountsCache[DateTime(date.year, date.month, date.day)] ?? 0;
                if (eventCount > 0) {
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
                          eventCount.toString(),
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
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'hoy';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'mañana';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}