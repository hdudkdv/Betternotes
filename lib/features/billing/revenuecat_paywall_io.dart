import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

export 'package:purchases_ui_flutter/purchases_ui_flutter.dart'
    show PaywallResult;

Future<PaywallResult> presentRevenueCatPaywall({Offering? offering}) {
  return RevenueCatUI.presentPaywall(
    offering: offering,
    displayCloseButton: true,
  );
}

Future<PaywallResult> presentRevenueCatPaywallIfNeeded({
  required String entitlementId,
  Offering? offering,
}) {
  return RevenueCatUI.presentPaywallIfNeeded(
    entitlementId,
    offering: offering,
    displayCloseButton: true,
  );
}

Future<void> presentRevenueCatCustomerCenter({
  void Function(CustomerInfo info)? onRestoreCompleted,
}) {
  return RevenueCatUI.presentCustomerCenter(
    onRestoreCompleted: onRestoreCompleted,
  );
}
