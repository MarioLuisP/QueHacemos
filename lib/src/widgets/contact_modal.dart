import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactModal {
  /// NUEVO: Mostrar modal de contacto para publicar eventos
  static Future<void> show(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ContactModalContent(),
    ).then((_) {                          // <-- AGREGAR
      FocusScope.of(context).unfocus();   // <-- AGREGAR
    });                                   // <-- AGREGAR
  }
}

class _ContactModalContent extends StatelessWidget {
  const _ContactModalContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NUEVO: Header del modal
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
          const SizedBox(height: 20),

          // NUEVO: Título principal
          Text(
            '¿Querés publicar tu evento?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // NUEVO: Subtítulo
          Text(
            'Contáctanos por cualquiera de estos medios:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // NUEVO: Opción WhatsApp
          _ContactOption(
            icon: '📱',
            title: 'WhatsApp',
            subtitle: '+54 9 351 XXX XXXX',
            onTap: () => _launchWhatsApp(context),
          ),
          const SizedBox(height: 16),

          // NUEVO: Opción Email
          _ContactOption(
            icon: '📧',
            title: 'Email',
            subtitle: 'eventos@quehacemos.com',
            onTap: () => _launchEmail(context),
          ),
          const SizedBox(height: 16),

          // NUEVO: Opción futura (formulario)
          _ContactOption(
            icon: '📋',
            title: 'Formulario online',
            subtitle: 'Próximamente disponible',
            onTap: null, // NUEVO: Deshabilitado por ahora
            enabled: false,
          ),
          const SizedBox(height: 24),

          // NUEVO: Botón cerrar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// NUEVO: Abrir WhatsApp
  static Future<void> _launchWhatsApp(BuildContext context) async {
    const phoneNumber = '+5493511234567'; // NUEVO: Reemplazar con número real
    const message =
        'Hola! Me gustaría publicar un evento en QuehaCeMos Córdoba';
    final url =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
      if (context.mounted) Navigator.pop(context);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  /// NUEVO: Abrir email
  static Future<void> _launchEmail(BuildContext context) async {
    const email = 'eventos@quehacemos.com'; // NUEVO: Reemplazar con email real
    const subject = 'Publicar evento en QuehaCeMos Córdoba';
    const body = 'Hola! Me gustaría publicar un evento en la plataforma.';

    final url =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
      if (context.mounted) Navigator.pop(context);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el cliente de email')),
        );
      }
    }
  }
}

/// NUEVO: Widget para cada opción de contacto
class _ContactOption extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color:
              enabled
                  ? Theme.of(context).colorScheme.outline.withAlpha(77)
                  : Colors.grey.withAlpha(77),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // NUEVO: Ícono
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),

              // NUEVO: Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: enabled ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // NUEVO: Flecha si está habilitado
              if (enabled) Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
