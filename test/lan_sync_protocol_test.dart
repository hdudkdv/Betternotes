import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/lan_sync/lan_sync_protocol.dart';
import 'package:betternotes/features/lan_sync/classroom_auto_connect.dart';
import 'package:betternotes/features/sync/sync_merge.dart';

void main() {
  test('nearby protocol hello round-trips', () {
    final raw = LanSyncMessage.encode(
      LanSyncMessage.hello(
        code: 'ABC123',
        deviceId: 'd1',
        deviceName: 'Tablet',
      ),
    );
    final decoded = LanSyncMessage.decode(raw);
    expect(decoded['type'], 'hello');
    expect(decoded['code'], 'ABC123');
    expect(decoded['protocol'], kLanSyncProtocolVersion);
  });

  test('page merge keeps union of strokes by id', () {
    final local = {
      'id': 'p1',
      'strokes': [
        {'id': 's1', 'updatedAt': '2026-01-01T00:00:00.000'},
      ],
      'title': 'local',
    };
    final remote = {
      'id': 'p1',
      'strokes': [
        {'id': 's2', 'updatedAt': '2026-01-02T00:00:00.000'},
      ],
      'title': 'remote',
    };
    final merged = SyncMerge.mergeCrdtMaps(
      local,
      remote,
      localUpdated: DateTime.parse('2026-01-01T00:00:00.000'),
      remoteUpdated: DateTime.parse('2026-01-02T00:00:00.000'),
    );
    expect(merged['title'], 'remote');
    final strokes = merged['strokes'] as List;
    expect(strokes.length, 2);
  });

  test('classroom auto-connect accepts subject or room match', () {
    expect(
      ClassroomAutoConnect.matches(
        expectedSubject: 'Mathe',
        expectedRoom: 'B12',
        actualSubject: 'mathe',
        actualRoom: 'A01',
      ),
      isTrue,
    );
    expect(
      ClassroomAutoConnect.matches(
        expectedSubject: 'Mathe',
        expectedRoom: ' B12 ',
        actualSubject: 'Deutsch',
        actualRoom: 'b12',
      ),
      isTrue,
    );
    expect(
      ClassroomAutoConnect.matches(
        expectedSubject: 'Mathe',
        expectedRoom: 'B12',
        actualSubject: 'Deutsch',
        actualRoom: 'A01',
      ),
      isFalse,
    );
  });

  test('auto reconnect criteria are included in hello handshake', () {
    final hello = LanSyncMessage.hello(
      code: 'ABC123',
      deviceId: 'd1',
      deviceName: 'Tablet',
      autoReconnect: true,
      expectedSubject: 'Mathe',
      expectedRoom: 'B12',
    );
    expect(hello['autoReconnect'], isTrue);
    expect(hello['expectedSubject'], 'Mathe');
    expect(hello['expectedRoom'], 'B12');
  });
}
