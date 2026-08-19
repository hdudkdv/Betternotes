import Flutter
import UIKit

/// Nearby Wi‑Fi AP control.
///
/// iOS cannot start a Personal Hotspot from an app, and joining a hotspot
/// needs the Hotspot Configuration entitlement (not on the App Store profile).
/// Guests join in Settings; the Dart UI already explains that.
final class NearbyHotspotPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NearbyHotspotPlugin()
    instance.channel = FlutterMethodChannel(
      name: "notis/nearby_hotspot",
      binaryMessenger: registrar.messenger()
    )
    instance.channel?.setMethodCallHandler(instance.handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startHost", "connect":
      result(
        FlutterError(
          code: "unsupported",
          message:
            "On iPhone, turn on Personal Hotspot in Settings, then scan the QR code.",
          details: nil
        )
      )
    case "stop":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
