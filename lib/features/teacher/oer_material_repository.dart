import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../sync/firebase_bootstrap.dart';
import 'teacher_models.dart';

class OerMaterialRepository {
  OerMaterialRepository(this._firebaseAvailable);

  final bool _firebaseAvailable;

  bool get available =>
      _firebaseAvailable && FirebaseAuth.instance.currentUser != null;

  Stream<List<TeacherMaterial>> watchApproved() {
    if (!available) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('oer_materials')
        .where('status', isEqualTo: 'approved')
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              TeacherMaterial.fromJson({
                ...doc.data(),
                'id': doc.id,
                'isOer': true,
              }),
          ],
        );
  }

  Future<void> submit({
    required Uint8List bytes,
    required String fileName,
    required String title,
    required String subject,
    required String grade,
    required String germanState,
    required int durationMinutes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (!_firebaseAvailable || user == null) {
      throw StateError('authentication_required');
    }
    final id = const Uuid().v4();
    final storageRef = FirebaseStorage.instance.ref(
      'oer_materials/${user.uid}/$id/$fileName',
    );
    await storageRef.putData(
      bytes,
      SettableMetadata(customMetadata: {'ownerUid': user.uid}),
    );
    final url = await storageRef.getDownloadURL();
    await FirebaseFirestore.instance.collection('oer_materials').doc(id).set({
      'title': title,
      'subject': subject,
      'grade': grade,
      'germanState': germanState,
      'durationMinutes': durationMinutes,
      'cloudUrl': url,
      'sharedBy': user.displayName ?? 'Lehrkraft',
      'ownerUid': user.uid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadPrivate({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (!_firebaseAvailable || user == null) {
      throw StateError('authentication_required');
    }
    final id = const Uuid().v4();
    final storageRef = FirebaseStorage.instance.ref(
      'users/${user.uid}/teacher_materials/$id/$fileName',
    );
    await storageRef.putData(
      bytes,
      SettableMetadata(customMetadata: {'ownerUid': user.uid}),
    );
    return storageRef.getDownloadURL();
  }
}

final oerMaterialRepositoryProvider = Provider<OerMaterialRepository>((ref) {
  return OerMaterialRepository(ref.watch(firebaseBootstrapProvider).available);
});

final approvedOerMaterialsProvider =
    StreamProvider.autoDispose<List<TeacherMaterial>>((ref) {
      return ref.watch(oerMaterialRepositoryProvider).watchApproved();
    });
