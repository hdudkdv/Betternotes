import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../entitlements/entitlement_model.dart';
import '../library/providers/library_providers.dart';

/// Lite may keep this many notebooks in the cloud at once. Pro is unlimited.
const kLiteCloudNotebookLimit = 5;

const kCloudSyncNotebookIdsKey = 'cloudSyncNotebookIdsV1';
const kCloudSyncNotebookIdsInitKey = 'cloudSyncNotebookIdsInitV1';

int? cloudNotebookLimit(PaidTier paid) => switch (paid) {
  PaidTier.free => 0,
  PaidTier.lite => kLiteCloudNotebookLimit,
  PaidTier.pro => null,
};

bool cloudSyncsNotebook(
  String notebookId, {
  required PaidTier paid,
  required Set<String> selected,
}) {
  final limit = cloudNotebookLimit(paid);
  if (limit == null) return true;
  if (limit == 0) return false;
  return selected.contains(notebookId);
}

String? notebookIdForSyncOp(SyncOp op) {
  if (op.entityType == 'page' || op.entityType == 'delete_page') {
    try {
      final payload = jsonDecode(op.payloadJson);
      if (payload is Map) {
        final id = payload['notebookId']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (_) {}
  }
  if (op.entityId.isEmpty) return null;
  return op.entityId;
}

bool shouldPushCloudOp(
  SyncOp op, {
  required PaidTier paid,
  required Set<String> selected,
}) {
  if (op.entityType == 'delete_notebook') {
    return cloudNotebookLimit(paid) != 0;
  }
  final id = notebookIdForSyncOp(op);
  if (id == null) return cloudNotebookLimit(paid) == null;
  return cloudSyncsNotebook(id, paid: paid, selected: selected);
}

class CloudSyncSelection extends ChangeNotifier {
  CloudSyncSelection(this._prefs) {
    _ids = _readIds();
  }

  final SharedPreferences _prefs;
  late Set<String> _ids;

  Set<String> get ids => Set.unmodifiable(_ids);

  Set<String> _readIds() {
    final raw = _prefs.getString(kCloudSyncNotebookIdsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return {
          for (final item in decoded)
            if (item is String && item.isNotEmpty) item,
        };
      }
    } catch (_) {}
    return {};
  }

  Future<void> _persist() async {
    await _prefs.setString(kCloudSyncNotebookIdsKey, jsonEncode(_ids.toList()));
    notifyListeners();
  }

  /// First Lite session: keep the five most recently used notebooks in sync.
  Future<void> ensureInitialized({
    required PaidTier paid,
    required List<Notebook> notebooks,
  }) async {
    if (paid != PaidTier.lite) return;
    if (_prefs.getBool(kCloudSyncNotebookIdsInitKey) == true) return;
    final ranked = [...notebooks]..sort((a, b) {
      final aAt = a.lastOpenedAt ?? a.updatedAt;
      final bAt = b.lastOpenedAt ?? b.updatedAt;
      return bAt.compareTo(aAt);
    });
    _ids = {
      for (final notebook in ranked.take(kLiteCloudNotebookLimit)) notebook.id,
    };
    await _prefs.setBool(kCloudSyncNotebookIdsInitKey, true);
    await _persist();
  }

  bool isSynced(String notebookId, PaidTier paid) =>
      cloudSyncsNotebook(notebookId, paid: paid, selected: _ids);

  /// Returns false when the Lite cap is already full.
  Future<bool> add(String notebookId, PaidTier paid) async {
    if (paid == PaidTier.pro) return true;
    if (paid == PaidTier.free) return false;
    if (_ids.contains(notebookId)) return true;
    if (_ids.length >= kLiteCloudNotebookLimit) return false;
    _ids = {..._ids, notebookId};
    await _prefs.setBool(kCloudSyncNotebookIdsInitKey, true);
    await _persist();
    return true;
  }

  Future<void> remove(String notebookId) async {
    if (!_ids.contains(notebookId)) return;
    _ids = {..._ids}..remove(notebookId);
    await _prefs.setBool(kCloudSyncNotebookIdsInitKey, true);
    await _persist();
  }
}

final cloudSyncSelectionProvider = ChangeNotifierProvider<CloudSyncSelection>((
  ref,
) {
  return CloudSyncSelection(ref.watch(sharedPreferencesProvider));
});
