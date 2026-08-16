import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'cloud_store.dart';

class FirebaseCloudStore implements CloudStore {
  FirebaseCloudStore({
    required this.uid,
    FirebaseStorage? storage,
  }) : _storage = storage ?? FirebaseStorage.instance;

  final String uid;
  final FirebaseStorage _storage;

  Reference _ref(String key) => _storage.ref('users/$uid/$key');

  @override
  Future<void> put(
    String key,
    Uint8List bytes, {
    String? contentType,
  }) async {
    await _ref(key).putData(
      bytes,
      contentType == null ? null : SettableMetadata(contentType: contentType),
    );
  }

  @override
  Future<Uint8List?> get(String key) async {
    try {
      return await _ref(key).getData(20 * 1024 * 1024);
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return null;
      rethrow;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _ref(key).delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return;
      rethrow;
    }
  }
}
