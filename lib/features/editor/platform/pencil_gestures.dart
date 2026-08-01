import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hardware Apple Pencil events from iOS (`UIPencilInteraction`).
enum PencilHardwareEvent { doubleTap, squeeze }

/// Thin MethodChannel bridge. No-ops on non-iOS platforms.
class PencilGestures {
  PencilGestures._();

  static const _channel = MethodChannel('betternotes/pencil');
  static final _controller = StreamController<PencilHardwareEvent>.broadcast();
  static bool _listening = false;

  static Stream<PencilHardwareEvent> get events {
    _ensureListening();
    return _controller.stream;
  }

  static void _ensureListening() {
    if (_listening) return;
    _listening = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'doubleTap':
          _controller.add(PencilHardwareEvent.doubleTap);
        case 'squeeze':
          _controller.add(PencilHardwareEvent.squeeze);
      }
    });
  }
}
