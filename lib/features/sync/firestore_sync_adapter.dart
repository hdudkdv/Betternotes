import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';
import 'sync_merge.dart';

/// User-scoped Firestore transport. Local persistence remains authoritative:
/// this adapter is called only after a change has been committed locally.
class FirestoreSyncAdapter {
  FirestoreSyncAdapter(
    this._repository, {
    required SharedPreferences preferences,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storageOverride = storage,
       _preferences = preferences;

  final NotebookRepository _repository;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  FirebaseStorage? _storageOverride;
  final SharedPreferences _preferences;

  FirebaseStorage get _storage => _storageOverride ??= FirebaseStorage.instance;

  static const _appStateKeys = <String>[
    'plannerV1',
    'timetableV2',
    'entitlementsV1',
    'toolPresetsV1',
    'userRole',
    'teacherWorkspaceV1',
    'classroomAutoConnectSubject',
    'classroomAutoConnectRoom',
  ];
  static const _appBoolStateKeys = <String>[
    'classroomAutoConnectEnabled',
    'classroomAutoConnectAsked',
  ];

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Nicht angemeldet.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _user =>
      _firestore.collection('users').doc(_uid);

  Future<void> ensureProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _user.set({
      'displayName': user.displayName,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> push(SyncOp operation) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(operation.payloadJson) as Map,
    );
    final now = DateTime.now().toIso8601String();
    switch (operation.entityType) {
      case 'notebook':
        await _user.collection('notebooks').doc(operation.entityId).set({
          ...payload,
          'updatedAt': payload['updatedAt'] ?? now,
        }, SetOptions(merge: true));
      case 'page':
        final notebookId = payload['notebookId']?.toString();
        if (notebookId == null || notebookId.isEmpty) {
          throw const FormatException('Page ohne notebookId');
        }
        await _user
            .collection('notebooks')
            .doc(notebookId)
            .collection('pages')
            .doc(operation.entityId)
            .set({
              ...payload,
              'updatedAt': payload['updatedAt'] ?? now,
            }, SetOptions(merge: true));
      case 'delete_notebook':
        final pages = await _user
            .collection('notebooks')
            .doc(operation.entityId)
            .collection('pages')
            .get();
        for (final doc in pages.docs) {
          await doc.reference.delete();
        }
        await _user.collection('notebooks').doc(operation.entityId).delete();
      case 'delete_page':
        final notebookId = payload['notebookId']?.toString();
        if (notebookId == null || notebookId.isEmpty) {
          throw const FormatException('delete_page ohne notebookId');
        }
        await _user
            .collection('notebooks')
            .doc(notebookId)
            .collection('pages')
            .doc(operation.entityId)
            .delete();
      default:
        await _user.collection('sync_ops').doc(operation.id).set({
          'entityType': operation.entityType,
          'entityId': operation.entityId,
          'payload': payload,
          'createdAt': operation.createdAt.toIso8601String(),
          'updatedAt': now,
        });
    }
  }

  /// Imports remote notebooks and pages, merging list fields by id when both
  /// sides have content (CRDT-oriented block merge).
  Future<void> pullRemoteChanges() async {
    final remoteNotebooks = await _user.collection('notebooks').get();
    for (final remote in remoteNotebooks.docs) {
      final data = remote.data();
      if (!data.containsKey('id')) continue;
      final notebook = Notebook.fromJson(data);
      final local = await _repository.getNotebook(notebook.id);
      if (local == null || notebook.updatedAt.isAfter(local.updatedAt)) {
        await _repository.upsertRemoteNotebook(notebook);
      }

      final remotePages = await remote.reference.collection('pages').get();
      for (final remotePage in remotePages.docs) {
        final pageData = remotePage.data();
        if (!pageData.containsKey('id')) continue;
        final remoteNote = NotePage.fromJson(pageData);
        final localPage = await _repository.getPage(remoteNote.id);
        final remoteUpdated = remoteNote.updatedAt ?? notebook.updatedAt;
        final localUpdated = localPage?.updatedAt ?? local?.updatedAt;
        if (localPage == null) {
          await _repository.upsertRemotePage(remoteNote);
          continue;
        }
        if (localUpdated != null && !remoteUpdated.isAfter(localUpdated)) {
          continue;
        }
        final merged = NotePage.fromJson(
          SyncMerge.mergeCrdtMaps(
            localPage.toJson(),
            remoteNote.toJson(),
            localUpdated: localUpdated ?? DateTime.fromMillisecondsSinceEpoch(0),
            remoteUpdated: remoteUpdated,
          ),
        );
        await _repository.upsertRemotePage(merged);
      }
    }
  }

  /// Synchronizes small app-wide JSON documents (planner, timetable and local
  /// entitlement state). The first signed-in device imports an existing cloud
  /// copy once; later calls publish its current local state.
  Future<void> syncAppState() async {
    final document = await _user.collection('meta').doc('app_state').get();
    final loadedKey = 'cloudStateLoadedV1_$_uid';
    if (_preferences.getBool(loadedKey) != true && document.exists) {
      final remote = document.data()?['data'];
      if (remote is Map) {
        for (final key in _appStateKeys) {
          final value = remote[key];
          if (value is String && value.isNotEmpty) {
            await _preferences.setString(key, value);
          }
        }
        for (final key in _appBoolStateKeys) {
          final value = remote[key];
          if (value is bool) {
            await _preferences.setBool(key, value);
          }
        }
      }
    }
    await _preferences.setBool(loadedKey, true);
    await _user.collection('meta').doc('app_state').set({
      'data': {
        for (final key in _appStateKeys)
          if (_preferences.getString(key) != null)
            key: _preferences.getString(key),
        for (final key in _appBoolStateKeys)
          if (_preferences.getBool(key) != null)
            key: _preferences.getBool(key),
      },
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// First-login migration for the existing local notebook collection.
  Future<void> pushLocalSnapshot() async {
    await ensureProfile();
    for (final notebook in await _repository.getNotebooks()) {
      await _user
          .collection('notebooks')
          .doc(notebook.id)
          .set(notebook.toJson(), SetOptions(merge: true));
      for (final page in await _repository.getPages(notebook.id)) {
        await _user
            .collection('notebooks')
            .doc(notebook.id)
            .collection('pages')
            .doc(page.id)
            .set({
              ...page.toJson(),
              'updatedAt':
                  page.updatedAt?.toIso8601String() ??
                  notebook.updatedAt.toIso8601String(),
            }, SetOptions(merge: true));
      }
    }
  }

  /// Binary attachment primitive for PDF backgrounds, images and grade scans.
  Future<String> uploadBytes({
    required String remotePath,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final reference = _storage.ref('users/$_uid/$remotePath');
    await reference.putData(
      bytes,
      contentType == null ? null : SettableMetadata(contentType: contentType),
    );
    return reference.getDownloadURL();
  }
}
