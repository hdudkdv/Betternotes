import 'package:betternotes/features/sync/crdt_delta.dart';
import 'package:betternotes/features/sync/transport_manager.dart';
import 'package:betternotes/features/sync/vector_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes P2P before cloud before queue', () {
    final tm = TransportManager();
    expect(tm.preferredRoute, TransportRoute.queued);

    tm.setCloud(premium: true, reachable: true);
    expect(tm.preferredRoute, TransportRoute.cloud);

    tm.setP2pActive(true);
    expect(tm.preferredRoute, TransportRoute.p2p);
  });

  test('vector clocks merge and order events', () {
    var a = VectorClock.empty().increment('phone');
    var b = VectorClock.empty().increment('tablet');
    expect(a.happensBefore(b), isFalse);
    expect(b.happensBefore(a), isFalse);
    final merged = a.merge(b).increment('phone');
    expect(a.happensBefore(merged), isTrue);

    final delta = CrdtDelta(
      id: 'd1',
      notebookId: 'nb',
      type: CrdtOpType.addStroke,
      payload: const {'strokeId': 's1'},
      clock: merged,
      deviceId: 'phone',
      createdAt: DateTime.utc(2026, 8, 15),
    );
    expect(CrdtDelta.fromJson(delta.toJson()).id, 'd1');
  });
}
