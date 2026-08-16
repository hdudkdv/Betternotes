import 'package:flutter/material.dart';
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

/// Full-screen RevenueCat [PaywallView] when the native modal is missing
/// a dashboard paywall or cannot be presented.
Future<PaywallResult> presentEmbeddedRevenueCatPaywall(
  BuildContext context, {
  required Offering offering,
  void Function(CustomerInfo info)? onCustomerInfo,
}) {
  return Navigator.of(context)
      .push<PaywallResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) {
            var popped = false;
            void finish(PaywallResult result) {
              if (popped || !ctx.mounted) return;
              popped = true;
              Navigator.pop(ctx, result);
            }

            return Scaffold(
              body: PaywallView(
                offering: offering,
                displayCloseButton: true,
                onDismiss: () => finish(PaywallResult.cancelled),
                onPurchaseCompleted: (info, _) {
                  onCustomerInfo?.call(info);
                  finish(PaywallResult.purchased);
                },
                onRestoreCompleted: (info) {
                  onCustomerInfo?.call(info);
                  finish(PaywallResult.restored);
                },
                onPurchaseCancelled: () {},
                onPurchaseError: (_) {},
              ),
            );
          },
        ),
      )
      .then((result) => result ?? PaywallResult.cancelled);
}
