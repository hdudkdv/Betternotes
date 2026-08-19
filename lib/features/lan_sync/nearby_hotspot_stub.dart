class NearbyHotspotSession {
  const NearbyHotspotSession({
    required this.ssid,
    required this.password,
  });

  final String ssid;
  final String password;
}

/// Web / unsupported platforms: no local AP.
class NearbyHotspot {
  NearbyHotspot._();
  static final NearbyHotspot instance = NearbyHotspot._();

  bool get canStartAp => false;

  Future<bool> ensurePermissions() async => true;

  Future<NearbyHotspotSession?> startHostAp() async => null;

  Future<bool> connectToAp({
    required String ssid,
    required String password,
  }) async =>
      false;

  Future<void> stop() async {}
}
