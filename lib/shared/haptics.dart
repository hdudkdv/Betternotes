import 'package:flutter/services.dart';

/// Light tactile feedback for taps that should feel physical.
abstract final class AppHaptics {
  static Future<void> tap() => HapticFeedback.selectionClick();

  static Future<void> confirm() => HapticFeedback.lightImpact();

  static Future<void> warn() => HapticFeedback.mediumImpact();
}
