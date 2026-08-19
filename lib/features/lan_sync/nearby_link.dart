/// Join payload for nearby sync without a shared router.
///
/// Encoded as a compact URI so it fits a QR code:
/// `notisnearby:1?s=SSID&p=PASS&h=IP&o=47821&c=CODE`
class NearbyLink {
  const NearbyLink({
    required this.host,
    required this.port,
    required this.code,
    this.shareId,
    this.ssid,
    this.password,
  });

  final String host;
  final int port;
  final String code;
  final String? shareId;
  final String? ssid;
  final String? password;

  bool get hasWifi =>
      ssid != null && ssid!.trim().isNotEmpty && password != null && password!.isNotEmpty;

  Uri toUri() {
    return Uri(
      scheme: 'notisnearby',
      path: '1',
      queryParameters: {
        'h': host,
        'o': '$port',
        'c': code,
        if (shareId != null && shareId!.isNotEmpty) 'sid': shareId!,
        if (ssid != null && ssid!.isNotEmpty) 's': ssid!,
        if (password != null && password!.isNotEmpty) 'p': password!,
      },
    );
  }

  @override
  String toString() => toUri().toString();

  static NearbyLink? tryParse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (uri.scheme != 'notisnearby' && uri.scheme != 'notis') return null;
    final host = uri.queryParameters['h']?.trim() ?? '';
    final code = (uri.queryParameters['c'] ?? '').trim().toUpperCase();
    if (host.isEmpty || code.isEmpty) return null;
    final port = int.tryParse(uri.queryParameters['o'] ?? '') ?? 47821;
    return NearbyLink(
      host: host,
      port: port,
      code: code,
      shareId: uri.queryParameters['sid'],
      ssid: uri.queryParameters['s'],
      password: uri.queryParameters['p'],
    );
  }
}
