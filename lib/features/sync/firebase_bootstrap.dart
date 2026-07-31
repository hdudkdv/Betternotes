import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

/// Firebase is optional until `flutterfire configure` has added the platform
/// files. This keeps the local-first app usable during development and offline.
class FirebaseBootstrap {
  const FirebaseBootstrap._({required this.available, this.error});

  final bool available;
  final String? error;

  static Future<FirebaseBootstrap> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return const FirebaseBootstrap._(available: true);
    } on FirebaseException catch (error) {
      return FirebaseBootstrap._(available: false, error: error.message);
    } catch (error) {
      return FirebaseBootstrap._(available: false, error: '$error');
    }
  }
}

final firebaseBootstrapProvider = Provider<FirebaseBootstrap>((ref) {
  return const FirebaseBootstrap._(available: false);
});
