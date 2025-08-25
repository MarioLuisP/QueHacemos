// lib/src/services/auth_service.dart

import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import '../providers/notifications_provider.dart'; // NUEVO


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isGoogleInitialized = false;

  /// Inicializar Google Sign-In (llamar una vez al inicio)
  Future<void> initializeGoogleSignIn() async {
    if (_isGoogleInitialized) return;

    try {
      await _googleSignIn.initialize(
        serverClientId: '998972257036-llbcet7uc4l7ilclp6uqp9r73o4eo1aa.apps.googleusercontent.com', // NUEVO
      );
      _isGoogleInitialized = true;
      print('✅ Google Sign-In inicializado correctamente');
    } catch (e) {
      print('⚠️ Error inicializando Google Sign-In: $e');
    }
  }

  /// Inicializar usuario anónimo (automático al abrir app)
  Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      print('✅ Usuario anónimo conectado: ${result.user?.uid}');
      return result.user;
    } catch (e) {
      print('⚠️ Error auth anónimo (sin conexión): $e');
      return null;
    }
  }

  /// Google Sign-In con nueva API 2025
  /// Google Sign-In simplificado (solo para upgrade inicial) // CAMBIO
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await initializeGoogleSignIn();

      if (!_googleSignIn.supportsAuthenticate()) {
        print('❌ Plataforma no soporta Google Sign-In');
        return null;
      }

      // Mostrar selector de Google directamente // NUEVO
      print('👤 Mostrando selector de Google');
      final googleUser = await _googleSignIn.authenticate(scopeHint: ['email']); // CAMBIO

      // Autenticar con Firebase // NUEVO
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final result = await _auth.signInWithCredential(credential);

      print('✅ Google Sign-In exitoso: ${result.user?.displayName}');

// NUEVO: Notificación de bienvenida
      await NotificationsProvider.instance.addNotification( // NUEVO
        title: '🤗 ¡Ya estás dentro!', // NUEVO
        message: 'Bienvenido ${result.user?.displayName ?? result.user?.email}', // NUEVO
        type: 'login_success', // NUEVO
      ); // NUEVO

      return result;


    } catch (e) {
      print('❌ Error en Google Sign-In: $e');
      if (!e.toString().contains('cancel')) { // NUEVO
        await NotificationsProvider.instance.addNotification( // NUEVO
          title: '🚩 No se pudo conectar', // NUEVO
          message: 'Verificá tu conexión e intentá de nuevo', // NUEVO
          type: 'login_error', // NUEVO
        ); // NUEVO
      }
      return null;
    }
  }
  /// Apple Sign-In (solo iOS, upgrade desde anónimo o login directo)
  Future<UserCredential?> signInWithApple() async {
    try {
      // Verificar disponibilidad (solo iOS)
      if (!Platform.isIOS) {
        print('⚠️ Apple Sign-In solo disponible en iOS');
        return null;
      }

      if (!await SignInWithApple.isAvailable()) {
        print('⚠️ Apple Sign-In no disponible en este dispositivo');
        return null;
      }

      // 1. Generar nonce para seguridad
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // 2. Iniciar proceso de login con Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // 3. Crear credencial de Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // 4. Autenticar con Firebase (upgrade automático si era anónimo)
      final result = await _auth.signInWithCredential(oauthCredential);

      // 5. Actualizar displayName si es la primera vez (Apple no siempre lo manda)
      if (result.user?.displayName == null && appleCredential.givenName != null) {
        await result.user?.updateDisplayName(
          '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim(),
        );
      }

      print('✅ Apple Sign-In exitoso: ${result.user?.displayName ?? result.user?.email}');
      await NotificationsProvider.instance.addNotification( // NUEVO
        title: '🤗 ¡Ya estás dentro!', // NUEVO
        message: 'Bienvenido ${result.user?.displayName ?? result.user?.email}', // NUEVO
        type: 'login_success', // NUEVO
      );
      return result;

    } catch (e) {
      print('❌ Error en Apple Sign-In: $e');

      if (!e.toString().contains('cancel')) { // NUEVO
        await NotificationsProvider.instance.addNotification( // NUEVO
          title: '🚩 No se pudo conectar', // NUEVO
          message: 'Verificá tu conexión e intentá de nuevo', // NUEVO
          type: 'login_error', // NUEVO
        ); // NUEVO
      }

      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut(); // Firebase logout
      await _googleSignIn.signOut(); // Google cleanup // CAMBIO

      await signInAnonymously(); // Volver a anónimo // CAMBIO
      print('✅ Logout completo'); // CAMBIO
    } catch (e) {
      print('❌ Error en logout: $e');
    }
  }

  /// Usuario actual (puede ser anónimo o autenticado)
  User? get currentUser => _auth.currentUser;

  /// Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Verificar si el usuario está logueado (no anónimo)
  bool get isLoggedIn => currentUser != null && !currentUser!.isAnonymous;

  /// Verificar si el usuario es anónimo
  bool get isAnonymous => currentUser?.isAnonymous ?? true;


// HELPERS PRIVADOS

  /// Generar nonce aleatorio para Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Generar hash SHA256 del nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

}