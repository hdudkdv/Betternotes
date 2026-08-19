import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// True when the signed-in Firebase user used Sign in with Apple.
bool usesAppleSignIn(Iterable<String> providerIds) =>
    providerIds.contains('apple.com');

/// True when the signed-in Firebase user used Google.
bool usesGoogleSignIn(Iterable<String> providerIds) =>
    providerIds.contains('google.com');

/// Deletes cloud documents and files that belong to [uid].
///
/// Auth deletion is separate so Apple's token can still be revoked afterwards.
Future<void> wipeAccountCloudData({
  required String uid,
  FirebaseFirestore? firestore,
  FirebaseStorage? storage,
}) async {
  final db = firestore ?? FirebaseFirestore.instance;
  final files = storage ?? FirebaseStorage.instance;
  final user = db.collection('users').doc(uid);

  final notebooks = await user.collection('notebooks').get();
  for (final notebook in notebooks.docs) {
    await _deleteCollection(notebook.reference.collection('pages'));
    await notebook.reference.delete();
  }

  await _deleteCollection(user.collection('sync_ops'));
  await _deleteCollection(user.collection('meta'));
  await _deleteCollection(user.collection('presence'));
  await _deleteCollection(user.collection('live'));
  await user.delete();

  final owned = await db
      .collection('collaborations')
      .where('ownerUid', isEqualTo: uid)
      .get();
  for (final doc in owned.docs) {
    await _deleteCollection(doc.reference.collection('live_sessions'));
    await _deleteCollection(doc.reference.collection('comments'));
    await _deleteCollection(doc.reference.collection('activity'));
    await doc.reference.delete();
  }

  final materials = await db
      .collection('oer_materials')
      .where('ownerUid', isEqualTo: uid)
      .get();
  for (final doc in materials.docs) {
    await doc.reference.delete();
  }

  await _deleteStoragePrefix(files.ref('users/$uid'));
  await _deleteStoragePrefix(files.ref('oer_materials/$uid'));
}

Future<void> _deleteCollection(
  CollectionReference<Map<String, dynamic>> collection,
) async {
  while (true) {
    final snap = await collection.limit(100).get();
    if (snap.docs.isEmpty) return;
    final batch = collection.firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

Future<void> _deleteStoragePrefix(Reference ref) async {
  try {
    final list = await ref.listAll();
    for (final item in list.items) {
      try {
        await item.delete();
      } catch (_) {}
    }
    for (final prefix in list.prefixes) {
      await _deleteStoragePrefix(prefix);
    }
  } catch (_) {}
}
