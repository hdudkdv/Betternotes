import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

enum CollaborationRole { viewer, editor, teacher, student }

class CollaborationService extends ChangeNotifier {
  CollaborationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Anmeldung erforderlich.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _session(String notebookId) =>
      _firestore.collection('collaborations').doc(notebookId);

  Future<void> invite({
    required String notebookId,
    required String memberUid,
    required CollaborationRole role,
  }) async {
    final ownerUid = _uid;
    await _session(notebookId).set({
      'notebookId': notebookId,
      'ownerUid': ownerUid,
      'members': {
        ownerUid: CollaborationRole.teacher.name,
        memberUid.trim(): role.name,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> revoke({
    required String notebookId,
    required String memberUid,
  }) async {
    await _session(notebookId).update({
      'members.${memberUid.trim()}': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> startLiveSession(String notebookId) async {
    final id = const Uuid().v4();
    await _session(notebookId).collection('live_sessions').doc(id).set({
      'id': id,
      'ownerUid': _uid,
      'active': true,
      'startedAt': FieldValue.serverTimestamp(),
      'participants': {
        _uid: {'joinedAt': DateTime.now().toIso8601String()},
      },
    });
    return id;
  }

  Future<void> joinLiveSession({
    required String notebookId,
    required String sessionId,
    required String pageId,
  }) async {
    await _session(notebookId).collection('live_sessions').doc(sessionId).set({
      'participants.$_uid': {
        'joinedAt': DateTime.now().toIso8601String(),
        'pageId': pageId,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchCollaboration(String notebookId) =>
      _session(notebookId).snapshots().map((snapshot) => snapshot.data());

  Stream<List<CollaborationComment>> watchComments(String notebookId) =>
      _session(notebookId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (document) => CollaborationComment.fromJson(
                    document.id,
                    document.data(),
                  ),
                )
                .toList(),
          );

  Future<void> addComment({
    required String notebookId,
    required String message,
    String? pageId,
  }) async {
    final text = message.trim();
    if (text.isEmpty) return;
    await _session(notebookId).collection('comments').add({
      'authorUid': _uid,
      'message': text,
      'pageId': pageId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordChange({
    required String notebookId,
    required String type,
    String? pageId,
  }) async {
    await _session(notebookId).collection('activity').add({
      'authorUid': _uid,
      'type': type,
      'pageId': pageId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<CollaborationActivity>> watchActivity(String notebookId) =>
      _session(notebookId)
          .collection('activity')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (document) => CollaborationActivity.fromJson(
                    document.id,
                    document.data(),
                  ),
                )
                .toList(),
          );
}

class CollaborationComment {
  const CollaborationComment({
    required this.id,
    required this.authorUid,
    required this.message,
    required this.createdAt,
    this.pageId,
  });

  final String id;
  final String authorUid;
  final String message;
  final DateTime? createdAt;
  final String? pageId;

  factory CollaborationComment.fromJson(String id, Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return CollaborationComment(
      id: id,
      authorUid: json['authorUid'] as String? ?? '',
      message: json['message'] as String? ?? '',
      pageId: json['pageId'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class CollaborationActivity {
  const CollaborationActivity({
    required this.id,
    required this.authorUid,
    required this.type,
    required this.createdAt,
    this.pageId,
  });

  final String id;
  final String authorUid;
  final String type;
  final DateTime? createdAt;
  final String? pageId;

  factory CollaborationActivity.fromJson(String id, Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return CollaborationActivity(
      id: id,
      authorUid: json['authorUid'] as String? ?? '',
      type: json['type'] as String? ?? '',
      pageId: json['pageId'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

final collaborationServiceProvider = Provider<CollaborationService>(
  (ref) => CollaborationService(),
);
