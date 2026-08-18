import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';
import '../sync/firestore_sync_adapter.dart';
import 'notebook_crypto.dart';

enum LibraryHandoverAction { deleteLocal, saveToCloud, lockLocal }

class AccountLibraryService {
  AccountLibraryService(
    this._repo,
    this._prefs, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final NotebookRepository _repo;
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;

  static const lastUidKey = 'lastAuthUidV1';

  static final Map<String, Uint8List> _vaultMemory = {};

  String? get lastUid => _prefs.getString(lastUidKey);

  Future<void> rememberUid(String? uid) async {
    if (uid == null || uid.isEmpty) {
      await _prefs.remove(lastUidKey);
      return;
    }
    await _prefs.setString(lastUidKey, uid);
  }

  List<Notebook> plaintextForeign(List<Notebook> notebooks, String? viewerUid) {
    return [
      for (final notebook in notebooks)
        if (!notebook.locked &&
            notebook.ownerUid != null &&
            notebook.ownerUid != viewerUid)
          notebook,
    ];
  }

  List<Notebook> unsignedOrOwned(
    List<Notebook> notebooks,
    String? ownerUid,
  ) {
    return [
      for (final notebook in notebooks)
        if (!notebook.locked &&
            (notebook.ownerUid == null || notebook.ownerUid == ownerUid))
          notebook,
    ];
  }

  Future<void> stampUnlocked({required String ownerUid}) async {
    for (final notebook in await _repo.getNotebooks()) {
      if (notebook.locked) continue;
      if (notebook.ownerUid == ownerUid) continue;
      if (notebook.ownerUid != null) continue;
      await _repo.setNotebookAccess(
        notebook.id,
        ownerUid: ownerUid,
        locked: false,
      );
    }
  }

  Future<void> deleteLocal(List<Notebook> notebooks) async {
    for (final notebook in notebooks) {
      await _repo.deleteLocalNotebookOnly(notebook.id);
    }
  }

  Future<void> saveToCloudThenRemoveLocal(List<Notebook> notebooks) async {
    final adapter = FirestoreSyncAdapter(_repo, preferences: _prefs);
    await adapter.pushLocalSnapshot();
    await deleteLocal(notebooks);
  }

  Future<void> lockLocal(List<Notebook> notebooks, {required String ownerUid}) async {
    final key = await ensureVaultKey(ownerUid);
    for (final notebook in notebooks) {
      if (notebook.locked) continue;
      final pages = await _repo.getPages(notebook.id);
      final blob = NotebookCrypto.encrypt(
        jsonEncode(pages.map((page) => page.toJson()).toList()),
        key,
      );
      await _repo.writeKv('locked_blob_${notebook.id}', blob);
      for (final page in pages) {
        await _repo.upsertRemotePage(
          page.copyWith(
            strokes: const [],
            textBlocks: const [],
            shapes: const [],
            images: const [],
            stickers: const [],
            searchIndex: '',
            clearBackgroundPdf: true,
          ),
        );
      }
      await _repo.setNotebookAccess(
        notebook.id,
        ownerUid: ownerUid,
        locked: true,
      );
    }
  }

  Future<void> unlockOwned(String ownerUid) async {
    Uint8List? key;
    for (final notebook in await _repo.getNotebooks()) {
      if (!notebook.locked || notebook.ownerUid != ownerUid) continue;
      key ??= await ensureVaultKey(ownerUid);
      final raw = await _repo.readKv('locked_blob_${notebook.id}');
      if (raw == null || raw.isEmpty) {
        await _repo.setNotebookAccess(
          notebook.id,
          ownerUid: ownerUid,
          locked: false,
        );
        continue;
      }
      final decoded = jsonDecode(NotebookCrypto.decrypt(raw, key)) as List;
      for (final item in decoded) {
        await _repo.upsertRemotePage(
          NotePage.fromJson(Map<String, dynamic>.from(item as Map)),
        );
      }
      await _repo.deleteKv('locked_blob_${notebook.id}');
      await _repo.setNotebookAccess(
        notebook.id,
        ownerUid: ownerUid,
        locked: false,
      );
    }
  }

  Future<Uint8List> ensureVaultKey(String uid) async {
    final cached = _vaultMemory[uid];
    if (cached != null) return cached;
    final doc = _firestore
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('local_vault');
    final snap = await doc.get();
    final existing = snap.data()?['key'] as String?;
    if (existing != null && existing.isNotEmpty) {
      final key = Uint8List.fromList(base64Decode(existing));
      _vaultMemory[uid] = key;
      return key;
    }
    final key = Uint8List(32);
    final rng = Random.secure();
    for (var i = 0; i < key.length; i++) {
      key[i] = rng.nextInt(256);
    }
    await doc.set({
      'key': base64Encode(key),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _vaultMemory[uid] = key;
    return key;
  }

  static void forgetVault(String? uid) {
    if (uid == null) {
      _vaultMemory.clear();
      return;
    }
    _vaultMemory.remove(uid);
  }
}
