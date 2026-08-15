import 'package:purchases_flutter/purchases_flutter.dart';

enum PaywallResult { notPresented, cancelled, error, purchased, restored }

Future<PaywallResult> presentRevenueCatPaywall({Offering? offering}) async {
  return PaywallResult.notPresented;
}

Future<PaywallResult> presentRevenueCatPaywallIfNeeded({
  required String entitlementId,
  Offering? offering,
}) async {
  return PaywallResult.notPresented;
}

Future<void> presentRevenueCatCustomerCenter({
  void Function(CustomerInfo info)? onRestoreCompleted,
}) async {}
