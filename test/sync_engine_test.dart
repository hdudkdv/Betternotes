import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/sync/sync_engine.dart';

void main() {
  test('CRDT merge unions list items by id and prefers newer scalars', () {
    final local = {
      'title': 'Local',
      'updatedAt': '2026-01-01T00:00:00.000',
      'blocks': [
        {'id': 'a', 'text': 'old', 'updatedAt': '2026-01-01T00:00:00.000'},
      ],
    };
    final remote = {
      'title': 'Remote',
      'updatedAt': '2026-02-01T00:00:00.000',
      'blocks': [
        {'id': 'a', 'text': 'new', 'updatedAt': '2026-02-01T00:00:00.000'},
        {'id': 'b', 'text': 'extra', 'updatedAt': '2026-02-01T00:00:00.000'},
      ],
    };

    final merged = SyncEngine.mergeCrdtMaps(
      local,
      remote,
      localUpdated: DateTime.parse('2026-01-01T00:00:00.000'),
      remoteUpdated: DateTime.parse('2026-02-01T00:00:00.000'),
    );

    expect(merged['title'], 'Remote');
    final blocks = merged['blocks'] as List;
    expect(blocks, hasLength(2));
    final a = blocks.cast<Map>().firstWhere((b) => b['id'] == 'a');
    expect(a['text'], 'new');
  });
}
