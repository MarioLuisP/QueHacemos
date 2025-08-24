import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/cards/event_card_widget.dart';
import '../widgets/app_bars/main_app_bar.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

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