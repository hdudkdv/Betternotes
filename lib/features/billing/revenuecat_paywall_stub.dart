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
  void Function(Object info)? onRestoreCompleted,
}) async {}
