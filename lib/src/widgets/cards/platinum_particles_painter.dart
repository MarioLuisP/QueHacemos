import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Painter que dibuja puntos brillantes para tarjetas Platinum
/// Se usa como tercera capa sobre Silver + Shimmer
class PlatinumParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final String theme;
  final _random = math.Random();
  
  // Posiciones fijas de las partículas (para que no salten)
  final List<Offset> _particlePositions = [];
  
  PlatinumParticlesPainter({
    required this.animation,
    required this.theme,
  }) : super(repaint: animation) {
    // Generar posiciones aleatorias una sola vez
    _generateParticlePositions();
  }
  
  void _generateParticlePositions() {
    // Generar 12-15 puntos brillantes distribuidos
    for (int i = 0; i < 15; i++) {
      _particlePositions.add(
        Offset(
          _random.nextDouble(), // 0.0 a 1.0 (será multiplicado por width)
          _random.nextDouble(), // 0.0 a 1.0 (será multiplicado por height)
        ),
      );
    }
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    // Ciclo de animación: 0.0 → 1.0 → 0.0
    final animValue = animation.value;
    final pulse = animValue < 0.5 
      ? animValue * 2         // 0→1 en la primera mitad
      : 2 - (animValue * 2);  // 1→0 en la segunda mitad
    
    // Paint para los puntos brillantes
    final particlePaint = Paint()
      ..color = _getParticleColor().withAlpha((pulse * 1 * 255).round())
      ..style = PaintingStyle.fill;
    
    // Paint para el brillo exterior (glow)
    final glowPaint = Paint()
      ..color = _getParticleColor().withAlpha((pulse * 0.5 * 255).round())
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    // Dibujar cada partícula
    for (int i = 0; i < _particlePositions.length; i++) {
      final position = _particlePositions[i];
      final x = position.dx * size.width;
      final y = position.dy * size.height;
      
      // Tamaño variable según la animación
      final baseSize = 2.0 + (i % 3); // 2-4 pixels base
      final currentSize = baseSize * (0.5 + pulse * 0.5);
      
      // Solo dibujar si la opacidad es suficiente
      if (pulse > 0.2) {
        // Dibujar glow
        canvas.drawCircle(
          Offset(x, y),
          currentSize * 2,
          glowPaint,
        );
        
        // Dibujar punto central
        canvas.drawCircle(
          Offset(x, y),
          currentSize,
          particlePaint,
        );
      }
    }
  }
  
  /// Color de las partículas según el tema
  Color _getParticleColor() {
    switch (theme) {
      case 'dark':
      case 'fluor':
        return Colors.white;
      case 'normal':
        return const Color(0xFFE8E8E8); // Plateado claro
      case 'pastel':
        return const Color(0xFFFFE4E1); // Misty rose
      case 'sepia':
        return const Color(0xFFF5DEB3); // Wheat
      case 'harmony':
        return const Color(0xFFFAFAFA); // Casi blanco
      default:
        return Colors.white;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}