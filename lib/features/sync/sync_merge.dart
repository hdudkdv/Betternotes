/// CRDT-oriented JSON merge helpers used by sync pull/push.
abstract final class SyncMerge {
  /// Merges two JSON payloads with last-write-wins on scalar fields and
  /// union-merge for list-like maps keyed by id (CRDT-ish for blocks).
  static Map<String, dynamic> mergeCrdtMaps(
    Map<String, dynamic> local,
    Map<String, dynamic> remote, {
    required DateTime localUpdated,
    required DateTime remoteUpdated,
  }) {
    final out = Map<String, dynamic>.from(local);
    for (final entry in remote.entries) {
      final key = entry.key;
      final remoteVal = entry.value;
      final localVal = out[key];
      if (localVal is List && remoteVal is List) {
        out[key] = _mergeListsById(localVal, remoteVal);
      } else if (remoteUpdated.isAfter(localUpdated)) {
        out[key] = remoteVal;
      }
    }
    return out;
  }

  static List<dynamic> _mergeListsById(List local, List remote) {
    final map = <String, Map<String, dynamic>>{};
    for (final item in [...local, ...remote]) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = m['id']?.toString();
      if (id == null) continue;
      final existing = map[id];
      if (existing == null) {
        map[id] = m;
      } else {
        final a = DateTime.tryParse('${existing['updatedAt'] ?? ''}');
        final b = DateTime.tryParse('${m['updatedAt'] ?? ''}');
        if (b != null && (a == null || b.isAfter(a))) {
          map[id] = m;
        }
      }
    }
    return map.values.toList();
  }
}
