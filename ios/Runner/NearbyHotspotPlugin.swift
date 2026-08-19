import Flutter
import NetworkExtension
import UIKit

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
    case "startHost":
      result(
        FlutterError(
          code: "unsupported",
          message: "iOS cannot start a hotspot from the app. Turn on Personal Hotspot in Settings.",
          details: nil
        )
      )
    case "connect":
      guard
        let args = call.arguments as? [String: Any],
        let ssid = args["ssid"] as? String,
        let password = args["password"] as? String,
        !ssid.isEmpty,
        !password.isEmpty
      else {
        result(
          FlutterError(code: "args", message: "ssid and password required", details: nil)
        )
        return
      }
      joinWifi(ssid: ssid, password: password, result: result)
    case "stop":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func joinWifi(ssid: String, password: String, result: @escaping FlutterResult) {
    let config = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
    config.joinOnce = true
    NEHotspotConfigurationManager.shared.apply(config) { error in
      if let error = error as NSError? {
        // Already associated is success for our purposes.
        if error.domain == NEHotspotConfigurationErrorDomain,
           error.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
          result(true)
          return
        }
        result(
          FlutterError(code: "failed", message: error.localizedDescription, details: nil)
        )
        return
      }
      result(true)
    }
  }
}
