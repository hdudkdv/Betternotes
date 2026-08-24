import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var storeEnvChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PencilGesturePlugin") {
      PencilGesturePlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NearbyHotspotPlugin") {
      NearbyHotspotPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NearbyBlePlugin") {
      NearbyBlePlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StoreEnv") {
      let channel = FlutterMethodChannel(
        name: "notis/store_env",
        binaryMessenger: registrar.messenger()
      )
      storeEnvChannel = channel
      channel.setMethodCallHandler { call, result in
        if call.method == "isSandbox" {
          let sandbox =
            Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
          result(sandbox)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
