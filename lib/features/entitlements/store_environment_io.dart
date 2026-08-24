import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('notis/store_env');

/// True in App Review / TestFlight / StoreKit sandbox (receipt is
/// `sandboxReceipt`). Live AdMob units usually do not fill there.
Future<bool> isAppStoreSandbox() async {
  if (defaultTargetPlatform != TargetPlatform.iOS) return false;
  try {
    return await _channel.invokeMethod<bool>('isSandbox') ?? false;
  } catch (_) {
    return false;
  }
}
