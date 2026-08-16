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

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;

  @override
  String toString() => message.isEmpty ? 'AuthFailure' : message;

  static bool looksTechnical(Object error) {
    final lower = '$error'.toLowerCase();
    return lower.contains('typeerror') ||
        lower.contains('jsobject') ||
        lower.contains('javascriptobject') ||
        lower.contains('minified:') ||
        lower.contains('bad state') ||
        lower.contains('stateerror') ||
        lower.contains('instance of') ||
        lower.contains('firebase_auth/') ||
        lower.contains('exception:');
  }

  static AuthFailure map(Object error) {
    if (error is AuthFailure) return error;
    final code = error is FirebaseAuthException ? error.code.toLowerCase() : '';
    final raw = error is FirebaseAuthException
        ? '${error.code} ${error.message ?? ''}'
        : '$error';
    final lower = raw.toLowerCase();
    final cancelled =
        code == 'user-cancelled' ||
        code == 'popup-closed-by-user' ||
        code == 'web-context-cancelled' ||
        code == 'cancelled' ||
        code == 'canceled' ||
        lower.contains('user-cancelled') ||
        lower.contains('popup-closed') ||
        lower.contains('idp denied access') ||
        lower.contains('refuses to grant permission') ||
        lower.contains('authorizationerrorcode.canceled') ||
        (lower.contains('canceled') && !lower.contains('unauthorized')) ||
        (lower.contains('cancelled') && !lower.contains('unauthorized'));
    if (cancelled) {
      return const AuthFailure('', cancelled: true);
    }
    if (lower.contains('unauthorized-domain')) {
      return const AuthFailure(
        'Diese Website ist für die Anmeldung noch nicht freigegeben.',
      );
    }
    if (lower.contains('redirect_uri_mismatch') ||
        lower.contains('redirect-uri-mismatch') ||
        lower.contains('invalid request')) {
      return const AuthFailure(
        'Google-Login auf dem Handy braucht die Redirect-URI '
        'https://notis-notizbuecher.web.app/__/auth/handler '
        'in der Google-Cloud-Konsole.',
      );
    }
    if (lower.contains('1000') ||
        lower.contains('authorizationerrorcode.unknown') ||
        lower.contains('authorizationerror')) {
      return const AuthFailure(
        'Apple-Anmeldung braucht eine vom App Store oder TestFlight '
        'signierte Notis-Version.',
      );
    }
    if (lower.contains('operation-not-allowed') ||
        lower.contains('invalid-client') ||
        lower.contains('unauthorized-client') ||
        lower.contains('invalid-oauth-client-id') ||
        lower.contains('oauth client was not found')) {
      return const AuthFailure(
        'Apple-Anmeldung im Browser ist in Firebase noch nicht eingetragen. '
        'Unter Authentication → Apple die Services-ID und den '
        'Sign-in-with-Apple-Schlüssel speichern.',
      );
    }
    if (lower.contains('network') || lower.contains('unavailable')) {
      return const AuthFailure(
        'Keine Verbindung. Bitte Internet prüfen und nochmal versuchen.',
      );
    }
    return const AuthFailure(
      'Anmeldung hat nicht geklappt. Bitte nochmal versuchen.',
    );
  }
}

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
      throw const AuthFailure('Firebase ist noch nicht eingerichtet.');
    }
  }

  bool get _webUsesRedirect {
    if (!kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  /// Popup can succeed in Firebase while Dart fails to cast the JS result.
  Future<void> _signInWithPopup(AuthProvider provider) async {
    try {
      await FirebaseAuth.instance.signInWithPopup(provider);
    } catch (error) {
      if (FirebaseAuth.instance.currentUser != null) return;
      rethrow;
    }
  }

  Future<void> _signInOnWeb(AuthProvider provider) async {
    if (_webUsesRedirect) {
      await FirebaseAuth.instance.signInWithRedirect(provider);
      return;
    }
    await _signInWithPopup(provider);
  }

  Future<void> signInWithGoogle() async {
    _requireFirebase();
    try {
      if (kIsWeb) {
        await _signInOnWeb(GoogleAuthProvider());
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
      if (FirebaseAuth.instance.currentUser != null) {
        await _ensureProfile();
        return;
      }
      final failure = AuthFailure.map(error);
      state = AppAuthState(
        firebaseAvailable: true,
        user: FirebaseAuth.instance.currentUser,
        error: failure.cancelled ? null : failure.message,
      );
      if (failure.cancelled) return;
      throw failure;
    }
  }

  Future<void> signInWithApple() async {
    _requireFirebase();
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      if (kIsWeb) {
        await _signInOnWeb(provider);
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
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
      if (FirebaseAuth.instance.currentUser != null) {
        await _ensureProfile();
        return;
      }
      final failure = AuthFailure.map(error);
      state = AppAuthState(
        firebaseAvailable: true,
        user: FirebaseAuth.instance.currentUser,
        error: failure.cancelled ? null : failure.message,
      );
      if (failure.cancelled) return;
      throw failure;
    }
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
