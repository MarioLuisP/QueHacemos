import 'package:flutter/material.dart';

/// Singleton que maneja la animación de partículas para tarjetas Platinum
/// Similar a GoldShimmerManager pero con timing diferente
class PlatinumParticlesManager {
  static PlatinumParticlesManager? _instance;
  static PlatinumParticlesManager get instance => _instance ??= PlatinumParticlesManager._();
  
  AnimationController? _controller;
  Animation<double>? _animation;
  final Set<VoidCallback> _listeners = {};
  bool _isInitialized = false;
  
  PlatinumParticlesManager._();
  
  /// Inicializa el manager con un TickerProvider
  void initialize(TickerProvider vsync) {
    if (_isInitialized) {
      return;
    }
    
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // Ciclo de 3 segundos
      vsync: vsync,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    ));

    _animation!.addListener(_notifyListeners);
    
    _isInitialized = true;
    
    // Loop infinito
    _controller!.repeat();
  }
  
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
  
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
  _controller?.dispose();
  _controller = null;
  _animation = null;
  _isInitialized = false;
}
  }
  
  Animation<double>? get animation => _animation;
  
  void dispose() {
    _controller?.dispose();
    _listeners.clear();
    _isInitialized = false;
    _controller = null;
    _animation = null;
  }
  
  bool get isInitialized => _isInitialized;
}