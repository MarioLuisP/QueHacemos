import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/pages/pages.dart';
import 'package:quehacemos_cba/src/pages/favorites_page.dart';



class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _selectedDate;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) {
        _selectedDate = null;
      }
      print('Índice seleccionado: $_currentIndex, Fecha: $_selectedDate');
    });
  }

  // NUEVO: Método para volver al calendario desde HomePage
  void _returnToCalendar() {
    setState(() {
      _currentIndex = 2; // Índice del calendario
    });
  }
  void _onDateSelected(DateTime? selectedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _currentIndex = 0;
      print('Fecha seleccionada: $_selectedDate, Cambiando a HomePage');
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        key: ValueKey(_selectedDate?.toIso8601String() ?? 'no-date'),
        selectedDate: _selectedDate,
        onReturnToCalendar: _returnToCalendar, // NUEVO
      ),
      const ExplorePage(),
      CalendarPage(onDateSelected: _onDateSelected),
      const FavoritesPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
