import 'package:betternotes/features/lan_sync/nearby_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NearbyLink round-trips Wi-Fi credentials', () {
    const link = NearbyLink(
      host: '192.168.49.1',
      port: 47821,
      code: 'ABC234',
      ssid: 'Notis-Park',
      password: 'secret12',
    );
    final parsed = NearbyLink.tryParse(link.toString());
    expect(parsed, isNotNull);
    expect(parsed!.host, '192.168.49.1');
    expect(parsed.port, 47821);
    expect(parsed.code, 'ABC234');
    expect(parsed.ssid, 'Notis-Park');
    expect(parsed.password, 'secret12');
    expect(parsed.hasWifi, isTrue);
  });

  test('NearbyLink parses IP-only join codes', () {
    final parsed = NearbyLink.tryParse(
      'notisnearby:1?h=172.20.10.1&o=47821&c=hello1',
    );
    expect(parsed?.host, '172.20.10.1');
    expect(parsed?.code, 'HELLO1');
    expect(parsed?.hasWifi, isFalse);
  });

  test('NearbyLink rejects junk', () {
    expect(NearbyLink.tryParse('https://example.com'), isNull);
    expect(NearbyLink.tryParse(''), isNull);
  });
}
