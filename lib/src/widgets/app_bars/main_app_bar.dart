// lib/src/widgets/app_bars/main_app_bar.dart
// VERSIÓN OPTIMIZADA basada en MainAppBar vieja pero para nueva arquitectura

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../contact_modal.dart';
import '../../providers/auth_provider.dart';
import 'components/notifications_bell.dart';
import '../login_modal.dart';

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
      titleSpacing: 0,
      actions: _buildActions(context, appBarFgColor),
    );
  }

  /// Construir título optimizado
  Widget _buildTitle(BuildContext context) {
    if (title == null) return const SizedBox.shrink();

    // Ancho REAL de la pantalla (no del título)
    final screenWidth = MediaQuery.of(context).size.width;

    return Text(
      title!,
      overflow: TextOverflow.visible,
      softWrap: false,
      maxLines: 1,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.bold,
        fontSize: _getResponsiveFontSize(title!, screenWidth),
        color: foregroundColor ?? Theme.of(context).appBarTheme.foregroundColor,
      ),
    );
  }

  double _getResponsiveFontSize(String title, double screenWidth) {
    if (screenWidth < 360) return 16.0;

    if (screenWidth < 430) {
      if (title.length > 15) return 19.0;
      return 20.0;
    }

    if (title.length > 15) return 20.0;
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
// UserAvatar - Real con AuthProvider // NUEVO
    if (showUserAvatar) {
      actions.add(
        Transform.translate(
          offset: const Offset(-2.0, 0), // Acercar desde el borde
          child: _UserAvatarReal(iconColor: foregroundColor), // NUEVO
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
        ContactModal.show(context);
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
          Icons.phone_forwarded,
          color: color,
          size: 18,
        ),
      ),
      tooltip: 'Publicar evento',
    );
  }
}

/// UserAvatar real con AuthProvider // NUEVO
class _UserAvatarReal extends StatelessWidget {
  // NUEVO
  final Color? iconColor;

  const _UserAvatarReal({this.iconColor}); // NUEVO

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Colors.white;

    return Consumer<AuthProvider>( // NUEVO
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) { // NUEVO
          return _buildLoadingAvatar(color); // NUEVO
        }

        return IconButton( // NUEVO
          onPressed: () => _handleAvatarTap(context, authProvider), // NUEVO
          icon: _buildAvatarIcon(authProvider, color), // NUEVO
          tooltip: authProvider.isLoggedIn
              ? 'Mi cuenta'
              : 'Iniciar sesión', // NUEVO
        );
      },
    );
  }

  /// Avatar en estado loading // NUEVO
  Widget _buildLoadingAvatar(Color color) {
    // NUEVO
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  /// Manejar tap en avatar // NUEVO
  void _handleAvatarTap(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isLoggedIn) {
      _showLogoutModal(context, authProvider); // NUEVO
    } else {
      _showLoginModal(context, authProvider); // NUEVO
    }
  }

  /// Construir icono del avatar // NUEVO
  Widget _buildAvatarIcon(AuthProvider authProvider, Color color) {
    // Usar AspectRatio para mantener proporción circular
    return AspectRatio(
      aspectRatio: 1.0, // Mantiene círculo perfecto
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 36,
          maxHeight: 36,
        ),
        decoration: BoxDecoration(
          color: authProvider.getAvatarColor(),
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(77), width: 2),
        ),
        child: _buildAvatarContent(authProvider, color),
      ),
    );
  }
  /// Contenido del avatar (foto, iniciales o silueta) // NUEVO
  Widget _buildAvatarContent(AuthProvider authProvider, Color color) {
    // NUEVO
    if (authProvider.userPhotoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          authProvider.userPhotoUrl,
          fit: BoxFit.cover, // Sin width/height fijos
          // ... resto igual
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar(authProvider, color); // NUEVO
          },
        ),
      );
    }

    return _buildFallbackAvatar(authProvider, color); // NUEVO
  }

  /// Avatar fallback (iniciales para logueado, silueta para anónimo) // NUEVO
  Widget _buildFallbackAvatar(AuthProvider authProvider, Color color) {
    // NUEVO
    return Center(
      child: authProvider.isLoggedIn
          ? Text( // Iniciales para usuario logueado
        authProvider.userInitials,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      )
          : Icon( // Silueta para usuario anónimo // NUEVO
        Icons.person,
        color: color,
        size: 20,
      ),
    );
  }

// Métodos helper se agregan después... // NUEVO

  /// Mostrar modal de login (anónimo → logueado) // NUEVO
  void _showLoginModal(BuildContext context, AuthProvider authProvider) {
    // NUEVO
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LoginModal(authProvider: authProvider),
    );
  }

  /// Mostrar modal de logout (logueado → anónimo) // NUEVO
  void _showLogoutModal(BuildContext context, AuthProvider authProvider) {
    // NUEVO
    showDialog(
      context: context,
      builder: (context) => _LogoutModal(authProvider: authProvider), // NUEVO
    );
  }

}

/// Modal de Logout - Simple y directo // NUEVO
class _LogoutModal extends StatelessWidget { // NUEVO
  final AuthProvider authProvider;

  const _LogoutModal({required this.authProvider}); // NUEVO

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          // Email del usuario // NUEVO
          Text(
            authProvider.userEmail,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
      content: const Text('¿Querés cerrar sesión?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: authProvider.isLoading ? null : () async {
            await authProvider.signOut();
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: authProvider.isLoading
              ? const Text('Cerrando...')
              : const Text('Cerrar sesión'),
        ),
      ],
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
    title: title ?? 'Busca Eventos',
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