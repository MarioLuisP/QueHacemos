import 'package:flutter/material.dart';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';
import '../widgets/cards/event_card_widget.dart';
import '../widgets/chips/filter_chips_widget.dart';
import '../cache/cache_models.dart';
import '../widgets/app_bars/main_app_bar.dart';


class CalendarPage extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  const CalendarPage({super.key, this.onDateSelected});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}
enum CalendarState { expanded, collapsed }

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {

  // ===== CONFIGURACIÓN AJUSTABLE =====
  static const double COLLAPSED_HEIGHT_FRACTION = 0.15; // Ajustable: fracción visible cuando colapsado (15%)

  // ===== ESTADO DEL CALENDARIO =====
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, int> _eventCountsCache = {};
  final GlobalKey _calendarKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  // ✅ MEJORADO: Una sola fuente de verdad para altura
  double _fullCalendarHeight = 300.0; // Altura completa medida una vez


  // ✅ MEJORADO: Estado de colapso con state machine
  CalendarState _calendarState = CalendarState.expanded;

  // ===== ESTADO DE CHIPS (LOCAL) =====
  Set<String> _localActiveCategories = {};


  SimpleHomeProvider get _provider => context.read<SimpleHomeProvider>();

  @override
  void initState() {
    super.initState();

    // ✅ MEJORADO: Restaurar estado desde provider si existe
    _selectedDay = _provider.lastSelectedDate ?? _focusedDay;



   _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureCalendarHeight();
      _loadEventCounts();
    });

    print('📅 Calendar inicializado - día restaurado: $_selectedDay');
  }


  void _collapseCalendar() {
    if (_calendarState != CalendarState.expanded) return;
    setState(() => _calendarState = CalendarState.collapsed);
  }

  void _expandCalendar() {
    if (_calendarState != CalendarState.collapsed) return;
    setState(() => _calendarState = CalendarState.expanded);
  }
  void _onCalendarTap() {
    if (_calendarState == CalendarState.collapsed) {
      _expandCalendar();
    }
  }

  // ===== GESTIÓN DE CHIPS =====
  void _toggleLocalCategory(String category) {
    setState(() {
      if (_localActiveCategories.contains(category)) {
        _localActiveCategories.remove(category);
      } else {
        _localActiveCategories.add(category);
      }
    });
  }

  void _clearLocalCategories() {
    setState(() {
      _localActiveCategories.clear();
    });
  }

  List<EventCacheItem> _getFilteredEventsForDay() {
    if (_selectedDay == null) return [];

    final dateString = "${_selectedDay!.year.toString().padLeft(4, '0')}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}";
    var eventsForDay = _provider.events.where((event) =>
        event.date.startsWith(dateString)
    ).toList();

    if (_localActiveCategories.isNotEmpty) {
      eventsForDay = eventsForDay.where((event) =>
          _localActiveCategories.contains(event.type.toLowerCase())
      ).toList();
    }

    return eventsForDay;
  }

  // ===== MÉTODOS DE CALENDARIO =====
  Future<void> _loadEventCounts() async {
    final now = _focusedDay;
    final startMonth = DateTime(now.year, now.month - 1, 1);
    final endMonth = DateTime(now.year, now.month + 2, 0);

    final counts = _provider.getEventCountsForDateRange(startMonth, endMonth);

    _eventCountsCache.clear();
    _eventCountsCache.addAll(counts);

    if (mounted) setState(() {});
  }

  // ✅ MEJORADO: Medir altura una sola vez
  void _measureCalendarHeight() {
    Future.delayed(Duration(milliseconds: 150), () {
      final RenderBox? renderBox = _calendarKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final newHeight = renderBox.size.height + 16.0;
        if ((newHeight - _fullCalendarHeight).abs() > 5.0) {
          setState(() {
            _fullCalendarHeight = newHeight;
          });
          print('📅 Altura del calendario medida: $_fullCalendarHeight');
        }
      }
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final eventCount = _eventCountsCache[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)] ?? 0;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // ✅ MEJORADO: Persistir en provider
    _provider.setLastSelectedDate(selectedDay);

    // Si no hay eventos y está colapsado, expandir para mostrar el calendario
    if (eventCount == 0 && _calendarState == CalendarState.collapsed) {
      _expandCalendar();
    }

    print('📅 Día seleccionado y persistido: $selectedDay');
  }

  void _onScroll() {
    final scrollPosition = _scrollController.position.pixels;
    final halfCalendarHeight = _fullCalendarHeight / 2;

    // ✅ Trigger simple: si scroll pasó la mitad del calendario
    if (scrollPosition > halfCalendarHeight && _calendarState == CalendarState.expanded) {
      _collapseCalendar();
    } else if (scrollPosition < 20 && _calendarState == CalendarState.collapsed) {
      _expandCalendar();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleHomeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: CalendarAppBar(title: 'Elije el Día'),
          body: Column(
            children: [
              // CHIPS FIJOS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FilterChipsRow(
                  availableCategories: provider.selectedCategories.toList(),
                  activeCategories: _localActiveCategories,
                  onToggleCategory: _toggleLocalCategory,
                  onClearAll: _clearLocalCategories,
                  currentTheme: provider.theme,
                ),
              ),

              // CONTENIDO PRINCIPAL
              Expanded(
                child: Stack(
                  children: [
                    _buildScrollableContent(provider),
                    _buildAnimatedCalendar(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollableContent(SimpleHomeProvider provider) {
    if (_selectedDay == null) return Container();

    final filteredEvents = _getFilteredEventsForDay();

    if (filteredEvents.isEmpty) {
      return CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: _fullCalendarHeight + 24.0),
          ),
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No hay eventos para esta fecha con los filtros aplicados.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: _fullCalendarHeight + 24.0),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(left: 0.0, right: 0.0),
          sliver: SliverFixedExtentList(
            itemExtent: 249.0,
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final event = filteredEvents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: EventCardWidget(
                    event: event,
                    provider: provider,
                    key: ValueKey(event.id),
                  ),
                );
              },
              childCount: filteredEvents.length,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ MEJORADO: AnimatedBuilder optimizado con child parameter
  Widget _buildAnimatedCalendar() {
    return Positioned(
      top: 8.0,
      left: 20.0,
      right: 20.0,
      child: GestureDetector(
        onTap: _onCalendarTap,
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.7), // ✅ Transparencia del simple
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: _buildCalendarChild(), // ✅ Sin AnimatedBuilder
          ),
        ),
      ),
    );
  }
  Widget _buildCalendarChild() {
    return _calendarState == CalendarState.collapsed
        ? _buildCollapsedCalendarHeader()
        : _buildFullCalendar();
  }

  Widget _buildCollapsedCalendarHeader() {
    return SizedBox(
      height: _fullCalendarHeight * COLLAPSED_HEIGHT_FRACTION,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Calendario',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedDay != null)
              Text(
                '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            Icon(
              Icons.expand_more,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCalendar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
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
              _measureCalendarHeight();
            });
          }
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
          _loadEventCounts();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _measureCalendarHeight();
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