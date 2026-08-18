import 'package:flutter/gestures.dart';

/// Maps a pointer to ink vs. page navigation.
///
/// On mouse: left button behaves like a stylus, right button like a finger.
abstract final class PointerRouting {
  static bool isMouse(PointerEvent event) =>
      event.kind == PointerDeviceKind.mouse;

  static bool isRightMouse(PointerEvent event) =>
      isMouse(event) && (event.buttons & kSecondaryButton) != 0;

  static bool isActiveStylus(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus ||
      (event.kind == PointerDeviceKind.touch &&
          (event.pressureMax > 1.0 || (event.size > 0 && event.size < 0.08)));

  /// Immediate ink: real stylus, or left mouse (no swipe slop).
  static bool drawsLikeStylus(PointerEvent event) {
    if (isActiveStylus(event)) return true;
    return isMouse(event) && !isRightMouse(event);
  }

  /// Pan / page-flip like a finger. Right mouse counts; left mouse does not.
  static bool browsesLikeFinger(PointerEvent event) {
    if (drawsLikeStylus(event)) return false;
    return event.kind == PointerDeviceKind.touch ||
        isRightMouse(event) ||
        event.kind == PointerDeviceKind.trackpad;
  }
}
