import Flutter
import UIKit

/// Forwards Apple Pencil double-tap / squeeze to Flutter.
final class PencilGesturePlugin: NSObject, FlutterPlugin, UIPencilInteractionDelegate {
  private var channel: FlutterMethodChannel?
  private weak var hostView: UIView?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PencilGesturePlugin()
    instance.channel = FlutterMethodChannel(
      name: "betternotes/pencil",
      binaryMessenger: registrar.messenger()
    )
    registrar.publish(instance)
    DispatchQueue.main.async {
      instance.attachToKeyWindow()
    }
  }

  private func attachToKeyWindow() {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
      ?? UIApplication.shared.windows.first
    guard let view = window?.rootViewController?.view else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.attachToKeyWindow()
      }
      return
    }
    if hostView === view { return }
    hostView = view
    let interaction = UIPencilInteraction()
    interaction.delegate = self
    view.addInteraction(interaction)
  }

  func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
    channel?.invokeMethod("doubleTap", arguments: nil)
  }

  @available(iOS 17.5, *)
  func pencilInteraction(
    _ interaction: UIPencilInteraction,
    didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze
  ) {
    if squeeze.phase == .ended {
      channel?.invokeMethod("squeeze", arguments: nil)
    }
  }
}
