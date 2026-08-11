import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_auth_constants.dart';

class AuthRepository {
  AuthRepository({this._auth});

  FirebaseAuth? _auth;
  bool _googleInitialized = false;

  bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth get auth {
    if (!isFirebaseReady) {
      throw StateError('Firebase não inicializado');
    }
    return _auth ??= FirebaseAuth.instance;
  }

  User? get currentUser {
    if (!isFirebaseReady) return null;
    return auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    if (!isFirebaseReady) return const Stream.empty();
    return auth.authStateChanges();
  }

  bool get isSignedIn => currentUser != null;

  Future<void> initializeGoogleSignIn() async {
    if (!isFirebaseReady || _googleInitialized) return;
    if (kIsWeb) {
      // No web usamos signInWithPopup do Firebase Auth.
      _googleInitialized = true;
      return;
    }
    await GoogleSignIn.instance.initialize(
      serverClientId: FirebaseAuthConstants.webClientId,
    );
    _googleInitialized = true;
  }

  /// Login com Google → Firebase Auth.
  /// Após sucesso, o UID fica estável e o sync do Firestore funciona.
  Future<User> signInWithGoogle() async {
    if (!isFirebaseReady) {
      throw StateError('Firebase não inicializado');
    }

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final cred = await auth.signInWithPopup(provider);
      final user = cred.user;
      if (user == null) {
        throw StateError('Login cancelado ou sem usuário.');
      }
      return user;
    }

    await initializeGoogleSignIn();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError(
        'Login com Google não suportado nesta plataforma. Use Android ou Web.',
      );
    }

    final googleUser = await GoogleSignIn.instance.authenticate(
      scopeHint: const ['email', 'profile'],
    );

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw StateError(
        'Não foi possível obter idToken do Google. '
        'Verifique o Web client ID (serverClientId) no Firebase Console.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final cred = await auth.signInWithCredential(credential);
    final user = cred.user;
    if (user == null) {
      throw StateError('Login com Google falhou.');
    }
    return user;
  }

  Future<void> signOut() async {
    if (!isFirebaseReady) return;
    try {
      if (!kIsWeb && _googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    await auth.signOut();
  }
}
