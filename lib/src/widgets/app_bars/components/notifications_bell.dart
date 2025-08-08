import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notifications_provider.dart';

/// NotificationsBell real - Optimizado con Selector granular
class NotificationsBell extends StatelessWidget {
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

  /// Mostrar panel de notificaciones
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

/// Panel de notificaciones - Copiado de la app vieja pero optimizado
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
          _NotificationsPanelHeader(provider: provider),
          Expanded(
            child: provider.notifications.isEmpty
                ? _EmptyNotificationsState()
                : _NotificationsList(provider: provider),
          ),
        ],
      ),
    );
  }
}

/// Resto de componentes del panel (copiados de notifications_bell.dart viejo)
class _NotificationsPanelHeader extends StatelessWidget {
  final NotificationsProvider provider;

  const _NotificationsPanelHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notificaciones',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Row(
                children: [
                  if (provider.hasUnreadNotifications)
                    TextButton(
                      onPressed: () => provider.markAllAsRead(),
                      child: Text(
                        '✔️Todas leídas',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.headlineSmall?.color,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => _showClearAllDialog(context, provider),
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                    tooltip: 'Limpiar historial',
                  ),
                ],
              ),
            ],
          ),
          if (provider.notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    '${provider.notifications.length} notificaciones',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (provider.hasUnreadNotifications) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.unreadCount} nuevas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, NotificationsProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar historial'),
          content: const Text('¿Estás seguro de que querés eliminar todas las notificaciones?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                provider.clearAllNotifications();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historial limpiado')),
                );
              },
              child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final NotificationsProvider provider;

  const _NotificationsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return _NotificationTile(notification: notification, provider: provider);
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final NotificationsProvider provider;

  const _NotificationTile({required this.notification, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] as bool;
    final timestamp = notification['timestamp'] as DateTime;

    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        provider.removeNotification(notification['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificación eliminada')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.transparent
              : Theme.of(context).colorScheme.primary.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? Colors.grey.withAlpha(51)
                : Theme.of(context).colorScheme.primary.withAlpha(51),
          ),
        ),
        child: ListTile(
          leading: Text(
            notification['icon'] ?? '🔔',
            style: const TextStyle(fontSize: 24),
          ),
          title: Text(
            notification['title'],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification['message'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.getNotificationTime(timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: isRead
              ? null
              : Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          onTap: () {
            if (!isRead) {
              provider.markAsRead(notification['id']);
            }
          },
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tenés notificaciones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Te avisaremos cuando haya eventos nuevos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}