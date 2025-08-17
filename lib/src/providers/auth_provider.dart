// lib/src/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;

  // GETTERS PÚBLICOS
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isAnonymous => _authService.isAnonymous;

  // DATOS DEL USUARIO PARA UI
  String get userName {
    if (!isLoggedIn) return 'Usuario';
    return _user?.displayName ?? _user?.email?.split('@')[0] ?? 'Usuario';
  }

  String get userEmail {
    if (!isLoggedIn) return '';
    return _user?.email ?? '';
  }

  String get userInitials {
    if (!isLoggedIn) return '?';

    final name = _user?.displayName;
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        return parts[0][0].toUpperCase();
      }
    }

    final email = _user?.email;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }

    return '?';
  }

  String get userPhotoUrl => _user?.photoURL ?? '';

  AuthProvider() {
    _initializeAuthListener();
  }

  /// Inicializar listener de cambios de autenticación
  void _initializeAuthListener() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();

      if (user != null) {
        if (user.isAnonymous) {
          print('👤 Usuario anónimo activo: ${user.uid}');
        } else {
          print('✅ Usuario logueado: ${user.displayName ?? user.email}');
        }
      }
    });

    // Establecer usuario actual
    _user = _authService.currentUser;
  }

  /// Inicializar autenticación (detecta usuario existente o crea anónimo) // CAMBIO
  void initializeAuth() { // CAMBIO
    _isLoading = true;
    notifyListeners();

    try {
      final existingUser = _authService.currentUser; // CAMBIO

      if (existingUser != null && !existingUser.isAnonymous) { // NUEVO
        // Usuario ya logueado - auto-login exitoso // NUEVO
        print('✅ Auto-login exitoso: ${existingUser.displayName ?? existingUser.email}'); // NUEVO
        // El listener ya se encarga de actualizar el estado // NUEVO
      } else { // NUEVO
        // No hay usuario real, crear anónimo // NUEVO
        _authService.signInAnonymously();
        // El listener se encarga de actualizar el estado
      } // NUEVO
    } catch (e) {
      print('❌ Error inicializando auth: $e'); // CAMBIO
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login con Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        // El listener se encarga de actualizar el estado
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error en Google Sign-In: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login con Apple
  Future<bool> signInWithApple() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signInWithApple();
      if (result != null) {
        // El listener se encarga de actualizar el estado
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error en Apple Sign-In: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cerrar sesión (vuelve a anónimo)
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      // El listener se encarga de actualizar el estado
    } catch (e) {
      print('❌ Error en logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtener color del avatar basado en el usuario
  Color getAvatarColor() {
    if (!isLoggedIn) {
      return Colors.grey.withAlpha(179); // Gris para anónimo
    }

    // Color basado en email para usuarios logueados
    final email = _user?.email ?? '';
    if (email.isNotEmpty) {
      final hash = email.hashCode;
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.indigo,
        Colors.pink,
      ];
      return colors[hash.abs() % colors.length];
    }

    return Colors.blue; // Default
  }

  @override
  void dispose() {
    super.dispose();
  }
}