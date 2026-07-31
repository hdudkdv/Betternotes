import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../entitlements/entitlement_model.dart';

/// Store-billing boundary. Public RevenueCat keys are supplied with
/// --dart-define, so no store credentials are committed to source control.
class RevenueCatBilling extends ChangeNotifier {
  static const _androidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const _iosKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
  static const _webKey = String.fromEnvironment('REVENUECAT_WEB_API_KEY');

  bool configured = false;
  String? error;
  AppTier tier = AppTier.free;
  Offerings? offerings;

  String get _apiKey => switch (defaultTargetPlatform) {
    TargetPlatform.android => _androidKey,
    TargetPlatform.iOS => _iosKey,
    _ => _webKey,
  };

  Future<void> initialize({String? appUserId}) async {
    final key = _apiKey;
    if (key.isEmpty) {
      configured = false;
      error = 'RevenueCat ist noch nicht konfiguriert.';
      notifyListeners();
      return;
    }
    try {
      if (!await Purchases.isConfigured) {
        final configuration = PurchasesConfiguration(key)
          ..appUserID = appUserId;
        await Purchases.configure(configuration);
        Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
      } else if (appUserId != null) {
        await Purchases.logIn(appUserId);
      }
      configured = true;
      error = null;
      await refresh();
    } catch (exception) {
      configured = false;
      error = '$exception';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!configured) return;
    try {
      _applyCustomerInfo(await Purchases.getCustomerInfo());
      offerings = await Purchases.getOfferings();
      error = null;
    } catch (exception) {
      error = '$exception';
    }
    notifyListeners();
  }

  Future<AppTier> restorePurchases() async {
    if (!configured) return tier;
    _applyCustomerInfo(await Purchases.restorePurchases());
    notifyListeners();
    return tier;
  }

  Future<AppTier> purchase(Package package) async {
    if (!configured) return tier;
    final result = await Purchases.purchase(PurchaseParams.package(package));
    _applyCustomerInfo(result.customerInfo);
    notifyListeners();
    return tier;
  }

  void _applyCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active;
    tier = active.containsKey('teacher')
        ? AppTier.teacher
        : active.containsKey('pro_plus')
        ? AppTier.proPlus
        : active.containsKey('pro')
        ? AppTier.pro
        : AppTier.free;
  }
}

final revenueCatBillingProvider = ChangeNotifierProvider<RevenueCatBilling>(
  (ref) => RevenueCatBilling(),
);
