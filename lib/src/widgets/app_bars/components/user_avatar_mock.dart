import 'package:flutter/material.dart';

class UserAvatarMock extends StatelessWidget {
  const UserAvatarMock({super.key});

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