import 'package:flutter/material.dart';
import '../services/notification_config_service.dart';
import '../models/user_preferences.dart';
import '../services/daily_task_manager.dart';
import '../utils/dimens.dart';

class NotificationCard extends StatefulWidget {
  const NotificationCard({super.key});

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimens.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔔 Notificaciones',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.paddingMedium),
            FutureBuilder<bool>(
              future: NotificationConfigurationService.isAlreadyConfigured(),
              builder: (context, snapshot) {
                final isConfigured = snapshot.data ?? false;
                
                // Si ya está configurado, mostrar toggle simple
                if (isConfigured) {
                  return _buildConfiguredNotificationToggle();
                }
                
                // Si no está configurado, mostrar botón de configuración
                return _buildNotificationConfigurationButton();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle simple para cuando las notificaciones ya están configuradas
  Widget _buildConfiguredNotificationToggle() {
    return FutureBuilder<bool>(
      future: UserPreferences.getNotificationsReady(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        
        return SwitchListTile(
          title: const Text('Notificaciones diarias'),
          subtitle: Text(isEnabled
              ? '✅ Notificaciones activadas'
              : '⏸️ Notificaciones pausadas'),
          value: isEnabled,
          onChanged: (value) async {
            if (value) {
              // Reactivar notificaciones
              await UserPreferences.setNotificationsReady(true);
              DailyTaskManager().initialize();
              print('✅ Notificaciones reactivadas');
            } else {
              // Pausar notificaciones
              await NotificationConfigurationService.disableNotifications();
              print('⏸️ Notificaciones pausadas');
            }
            setState(() {});
          },
        );
      },
    );
  }

  /// Botón de configuración inicial para cuando no están configuradas
  Widget _buildNotificationConfigurationButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Estado actual
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_off,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Notificaciones no configuradas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botón de configuración
        _NotificationConfigButton(
          onConfigurationChanged: () {
            // Actualizar el FutureBuilder padre
            setState(() {});
          },
        ),
      ],
    );
  }
}

// WIDGET DEDICADO PARA EL BOTÓN DE CONFIGURACIÓN
class _NotificationConfigButton extends StatefulWidget {
  final VoidCallback onConfigurationChanged;
  
  const _NotificationConfigButton({
    required this.onConfigurationChanged,
  });
  
  @override
  State<_NotificationConfigButton> createState() => _NotificationConfigButtonState();
}

