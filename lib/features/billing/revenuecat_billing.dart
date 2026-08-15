import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../entitlements/entitlement_model.dart';
import 'revenuecat_config.dart';
import 'revenuecat_paywall.dart';

enum PurchaseOutcome { success, cancelled, error, unavailable }

/// Store-billing boundary. Test Store key is the default; production keys
/// come from `--dart-define` so they are not required for local testing.
class RevenueCatBilling extends ChangeNotifier {
  bool configured = false;
  String? error;
  AppTier tier = AppTier.free;
  Offerings? offerings;
  CustomerInfo? customerInfo;

  bool get hasNotisPro => _hasNotisPro(customerInfo);
  bool get paywallSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Offering? get currentOffering => offerings?.current;

  Package? get lifetimePackage => _package(
    RevenueCatConfig.packageLifetime,
    fallback: currentOffering?.lifetime,
    rcIdentifier: r'$rc_lifetime',
  );

  Package? get yearlyPackage => _package(
    RevenueCatConfig.packageYearly,
    fallback: currentOffering?.annual,
    rcIdentifier: r'$rc_annual',
  );

  Package? get monthlyPackage => _package(
    RevenueCatConfig.packageMonthly,
    fallback: currentOffering?.monthly,
    rcIdentifier: r'$rc_monthly',
  );

  String get _apiKey {
    final platformKey = switch (defaultTargetPlatform) {
      TargetPlatform.android => RevenueCatConfig.androidKey,
      TargetPlatform.iOS => RevenueCatConfig.iosKey,
      _ => RevenueCatConfig.webKey,
    };
    if (platformKey.isNotEmpty) return platformKey;
    return RevenueCatConfig.testApiKey;
  }

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
        await Purchases.setLogLevel(
          kDebugMode ? LogLevel.debug : LogLevel.info,
        );
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

  Future<void> syncAppUser(String? appUserId) async {
    if (!configured) {
      await initialize(appUserId: appUserId);
      return;
    }
    try {
      if (appUserId != null && appUserId.isNotEmpty) {
        await Purchases.logIn(appUserId);
      } else {
        await Purchases.logOut();
      }
      error = null;
      await refresh();
    } on PlatformException catch (exception) {
      final code = PurchasesErrorHelper.getErrorCode(exception);
      if (code == PurchasesErrorCode.unknownError &&
          exception.message?.contains('logOut') == true) {
        error = null;
        await refresh();
        return;
      }
      error = exception.message ?? '$exception';
      notifyListeners();
    } catch (exception) {
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

  Future<PurchaseOutcome> restorePurchases() async {
    if (!configured) return PurchaseOutcome.unavailable;
    try {
      _applyCustomerInfo(await Purchases.restorePurchases());
      error = null;
      notifyListeners();
      return PurchaseOutcome.success;
    } on PlatformException catch (exception) {
      return _handlePurchaseError(exception);
    } catch (exception) {
      error = '$exception';
      notifyListeners();
      return PurchaseOutcome.error;
    }
  }

  Future<PurchaseOutcome> purchase(Package package) async {
    if (!configured) return PurchaseOutcome.unavailable;
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _applyCustomerInfo(result.customerInfo);
      error = null;
      notifyListeners();
      return PurchaseOutcome.success;
    } on PlatformException catch (exception) {
      return _handlePurchaseError(exception);
    } catch (exception) {
      error = '$exception';
      notifyListeners();
      return PurchaseOutcome.error;
    }
  }

  Future<PurchaseOutcome> purchaseNamed(String packageId) async {
    final package = switch (packageId) {
      RevenueCatConfig.packageLifetime => lifetimePackage,
      RevenueCatConfig.packageYearly => yearlyPackage,
      RevenueCatConfig.packageMonthly => monthlyPackage,
      _ => currentOffering?.getPackage(packageId),
    };
    if (package == null) {
      error = 'Produkt "$packageId" ist in der aktuellen Offering nicht da.';
      notifyListeners();
      return PurchaseOutcome.unavailable;
    }
    return purchase(package);
  }

  Future<PurchaseOutcome> presentPaywall() async {
    if (!configured) return PurchaseOutcome.unavailable;
    if (!paywallSupported) {
      error = 'Paywall ist auf dieser Plattform nicht verfügbar.';
      notifyListeners();
      return PurchaseOutcome.unavailable;
    }
    try {
      final result = await presentRevenueCatPaywall(
        offering: currentOffering,
      );
      return _outcomeFromPaywall(result);
    } catch (exception) {
      error = '$exception';
      notifyListeners();
      return PurchaseOutcome.error;
    }
  }

  Future<PurchaseOutcome> presentPaywallIfNeeded() async {
    if (!configured) return PurchaseOutcome.unavailable;
    if (hasNotisPro) return PurchaseOutcome.success;
    if (!paywallSupported) {
      error = 'Paywall ist auf dieser Plattform nicht verfügbar.';
      notifyListeners();
      return PurchaseOutcome.unavailable;
    }
    try {
      final result = await presentRevenueCatPaywallIfNeeded(
        entitlementId: RevenueCatConfig.notisPro,
        offering: currentOffering,
      );
      return _outcomeFromPaywall(result);
    } catch (exception) {
      error = '$exception';
      notifyListeners();
      return PurchaseOutcome.error;
    }
  }

  Future<void> presentCustomerCenter() async {
    if (!configured || !paywallSupported) return;
    await presentRevenueCatCustomerCenter(
      onRestoreCompleted: _applyCustomerInfo,
    );
    await refresh();
  }

  PurchaseOutcome _outcomeFromPaywall(PaywallResult result) {
    switch (result) {
      case PaywallResult.purchased:
      case PaywallResult.restored:
        error = null;
        unawaited(refresh());
        return PurchaseOutcome.success;
      case PaywallResult.cancelled:
      case PaywallResult.notPresented:
        return PurchaseOutcome.cancelled;
      case PaywallResult.error:
        error = 'Paywall-Fehler.';
        notifyListeners();
        return PurchaseOutcome.error;
    }
  }

  PurchaseOutcome _handlePurchaseError(PlatformException exception) {
    final code = PurchasesErrorHelper.getErrorCode(exception);
    if (code == PurchasesErrorCode.purchaseCancelledError) {
      error = null;
      notifyListeners();
      return PurchaseOutcome.cancelled;
    }
    error = exception.message ?? '$exception';
    notifyListeners();
    return PurchaseOutcome.error;
  }

  Package? _package(
    String identifier, {
    Package? fallback,
    required String rcIdentifier,
  }) {
    final offering = currentOffering;
    if (offering == null) return fallback;
    return offering.getPackage(identifier) ??
        fallback ??
        offering.getPackage(rcIdentifier);
  }

  void _applyCustomerInfo(CustomerInfo info) {
    customerInfo = info;
    final active = info.entitlements.active;
    tier = active.containsKey(RevenueCatConfig.teacher)
        ? AppTier.teacher
        : active.containsKey(RevenueCatConfig.proPlus)
        ? AppTier.proPlus
        : _hasNotisPro(info)
        ? AppTier.pro
        : AppTier.free;
    notifyListeners();
  }

  bool _hasNotisPro(CustomerInfo? info) {
    final active = info?.entitlements.active;
    if (active == null) return false;
    return active.containsKey(RevenueCatConfig.notisPro) ||
        active.containsKey(RevenueCatConfig.pro) ||
        active.containsKey(RevenueCatConfig.proPlus) ||
        active.containsKey(RevenueCatConfig.teacher);
  }
}

final revenueCatBillingProvider = ChangeNotifierProvider<RevenueCatBilling>(
  (ref) => RevenueCatBilling(),
);
