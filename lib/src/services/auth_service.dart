// lib/src/services/auth_service.dart

import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

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
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Asegurar que Google Sign-In esté inicializado
      await initializeGoogleSignIn();

      // Verificar si la plataforma soporta autenticación
      if (!_googleSignIn.supportsAuthenticate()) {
        print('❌ Plataforma no soporta Google Sign-In');
        return null;
      }

      // 1. Autenticar con Google usando la nueva API
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 2. Obtener authentication (ahora es síncrono)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Crear credencial de Firebase usando solo idToken (nuevo patrón)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Autenticar con Firebase (upgrade automático si era anónimo)
      final result = await _auth.signInWithCredential(credential);

      print('✅ Google Sign-In exitoso: ${result.user?.displayName}');
      return result;

    } catch (e) {
      print('❌ Error en Google Sign-In: $e');
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
      return result;

    } catch (e) {
      print('❌ Error en Apple Sign-In: $e');
      return null;
    }
  }

  /// Cerrar sesión (vuelve a anónimo automáticamente)
  Future<void> signOut() async {
    try {
      // Cerrar sesión de Firebase primero
      await _auth.signOut();

      // Cerrar sesión de Google si está disponible
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('⚠️ Error cerrando Google Sign-In: $e');
      }

      // Automáticamente vuelve a anónimo
      await signInAnonymously();

      print('✅ Logout exitoso - Usuario vuelve a anónimo');
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