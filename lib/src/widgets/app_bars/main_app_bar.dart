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
  final double toolbarHeight;

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
    this.toolbarHeight = kToolbarHeight,
  });

  /// Constructor para HomePage (configuración optimizada)
  const MainAppBar.home({
    super.key,
    this.title = 'QuehaCeMos Córdoba',
    this.customActions,
    this.showUserAvatar = true,
    this.showNotifications = true,
    this.showContactButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.centerTitle = true,
    this.toolbarHeight = kToolbarHeight,
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
    this.toolbarHeight = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    // Extraer colores del theme UNA VEZ
    final appBarBgColor = backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor;
    final appBarFgColor = foregroundColor ?? Theme.of(context).appBarTheme.foregroundColor;

    return AppBar(
      title: _buildTitle(context),
      centerTitle: centerTitle,
      toolbarHeight: preferredSize.height,
      elevation: elevation,
      backgroundColor: appBarBgColor,
      foregroundColor: appBarFgColor,
      actions: _buildActions(context, appBarFgColor),
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
        color: foregroundColor ?? Theme.of(context).appBarTheme.foregroundColor,
      ),
    );
  }

  /// Calcular tamaño de fuente eficientemente
  double _getTitleFontSize(String title) {
    if (title.length > 20) return 20.0;
    if (title.length > 15) return 21.0;
    return 22.0;
  }

  /// Construir acciones - VERSIÓN EFICIENTE
  List<Widget> _buildActions(BuildContext context, Color? foregroundColor) {
    final List<Widget> actions = [];

    // Acciones personalizadas primero
    if (customActions != null) {
      actions.addAll(customActions!);
    }

    // ContactButton - Versión simple eficiente
    if (showContactButton) {
      actions.add(
        Transform.translate(
          offset: const Offset(0.0, 0), // Acercar al centro
          child: _ContactButtonSimple(iconColor: foregroundColor),
        ),
      );
    }

// NotificationsBell - Versión real optimizada
    if (showNotifications) {
      actions.add(
        Transform.translate(
          offset: const Offset(-6.0, 0),
          child: _NotificationsBellReal(iconColor: foregroundColor),
        ),
      );
    }
// UserAvatar - Mock eficiente (sin auth complejo)
    if (showUserAvatar) {
      actions.add(
        Transform.translate(
          offset: const Offset(-2.0, 0), // Acercar desde el borde
          child: _UserAvatarMock(iconColor: foregroundColor),
        ),
      );
    }

    return actions;
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}

/// COMPONENTES MOCK EFICIENTES - Integrados para evitar imports

/// ContactButton simple - Ultra eficiente con modal funcional
class _ContactButtonSimple extends StatelessWidget {
  final Color? iconColor;

  const _ContactButtonSimple({this.iconColor});

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Colors.white;

    return IconButton(
      onPressed: () {
        FocusScope.of(context).unfocus(); // 👈 Cierra el teclado
        ContactModal.show(context);       // 👈 Abre el modal
      },
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withAlpha(38),
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(77), width: 1),
        ),
        child: Icon(
          Icons.add_circle_outline,
          color: color,
          size: 18,
        ),
      ),
      tooltip: 'Publicar evento',
    );
  }
}

/// UserAvatar mock - Ultra eficiente
class _UserAvatarMock extends StatelessWidget {
  final Color? iconColor;

  const _UserAvatarMock({this.iconColor});

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Colors.white;

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
          border: Border.all(color: color.withAlpha(77), width: 2),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              color: color,
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
  final Color? iconColor;

  const _NotificationsBellReal({this.iconColor});

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
              Icon(
                Icons.notifications_outlined,
                color: iconColor ?? Colors.white,
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
                      border: Border.all(color: iconColor ?? Colors.white, width: 1),
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
    FocusScope.of(context).unfocus();
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
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[300],
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
    title: title ?? 'Elije el Día',
    customActions: customActions,
    showUserAvatar: true,
    showNotifications: true,
    showContactButton: false,
    centerTitle: true,
    toolbarHeight: 40.0,
  );
}
class ExploreAppBar extends MainAppBar {
  const ExploreAppBar({super.key, String? title, List<Widget>? customActions})
      : super(
    title: title ?? 'Explorar Eventos',
    customActions: customActions,
    showUserAvatar: true,
    showNotifications: true,
    showContactButton: false,
    centerTitle: true,
    toolbarHeight: 40.0,
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
    toolbarHeight: 40.0,
  );
}