import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/cards/event_card_widget.dart';
import '../widgets/app_bars/main_app_bar.dart';
import 'dart:async';
import '../services/weekly_prompt_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_modal.dart';
import '../services/notification_config_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    _checkWeeklyPrompts();
  }

  void _checkWeeklyPrompts() {
    Timer(const Duration(seconds: 3), () {
      if (mounted && _isPageVisible()) {
        _evaluatePrompts();
      }
    });
  }

  bool _isPageVisible() {
    final route = ModalRoute.of(context);
    return route?.isCurrent == true;
  }

  Future<void> _evaluatePrompts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Evaluar si mostrar prompt de login
    final shouldShowLogin = await WeeklyPromptService.shouldShowLoginPrompt(authProvider);

    if (shouldShowLogin) {
      _showLoginPromptModal(authProvider);
    }

// Evaluar notificaciones siempre
    final shouldShowNotifications = await WeeklyPromptService.shouldShowNotificationPrompt();
    if (shouldShowNotifications) {
      // Delay mayor si ya se mostró login
      final delay = shouldShowLogin ? 5 : 2;
      Timer(Duration(seconds: delay), () {
        if (mounted) {
          _showNotificationPromptModal();
        }
      });
    }
  }

  void _showLoginPromptModal(AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LoginModal(authProvider: authProvider),
    ).then((result) async {
      // Si cerró sin loguear, contar como decline
      if (!authProvider.isLoggedIn) {
        await WeeklyPromptService.recordLoginDecline();
      }
    });
  }

  void _showNotificationPromptModal() {
    // Reutilizar modal del NotificationCard o crear uno simple
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📱 Notificaciones'),
        content: const Text('¿Querés activar las notificaciones para estar al día con los eventos?'),
        actions: [
          TextButton(
            onPressed: () async {
              await WeeklyPromptService.recordNotificationDecline();
              Navigator.pop(context);
            },
            child: const Text('Quizás más tarde'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await NotificationConfigurationService.configureNotifications();
            },
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FavoritesAppBar(),
      body: Consumer2<SimpleHomeProvider, FavoritesProvider>(
        builder: (context, simpleProvider, favProvider, child) {
          // Estados de carga y error (sin cambios)
          if (simpleProvider.isLoading || !favProvider.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando favoritos...'),
                ],
              ),
            );
          }

          if (simpleProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${simpleProvider.errorMessage}'),
                ],
              ),
            );
          }

          // Obtener todos los favoritos
          final favoriteEvents = simpleProvider.getFavoriteEvents();

          if (favoriteEvents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes eventos favoritos',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Marca eventos como favoritos desde la página principal',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // --- FILTRADO POR FECHA ---
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // Parsear y filtrar
          final activeEvents = favoriteEvents.where((event) {
            final eventDate = DateTime.parse(event.date);
            return !eventDate.isBefore(today);
          }).toList();

          final expiredEvents = favoriteEvents.where((event) {
            final eventDate = DateTime.parse(event.date);
            return eventDate.isBefore(today);
          }).toList();

          // Mantener orden ascendente original
          activeEvents.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
          expiredEvents.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

          // --- RENDERIZADO EFICIENTE ---
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. Activos (hoy en adelante)
              if (activeEvents.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 16.0),
                  sliver: SliverFixedExtentList(
                    itemExtent: 249.0,
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: EventCardWidget(
                            event: activeEvents[index],
                            provider: simpleProvider,
                            key: ValueKey(activeEvents[index].id),
                          ),
                        );
                      },
                      childCount: activeEvents.length,
                    ),
                  ),
                ),

              // 2. Separador visual (solo si hay vencidos)
              if (expiredEvents.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '🥀 Favoritos vencidos',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                  ),
                ),

              // 3. Vencidos (hasta ayer)
              if (expiredEvents.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 0.0),
                  sliver: SliverFixedExtentList(
                    itemExtent: 249.0,
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: EventCardWidget(
                            event: expiredEvents[index],
                            provider: simpleProvider,
                            key: ValueKey(expiredEvents[index].id),
                          ),
                        );
                      },
                      childCount: expiredEvents.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }


}