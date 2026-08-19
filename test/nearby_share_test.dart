import 'package:betternotes/features/lan_sync/nearby_share.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final share = NearbyHostedShare(
    shareId: 's1',
    notebookId: 'n1',
    displayName: 'Wirtschaft 13',
    accessCode: 'ABC234',
    granted: [
      NearbySharePeer(
        deviceId: 'tablet-a',
        name: 'Lea',
        grantedAt: DateTime.parse('2026-01-01T00:00:00.000'),
      ),
    ],
    revoked: const ['tablet-b'],
  );

  test('granted device joins without the code', () {
    expect(
      decideNearbyHello(
        deviceId: 'tablet-a',
        code: '',
        share: share,
      ),
      NearbyHelloDecision.allowGranted,
    );
  });

  test('new device joins with the durable code', () {
    expect(
      decideNearbyHello(
        deviceId: 'tablet-c',
        code: 'abc234',
        share: share,
      ),
      NearbyHelloDecision.allowCode,
    );
  });

  test('revoked device is rejected even with the code', () {
    expect(
      decideNearbyHello(
        deviceId: 'tablet-b',
        code: 'ABC234',
        share: share,
      ),
      NearbyHelloDecision.rejectRevoked,
    );
  });

  test('strangers without the code cannot join', () {
    expect(
      decideNearbyHello(
        deviceId: 'stranger',
        code: '',
        share: share,
      ),
      NearbyHelloDecision.rejectInvalid,
    );
  });
}
