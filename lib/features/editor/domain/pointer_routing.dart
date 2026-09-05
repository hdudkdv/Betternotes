import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Maps a pointer to ink vs. page navigation.
///
/// On mouse: left button behaves like a stylus, right button like a finger.
/// Flutter web often reports a desktop mouse as [PointerDeviceKind.touch]
/// with zero contact size; those still write immediately (no page-swipe slop).
abstract final class PointerRouting {
  static bool isMouse(PointerEvent event) =>
      event.kind == PointerDeviceKind.mouse;

  static bool isRightMouse(PointerEvent event) =>
      (event.buttons & kSecondaryButton) != 0;

  /// Desktop mouse that Flutter Web labelled as a finger.
  static bool looksLikeWebMouse(PointerEvent event) =>
      event.kind == PointerDeviceKind.touch &&
      event.size == 0 &&
      event.pressureMax <= 1.0;

  static bool isActiveStylus(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus ||
      (event.kind == PointerDeviceKind.touch &&
          (event.pressureMax > 1.0 || (event.size > 0 && event.size < 0.08)));

  /// Pencil in the air: hover, a missed up, or contact pressure gone.
  /// Mouse / finger never match — they have no hover-while-drawing path.
  static bool stylusIsInAir(PointerEvent event) {
    if (!isActiveStylus(event)) return false;
    if (!event.down) return true;
    return event.pressureMax > 1.0 && event.pressure < 0.02;
  }

  /// Immediate ink: real stylus, or left mouse (no swipe slop).
  static bool drawsLikeStylus(PointerEvent event) {
    if (isRightMouse(event)) return false;
    if (isActiveStylus(event)) return true;
    if (isMouse(event)) return true;
    if (kIsWeb && looksLikeWebMouse(event)) return true;
    return false;
  }

  /// Pan / page-flip like a finger. Right mouse counts; left mouse does not.
  static bool browsesLikeFinger(PointerEvent event) {
    if (drawsLikeStylus(event)) return false;
    return event.kind == PointerDeviceKind.touch ||
        isRightMouse(event) ||
        event.kind == PointerDeviceKind.trackpad;
  }
}
