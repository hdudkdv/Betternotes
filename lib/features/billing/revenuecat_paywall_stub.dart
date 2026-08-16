import 'package:flutter/widgets.dart';

enum PaywallResult { notPresented, cancelled, error, purchased, restored }

Future<PaywallResult> presentRevenueCatPaywall({Object? offering}) async {
  return PaywallResult.notPresented;
}

Future<PaywallResult> presentRevenueCatPaywallIfNeeded({
  required String entitlementId,
  Object? offering,
}) async {
  return PaywallResult.notPresented;
}

Future<void> presentRevenueCatCustomerCenter({
  void Function(dynamic info)? onRestoreCompleted,
}) async {}

Future<PaywallResult> presentEmbeddedRevenueCatPaywall(
  BuildContext context, {
  required Object offering,
  void Function(dynamic info)? onCustomerInfo,
}) async {
  return PaywallResult.notPresented;
}
