import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../sync/firebase_bootstrap.dart';

class AppAuthState {
  const AppAuthState({required this.firebaseAvailable, this.user, this.error});

  final bool firebaseAvailable;
  final User? user;
  final String? error;

  bool get signedIn => user != null;
}

class AuthRepository extends StateNotifier<AppAuthState> {
  AuthRepository(this._bootstrap)
    : super(AppAuthState(firebaseAvailable: _bootstrap.available)) {
    if (_bootstrap.available) {
      _subscription = FirebaseAuth.instance.authStateChanges().listen(
        (user) => state = AppAuthState(firebaseAvailable: true, user: user),
      );
    }
  }

  final FirebaseBootstrap _bootstrap;
  StreamSubscription<User?>? _subscription;

  void _requireFirebase() {
    if (!_bootstrap.available) {
      throw StateError('Firebase ist noch nicht eingerichtet.');
    }
  }

  Future<void> signInWithGoogle() async {
    _requireFirebase();
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        await GoogleSignIn.instance.initialize();
        final account = await GoogleSignIn.instance.authenticate();
        final authentication = account.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: authentication.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      await _ensureProfile();
    } catch (error) {
      state = AppAuthState(
        firebaseAvailable: true,
        user: FirebaseAuth.instance.currentUser,
        error: '$error',
      );
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    _requireFirebase();
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        final provider = AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');
        await FirebaseAuth.instance.signInWithProvider(provider);
      } else {
        final rawNonce = _nonce();
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        );
        final credential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      await _ensureProfile();
    } catch (error) {
      state = AppAuthState(
        firebaseAvailable: true,
        user: FirebaseAuth.instance.currentUser,
        error: _friendlyAppleError(error),
      );
      throw StateError(_friendlyAppleError(error));
    }
  }

  String _friendlyAppleError(Object error) {
    final raw = '$error';
    final lower = raw.toLowerCase();
    if (lower.contains('1000') ||
        lower.contains('authorizationerrorcode.unknown') ||
        lower.contains('authorizationerror')) {
      return 'Apple-Anmeldung braucht eine vom App Store oder TestFlight '
          'signierte Notis-Version. Sideload ohne gültiges Provisioning '
          'scheitert mit Fehler 1000. Auf dem Gerät muss ein Apple-Konto '
          'angemeldet sein, und in Firebase muss der Apple-Anbieter aktiv sein.';
    }
    if (lower.contains('canceled') || lower.contains('cancelled')) {
      return 'Apple-Anmeldung abgebrochen.';
    }
    return raw;
  }

  Future<void> signOut() async {
    _requireFirebase();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _ensureProfile() async {
    // Profile creation is handled by the sync adapter on the first sync.
  }

  String _nonce() {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthRepository, AppAuthState>((ref) {
  return AuthRepository(ref.watch(firebaseBootstrapProvider));
});
