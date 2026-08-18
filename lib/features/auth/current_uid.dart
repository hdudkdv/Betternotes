import 'package:firebase_auth/firebase_auth.dart';

String? currentAuthUid() {
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    return null;
  }
}
