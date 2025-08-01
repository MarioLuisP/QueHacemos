// lib/src/widgets/app_bars/main_app_bar.dart
// VERSIÓN OPTIMIZADA basada en MainAppBar vieja pero para nueva arquitectura

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../contact_modal.dart';
import '../../providers/notifications_provider.dart';
import 'components/notifications_bell.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? customActions;
  final bool showUserAvatar;
  final bool showNotifications;
  final bool showContactButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;

  const MainAppBar({
    super.key,
    this.title,
    this.customActions,
    this.showUserAvatar = true,
    this.showNotifications = true,
    this.showContactButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.centerTitle = true,
  });

  /// Constructor para HomePage (configuración optimizada)
  const MainAppBar.home({
    super.key,
    this.title = 'QuehaCeMos Córdoba',
    this.customActions,
    this.showUserAvatar = true,
    this.showNotifications = true,
    this.showContactButton = true,
    this.backgroundColor = Colors.blue,
    this.foregroundColor = Colors.white,
    this.elevation = 2.0,
    this.centerTitle = true,
  });

  /// Constructor para páginas internas (minimalista)
  const MainAppBar.internal({
    super.key,
    required this.title,
    this.customActions,
    this.showUserAvatar = false,
    this.showNotifications = false,
    this.showContactButton = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _buildTitle(context),
      centerTitle: centerTitle,
      toolbarHeight: preferredSize.height,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? Theme.of(context).appBarTheme.foregroundColor,
      actions: _buildActions(context),
    );
  }

  /// Construir título optimizado
  Widget _buildTitle(BuildContext context) {
    if (title == null) return const SizedBox.shrink();

    return Text(
      title!,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.bold,
        fontSize: _getTitleFontSize(title!),
        color: foregroundColor ?? Colors.white,
      ),
    );
  }

  /// Calcular tamaño de fuente eficientemente
  double _getTitleFontSize(String title) {
    if (title.length > 20) return 18.0;
    if (title.length > 15) return 18.0;
    return 20.0;
  }

  /// Construir acciones - VERSIÓN EFICIENTE
  List<Widget> _buildActions(BuildContext context) {
    final List<Widget> actions = [];

    // Acciones personalizadas primero
    if (customActions != null) {
      actions.addAll(customActions!);
    }

    // ContactButton - Versión simple eficiente
    if (showContactButton) {
      actions.add(
        Transform.translate(
          offset: const Offset(-4.0, 0), // Acercar al centro
          child: _ContactButtonSimple(),
        ),
      );
    }

// NotificationsBell - Versión real optimizada
    if (showNotifications) {
      actions.add(
        Transform.translate(
          offset: const Offset(-8.0, 0),
          child: NotificationsBell(),
        ),
      );
    }
    // UserAvatar - Mock eficiente (sin auth complejo)
    if (showUserAvatar) {
      actions.add(
        Transform.translate(
          offset: const Offset(-2.0, 0), // Acercar desde el borde
          child: _UserAvatarMock(),
        ),
      );
    }

    return actions;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// COMPONENTES MOCK EFICIENTES - Integrados para evitar imports

/// ContactButton simple - Ultra eficiente con modal funcional
class _ContactButtonSimple extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => ContactModal.show(context),
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(77), width: 1),
        ),
        child: const Icon(
          Icons.add_circle_outline,
          color: Colors.white,
          size: 18,
        ),
      ),
      tooltip: 'Publicar evento',
    );
  }
}


/// UserAvatar mock - Ultra eficiente
class _UserAvatarMock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil - Próximamente')),
        );
      },
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(77), width: 2),
        ),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      tooltip: 'Mi perfil',
    );
  }
}
/// NotificationsBell real - Optimizado con Selector granular
class _NotificationsBellReal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<NotificationsProvider, ({int unreadCount, bool hasUnread})>(
      selector: (context, provider) => (
      unreadCount: provider.unreadCount,
      hasUnread: provider.hasUnreadNotifications,
      ),
      builder: (context, data, child) {
        return IconButton(
          onPressed: () => _showNotificationsPanel(context),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 24,
              ),
              if (data.hasUnread)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${data.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Notificaciones',
        );
      },
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    final provider = context.read<NotificationsProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationsPanel(provider: provider),
    );
  }
}

/// Panel básico de notificaciones - Versión simplificada
class _NotificationsPanel extends StatelessWidget {
  final NotificationsProvider provider;

  const _NotificationsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notificaciones',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.notifications.isEmpty
                ? const Center(child: Text('No hay notificaciones'))
                : ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return ListTile(
                  leading: Text(notification['icon'] ?? '🔔'),
                  title: Text(notification['title']),
                  subtitle: Text(notification['message']),
                  onTap: () {
                    if (!notification['isRead']) {
                      provider.markAsRead(notification['id']);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
/// AppBars especializadas (conservadas de versión original)

class CalendarAppBar extends MainAppBar {
  const CalendarAppBar({super.key, String? title, List<Widget>? customActions})
      : super(
    title: title ?? 'Calendario',
    customActions: customActions,
    showUserAvatar: true,
    showNotifications: true,
    showContactButton: false,
    centerTitle: true,
  );
}

class FavoritesAppBar extends MainAppBar {
  const FavoritesAppBar({super.key, String? title, List<Widget>? customActions})
      : super(
    title: title ?? 'Mis Favoritos',
    customActions: customActions,
    showUserAvatar: true,
    showNotifications: false,
    showContactButton: false,
    centerTitle: true,
  );
}