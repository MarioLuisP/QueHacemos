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

/// NotificationsBell - Versión real optimizada
    if (showNotifications) {
      actions.add(
        Transform.translate(
          offset: const Offset(-6.0, 0),
          child: NotificationsBell(),
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