class _NotificationConfigButtonState extends State<_NotificationConfigButton> {
  NotificationConfigState _currentState = NotificationConfigState.idle;
  bool _isProcessing = false;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón principal
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _handleConfigurePress,
          icon: _buildButtonIcon(),
          label: Text(_buildButtonText()),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: _getButtonColor(context),
            foregroundColor: _getButtonTextColor(context),
          ),
        ),
        
        // Mensaje de estado
        if (_currentState != NotificationConfigState.idle)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildStateMessage(context),
          ),
        
        // Botón de reintento para errores
        if (_isErrorState() && !_isProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _handleRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
          ),
      ],
    );
  }
  
  Future<void> _handleConfigurePress() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _currentState = NotificationConfigState.detectingPlatform;
    });
    
    try {
      final result = await NotificationConfigurationService.configureNotifications();
      
      setState(() {
        _currentState = result;
        _isProcessing = false;
      });
      
      // Si fue exitoso, notificar al padre para que se actualice
      if (result == NotificationConfigState.success) {
        await Future.delayed(const Duration(seconds: 2));
        widget.onConfigurationChanged();
      }
    } catch (e) {
      print('💥 Error inesperado en configuración: $e');
      setState(() {
        _currentState = NotificationConfigState.errorUnknown;
        _isProcessing = false;
      });
    }
  }
  
  void _handleRetry() {
    setState(() {
      _currentState = NotificationConfigState.idle;
    });
  }
  
  Widget _buildButtonIcon() {
    if (_isProcessing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getButtonTextColor(context),
          ),
        ),
      );
    }
    
    switch (_currentState) {
      case NotificationConfigState.success:
        return const Icon(Icons.check_circle);
      case NotificationConfigState.errorPermissionDenied:
      case NotificationConfigState.errorInitializationFailed:
      case NotificationConfigState.errorWorkManagerFailed:
      case NotificationConfigState.errorUnknown:
        return const Icon(Icons.error);
      default:
        return const Icon(Icons.notifications_active);
    }
  }
  
  String _buildButtonText() {
    if (_isProcessing) {
      switch (_currentState) {
        case NotificationConfigState.detectingPlatform:
          return 'Detectando dispositivo...';
        case NotificationConfigState.requestingPermissions:
          return 'Pidiendo permisos...';
        case NotificationConfigState.initializingService:
          return 'Configurando servicio...';
        case NotificationConfigState.configuringWorkManager:
          return 'Configurando tareas...';
        case NotificationConfigState.savingPreferences:
          return 'Finalizando...';
        default:
          return 'Configurando...';
      }
    }
    
    switch (_currentState) {
      case NotificationConfigState.success:
        return '¡Configurado exitosamente!';
      case NotificationConfigState.errorPermissionDenied:
        return 'Permisos denegados';
      case NotificationConfigState.errorInitializationFailed:
        return 'Error de configuración';
      case NotificationConfigState.errorWorkManagerFailed:
        return 'Error en tareas programadas';
      case NotificationConfigState.errorUnknown:
        return 'Error inesperado';
      default:
        return 'Configurar Notificaciones';
    }
  }
  
  Widget _buildStateMessage(BuildContext context) {
    final message = _getStateMessage();
    final isError = _isErrorState();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isError 
            ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.5)
            : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.warning_amber : Icons.info,
            size: 16,
            color: isError 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isError 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getStateMessage() {
    switch (_currentState) {
      case NotificationConfigState.success:
        return 'Las notificaciones están configuradas y listas para usar.';
      case NotificationConfigState.errorPermissionDenied:
        return 'Los permisos de notificación fueron denegados. Ve a Configuración > Apps para habilitarlos.';
      case NotificationConfigState.errorInitializationFailed:
        return 'No se pudo inicializar el sistema de notificaciones.';
      case NotificationConfigState.errorWorkManagerFailed:
        return 'Error configurando las tareas programadas.';
      case NotificationConfigState.errorUnknown:
        return 'Ocurrió un error inesperado. Revisa los logs para más detalles.';
      default:
        return 'Configurando el sistema de notificaciones...';
    }
  }
  
  Color _getButtonColor(BuildContext context) {
    switch (_currentState) {
      case NotificationConfigState.success:
        return Theme.of(context).colorScheme.primaryContainer;
      case NotificationConfigState.errorPermissionDenied:
      case NotificationConfigState.errorInitializationFailed:
      case NotificationConfigState.errorWorkManagerFailed:
      case NotificationConfigState.errorUnknown:
        return Theme.of(context).colorScheme.errorContainer;
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }
  
  Color _getButtonTextColor(BuildContext context) {
    switch (_currentState) {
      case NotificationConfigState.success:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case NotificationConfigState.errorPermissionDenied:
      case NotificationConfigState.errorInitializationFailed:
      case NotificationConfigState.errorWorkManagerFailed:
      case NotificationConfigState.errorUnknown:
        return Theme.of(context).colorScheme.onErrorContainer;
      default:
        return Theme.of(context).colorScheme.onPrimaryContainer;
    }
  }
  
  bool _isErrorState() {
    return [
      NotificationConfigState.errorPermissionDenied,
      NotificationConfigState.errorInitializationFailed,
      NotificationConfigState.errorWorkManagerFailed,
      NotificationConfigState.errorUnknown,
    ].contains(_currentState);
  }
}