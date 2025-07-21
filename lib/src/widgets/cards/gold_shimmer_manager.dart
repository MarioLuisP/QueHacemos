import 'package:flutter/material.dart';

/// Singleton que maneja la animación shimmer para todas las tarjetas Gold
/// Eficiencia máxima: 1 solo AnimationController para todas las tarjetas Gold
class GoldShimmerManager {
  static GoldShimmerManager? _instance;
  static GoldShimmerManager get instance => _instance ??= GoldShimmerManager._();
  
  AnimationController? _controller;
  Animation<double>? _animation;
  final Set<VoidCallback> _listeners = {};
  bool _isInitialized = false;
  
  GoldShimmerManager._();
  
  /// Inicializa el manager con un TickerProvider (solo se llama una vez)
  void initialize(TickerProvider vsync) {
    if (_isInitialized) {
      return;
    }
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: vsync,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    ));

    // 🔧 Notificar en cada tick de la animación
    _animation!.addListener(_notifyListeners);

    // 🔁 Detectar cuándo termina para reiniciar
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller!.reset();
        Future.delayed(const Duration(seconds: 3), _startShimmerLoop);
      }
    });

    _isInitialized = true;
    _startShimmerLoop();
  }
  
  /// Inicia el loop infinito de shimmer
  void _startShimmerLoop() {
    if (!_isInitialized || _controller == null) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isInitialized && _controller != null) {
        _controller!.forward().then((_) {
          if (_isInitialized && _controller != null) {
            _controller!.reset();
            Future.delayed(const Duration(seconds: 3), _startShimmerLoop);
          }
        });
      }
    });
  }
  
  /// Notifica a todas las tarjetas Gold suscritas que se actualicen
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
  
  /// Las tarjetas Gold se suscriben para recibir updates
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  /// Las tarjetas Gold se desuscriben al destruirse
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
  _controller?.dispose();
  _controller = null;
  _animation = null;
  _isInitialized = false;
}
  }
  
  /// Getter para la animación (usado por GoldEventCardPainter)
  Animation<double>? get animation => _animation;
  
  /// Limpia recursos (opcional, para testing o hot reload)
  void dispose() {
    _controller?.dispose();
    _listeners.clear();
    _isInitialized = false;
    _controller = null;
    _animation = null;
  }
  
  /// Getter para verificar si está inicializado
  bool get isInitialized => _isInitialized;
}