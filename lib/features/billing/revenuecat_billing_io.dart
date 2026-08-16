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
  bool get usesTestStore => _apiKey.startsWith('test_');
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
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => RevenueCatConfig.androidKey,
      TargetPlatform.iOS => RevenueCatConfig.iosKey,
      _ => RevenueCatConfig.webKey,
    };
  }

  Future<void> initialize({String? appUserId}) async {
    final key = _apiKey;
    if (key.isEmpty || key.startsWith('test_')) {
      configured = false;
      error = null;
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
      final current = offerings?.current;
      final packages = current?.availablePackages ?? const <Package>[];
      if (current == null) {
        error = usesTestStore
            ? 'Test-Store hat kein Current Offering. In RevenueCat unter Test Store ein Offering als Current markieren und eine Paywall anhängen — oder den Apple-Key (appl_) nutzen.'
            : 'Kein Current Offering. In RevenueCat ein Offering als Current markieren und eine Paywall anhängen.';
      } else if (packages.isEmpty) {
        error =
            'Die Abo-Produkte kommen vom App Store. Sideload- und unsigned Builds können keine StoreKit-Produkte laden — TestFlight oder App-Store-Build nutzen.';
      } else {
        error = null;
      }
    } catch (exception) {
      error = _friendlyError('$exception');
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
      final result = await Purchases.purchase(PurchaseParams.package(package));
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
      final result = await presentRevenueCatPaywall(offering: currentOffering);
      return _outcomeFromPaywall(result);
    } catch (exception) {
      error = _friendlyError('$exception');
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
    final active = info.entitlements.active.keys.toSet();
    tier = active.intersection(RevenueCatConfig.teacherEntitlements).isNotEmpty
        ? AppTier.teacher
        : active
              .intersection(RevenueCatConfig.teacherLiteEntitlements)
              .isNotEmpty
        ? AppTier.proPlus
        : active
              .intersection(RevenueCatConfig.studentProEntitlements)
              .isNotEmpty
        ? AppTier.proPlus
        : active
              .intersection(RevenueCatConfig.studentLiteEntitlements)
              .isNotEmpty
        ? AppTier.pro
        : AppTier.free;
    notifyListeners();
  }

  bool _hasNotisPro(CustomerInfo? info) {
    final active = info?.entitlements.active;
    if (active == null) return false;
    return active.keys.any(
      (id) =>
          RevenueCatConfig.teacherEntitlements.contains(id) ||
          RevenueCatConfig.teacherLiteEntitlements.contains(id) ||
          RevenueCatConfig.studentProEntitlements.contains(id) ||
          RevenueCatConfig.studentLiteEntitlements.contains(id),
    );
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('test store') || lower.contains('test_')) {
      return 'RevenueCat Test-Store passt nicht zu den App-Store-Abos. Apple-Key (appl_) in RevenueCat kopieren und per --dart-define=REVENUECAT_IOS_API_KEY setzen.';
    }
    if (lower.contains('offering') ||
        lower.contains('product') ||
        lower.contains('storekit') ||
        lower.contains('store problem')) {
      return 'Die Abo-Produkte kommen vom App Store. Sideload-Builds sehen keine Pläne — TestFlight oder App-Store-Build nutzen. In RevenueCat müssen die Produkte am Current Offering und an den Entitlements hängen.';
    }
    return raw;
  }
}

final revenueCatBillingProvider = ChangeNotifierProvider<RevenueCatBilling>(
  (ref) => RevenueCatBilling(),
);
