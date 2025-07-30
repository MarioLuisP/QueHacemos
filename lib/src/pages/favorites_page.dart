import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_home_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/cards/event_card_widget.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        centerTitle: true,
        toolbarHeight: 40.0,
        elevation: 2.0,
      ),
      body: Consumer2<SimpleHomeProvider, FavoritesProvider>(
        builder: (context, simpleProvider, favProvider, child) {
          // Loading state
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

          // Error state
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

          // Get favorite events
          final favoriteEvents = simpleProvider.getFavoriteEvents();

          // Empty state
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

          // Success state - Lista eficiente de favoritos
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 16.0),
                sliver: SliverFixedExtentList(
                  itemExtent: 249.0, // Misma altura que HomePage
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: EventCardWidget(
                          event: favoriteEvents[index],
                          provider: simpleProvider,
                          key: ValueKey(favoriteEvents[index].id),
                        ),
                      );
                    },
                    childCount: favoriteEvents.length,
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