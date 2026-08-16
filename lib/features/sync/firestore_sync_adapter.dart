import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../shared/utils/file_store.dart';
import 'cloud_store.dart';
import 'cloud_store_factory.dart';
import 'page_cloud_codec.dart';
import 'sync_merge.dart';

/// User-scoped transport: Firestore holds tiny pointers, [CloudStore] holds
/// gzip page bodies and binary assets.
class FirestoreSyncAdapter {
  FirestoreSyncAdapter(
    this._repository, {
    required SharedPreferences preferences,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    CloudStore? store,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storageOverride = storage,
       _storeOverride = store,
       _preferences = preferences;

  final NotebookRepository _repository;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SharedPreferences _preferences;
  FirebaseStorage? _storageOverride;
  CloudStore? _storeOverride;
  final FileStore _files = createFileStore();

  FirebaseStorage get _storage => _storageOverride ??= FirebaseStorage.instance;

  CloudStore get _store {
    return _storeOverride ??= createCloudStore(
      uid: _uid,
      storage: _storage,
    );
  }

  static const _appStateKeys = <String>[
    'plannerV1',
    'timetableV2',
    'entitlementsV1',
    'toolPresetsV1',
    'userRole',
    'teacherTrack',
    'teacherWorkspaceV1',
    'classroomAutoConnectSubject',
    'classroomAutoConnectRoom',
  ];
  static const _appBoolStateKeys = <String>[
    'classroomAutoConnectEnabled',
    'classroomAutoConnectAsked',
    'profileSetupCompleted',
    'tutorialCompleted',
  ];

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Nicht angemeldet.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _user =>
      _firestore.collection('users').doc(_uid);

  String get _cursorKey => 'cloudPullCursorV1_$_uid';

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
    payload.remove('searchIndex');
    final now = DateTime.now().toIso8601String();
    switch (operation.entityType) {
      case 'notebook':
        await _user.collection('notebooks').doc(operation.entityId).set({
          ...payload,
          'updatedAt': payload['updatedAt'] ?? now,
        }, SetOptions(merge: true));
      case 'page':
        final page = NotePage.fromJson(payload);
        await _pushPage(page);
      case 'delete_notebook':
        final pages = await _user
            .collection('notebooks')
            .doc(operation.entityId)
            .collection('pages')
            .get();
        for (final doc in pages.docs) {
          final blobKey = doc.data()['blobKey']?.toString();
          if (blobKey != null && blobKey.isNotEmpty) {
            await _store.delete(blobKey);
          }
          await doc.reference.delete();
        }
        await _user.collection('notebooks').doc(operation.entityId).delete();
      case 'delete_page':
        final notebookId = payload['notebookId']?.toString();
        if (notebookId == null || notebookId.isEmpty) {
          throw const FormatException('delete_page ohne notebookId');
        }
        final pageRef = _user
            .collection('notebooks')
            .doc(notebookId)
            .collection('pages')
            .doc(operation.entityId);
        final existing = await pageRef.get();
        final blobKey = existing.data()?['blobKey']?.toString();
        if (blobKey != null && blobKey.isNotEmpty) {
          await _store.delete(blobKey);
        }
        await pageRef.delete();
        await _touchNotebook(notebookId);
      case 'crdt':
      case 'checkpoint':
        return;
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

  Future<void> _pushPage(NotePage page) async {
    final body = await _rewriteAssetsForUpload(PageCloudCodec.bodyJson(page));
    final hash = PageCloudCodec.hashBody(body);
    final blobKey = 'pages/${page.id}/$hash.bin';
    await _store.put(
      blobKey,
      PageCloudCodec.encodeBody(body),
      contentType: 'application/gzip',
    );
    final pointer = PageCloudCodec.pointer(
      page: page,
      contentHash: hash,
      blobKey: blobKey,
      assetKeys: [
        for (final value in body.values)
          if (value is String && PageCloudCodec.isRemotePath(value))
            PageCloudCodec.keyFromCloudPath(value)!,
      ],
    );
    await _user
        .collection('notebooks')
        .doc(page.notebookId)
        .collection('pages')
        .doc(page.id)
        .set(pointer, SetOptions(merge: true));
    await _touchNotebook(page.notebookId);
  }

  Future<void> _touchNotebook(String notebookId) async {
    await _user.collection('notebooks').doc(notebookId).set({
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> _rewriteAssetsForUpload(
    Map<String, dynamic> body,
  ) async {
    final next = Map<String, dynamic>.from(body);
    final background = next['backgroundPdfPath']?.toString();
    if (PageCloudCodec.isUploadablePath(background)) {
      next['backgroundPdfPath'] = PageCloudCodec.cloudPath(
        await _uploadAsset(background!),
      );
    }
    final images = next['images'];
    if (images is List) {
      next['images'] = [
        for (final item in images)
          if (item is Map)
            await _rewriteImage(Map<String, dynamic>.from(item))
          else
            item,
      ];
    }
    return next;
  }

  Future<Map<String, dynamic>> _rewriteImage(Map<String, dynamic> image) async {
    final path = image['localPath']?.toString();
    if (!PageCloudCodec.isUploadablePath(path)) return image;
    return {...image, 'localPath': PageCloudCodec.cloudPath(await _uploadAsset(path!))};
  }

  Future<String> _uploadAsset(String path) async {
    final bytes = await _files.readBytes(path);
    final hash = sha256.convert(bytes).toString();
    final ext = p.extension(path).replaceFirst('.', '');
    final key = 'assets/$hash${ext.isEmpty ? '' : '.$ext'}';
    await _store.put(key, bytes);
    return key;
  }

  Future<Map<String, dynamic>> _hydrateAssets(
    Map<String, dynamic> body,
  ) async {
    final filesDir = await _repository.resolveFilesDir();
    final next = Map<String, dynamic>.from(body);
    final background = next['backgroundPdfPath']?.toString();
    final bgKey = PageCloudCodec.keyFromCloudPath(background);
    if (bgKey != null) {
      next['backgroundPdfPath'] = await _downloadAsset(filesDir, bgKey);
    }
    final images = next['images'];
    if (images is List) {
      next['images'] = [
        for (final item in images)
          if (item is Map)
            await _hydrateImage(filesDir, Map<String, dynamic>.from(item))
          else
            item,
      ];
    }
    return next;
  }

  Future<Map<String, dynamic>> _hydrateImage(
    String filesDir,
    Map<String, dynamic> image,
  ) async {
    final key = PageCloudCodec.keyFromCloudPath(image['localPath']?.toString());
    if (key == null) return image;
    return {...image, 'localPath': await _downloadAsset(filesDir, key)};
  }

  Future<String> _downloadAsset(String filesDir, String key) async {
    final name = key.replaceAll('/', '_');
    final dest = p.join(filesDir, 'cloud_$name');
    try {
      await _files.readBytes(dest);
      return dest;
    } catch (_) {}
    final bytes = await _store.get(key);
    if (bytes == null) return PageCloudCodec.cloudPath(key);
    await _files.writeBytes(dest, bytes);
    return dest;
  }

  /// Imports remote notebooks and pages, merging list fields by id when both
  /// sides have content (CRDT-oriented block merge).
  Future<void> pullRemoteChanges({
    bool full = false,
    bool preferRemote = false,
  }) async {
    final cursor = full ? null : _preferences.getString(_cursorKey);
    Query<Map<String, dynamic>> query = _user.collection('notebooks');
    if (cursor != null && cursor.isNotEmpty) {
      query = query.where('updatedAt', isGreaterThan: cursor);
    }
    QuerySnapshot<Map<String, dynamic>> remoteNotebooks;
    try {
      remoteNotebooks = await query.get();
    } catch (_) {
      remoteNotebooks = await _user.collection('notebooks').get();
    }

    String? newest = cursor;
    for (final remote in remoteNotebooks.docs) {
      final data = remote.data();
      if (!data.containsKey('id')) continue;
      final notebook = Notebook.fromJson(data);
      final stamp = data['updatedAt']?.toString();
      if (stamp != null && (newest == null || stamp.compareTo(newest) > 0)) {
        newest = stamp;
      }
      final local = await _repository.getNotebook(notebook.id);
      if (local == null ||
          preferRemote ||
          notebook.updatedAt.isAfter(local.updatedAt)) {
        await _repository.upsertRemoteNotebook(notebook);
      }

      Query<Map<String, dynamic>> pageQuery = remote.reference.collection(
        'pages',
      );
      if (cursor != null && cursor.isNotEmpty && !full) {
        pageQuery = pageQuery.where('updatedAt', isGreaterThan: cursor);
      }
      QuerySnapshot<Map<String, dynamic>> remotePages;
      try {
        remotePages = await pageQuery.get();
      } catch (_) {
        remotePages = await remote.reference.collection('pages').get();
      }
      for (final remotePage in remotePages.docs) {
        final pageData = remotePage.data();
        if (!pageData.containsKey('id')) continue;
        final pageStamp = pageData['updatedAt']?.toString();
        if (pageStamp != null &&
            (newest == null || pageStamp.compareTo(newest) > 0)) {
          newest = pageStamp;
        }
        final remoteNote = await _materializePage(pageData);
        if (remoteNote == null) continue;
        final localPage = await _repository.getPage(remoteNote.id);
        final remoteUpdated = remoteNote.updatedAt ?? notebook.updatedAt;
        final localUpdated = localPage?.updatedAt ?? local?.updatedAt;
        if (localPage == null || preferRemote) {
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
            localUpdated:
                localUpdated ?? DateTime.fromMillisecondsSinceEpoch(0),
            remoteUpdated: remoteUpdated,
          ),
        );
        await _repository.upsertRemotePage(merged);
      }
    }
    if (newest != null && newest.isNotEmpty) {
      await _preferences.setString(_cursorKey, newest);
    }
  }

  Future<NotePage?> _materializePage(Map<String, dynamic> data) async {
    if (!PageCloudCodec.isPointer(data)) {
      final copy = Map<String, dynamic>.from(data)..remove('searchIndex');
      return NotePage.fromJson(copy);
    }
    final blobKey = data['blobKey']?.toString();
    if (blobKey == null || blobKey.isEmpty) return null;
    final bytes = await _store.get(blobKey);
    if (bytes == null) return null;
    final body = await _hydrateAssets(PageCloudCodec.decodeBody(bytes));
    body['updatedAt'] = data['updatedAt'] ?? body['updatedAt'];
    body.remove('searchIndex');
    return NotePage.fromJson(body);
  }

  /// Synchronizes small app-wide JSON documents (planner, timetable and local
  /// entitlement state). The first signed-in device imports an existing cloud
  /// copy once; later calls publish its current local state.
  Future<void> syncAppState({bool preferRemote = false}) async {
    final document = await _user.collection('meta').doc('app_state').get();
    final loadedKey = 'cloudStateLoadedV1_$_uid';
    if ((preferRemote || _preferences.getBool(loadedKey) != true) &&
        document.exists) {
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
        await _pushPage(page);
      }
    }
  }

  /// Binary attachment primitive for PDF backgrounds, images and grade scans.
  Future<String> uploadBytes({
    required String remotePath,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await _store.put(remotePath, bytes, contentType: contentType);
    return remotePath;
  }
}
