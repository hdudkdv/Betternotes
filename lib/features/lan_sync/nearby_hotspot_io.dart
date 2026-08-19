import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyHotspotSession {
  const NearbyHotspotSession({
    required this.ssid,
    required this.password,
  });

  final String ssid;
  final String password;
}

/// Starts a local-only Wi‑Fi AP (Android) or joins one (Android + iOS).
class NearbyHotspot {
  NearbyHotspot._();
  static final NearbyHotspot instance = NearbyHotspot._();

  static const _channel = MethodChannel('notis/nearby_hotspot');

  bool get canStartAp => !kIsWeb && Platform.isAndroid;

  Future<bool> ensurePermissions() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final location = await Permission.locationWhenInUse.request();
      if (!location.isGranted) return false;
      try {
        await Permission.nearbyWifiDevices.request();
      } catch (_) {}
    }
    return true;
  }

  Future<NearbyHotspotSession?> startHostAp() async {
    if (!canStartAp) return null;
    if (!await ensurePermissions()) return null;
    try {
      final raw = await _channel.invokeMethod<dynamic>('startHost');
      if (raw is! Map) return null;
      final ssid = raw['ssid']?.toString() ?? '';
      final password = raw['password']?.toString() ?? '';
      if (ssid.isEmpty || password.isEmpty) return null;
      return NearbyHotspotSession(ssid: ssid, password: password);
    } on PlatformException {
      return null;
    }
  }

  Future<bool> connectToAp({
    required String ssid,
    required String password,
  }) async {
    if (kIsWeb) return false;
    // iOS guests join Personal Hotspot in Settings; no Hotspot Configuration
    // entitlement on the App Store profile.
    if (Platform.isIOS) return false;
    if (Platform.isAndroid && !await ensurePermissions()) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('connect', {
        'ssid': ssid,
        'password': password,
      });
      return ok == true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stop() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // Native plugin may be missing on desktop.
    }
  }
}
