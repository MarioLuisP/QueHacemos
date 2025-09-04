import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class LoginModal extends StatelessWidget {
  final AuthProvider authProvider;

  const LoginModal({
    super.key,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Iniciar sesión',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🚀 Ayudá a que esta app crezca\n✨ Pronto vas a acceder a\n🎁 increibles beneficios 😎🎁',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: authProvider.isLoading ? null : () async {
                final success = await authProvider.signInWithGoogle();
                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.login, size: 20),
              label: authProvider.isLoading
                  ? const Text('Conectando...')
                  : const Text('Continuar con Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (Theme.of(context).platform == TargetPlatform.iOS) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: authProvider.isLoading ? null : () async {
                  final success = await authProvider.signInWithApple();
                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.apple, size: 20),
                label: authProvider.isLoading
                    ? const Text('Conectando...')
                    : const Text('Continuar con Apple'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quizás más tarde'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}