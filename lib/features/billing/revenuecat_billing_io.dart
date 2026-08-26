import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../entitlements/entitlement_model.dart';
import 'revenuecat_config.dart';
import 'revenuecat_paywall.dart';

export 'package:purchases_flutter/purchases_flutter.dart'
    show CustomerInfo, Offering, Offerings, Package, PackageType, StoreProduct;

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

  bool get hasStoreProducts {
    for (final offering in offerings?.all.values ?? const <Offering>[]) {
      if (offering.availablePackages.isNotEmpty) return true;
    }
    return (currentOffering?.availablePackages.isNotEmpty) ?? false;
  }

  Offering? _anyOfferingWithPackages() {
    final current = currentOffering;
    if (current != null && current.availablePackages.isNotEmpty) return current;
    for (final offering in offerings?.all.values ?? const <Offering>[]) {
      if (offering.availablePackages.isNotEmpty) return offering;
    }
    return null;
  }

  Offering? offeringForAudience(PaywallAudience audience) {
    final all = offerings?.all ?? const <String, Offering>{};
    final aliases = audience == PaywallAudience.teacher
        ? RevenueCatConfig.offeringTeacherAliases
        : RevenueCatConfig.offeringStudentAliases;
    for (final alias in aliases) {
      final exact = all[alias];
      if (exact != null) return exact;
      for (final entry in all.entries) {
        if (entry.key.toLowerCase() == alias.toLowerCase()) return entry.value;
      }
    }
    final current = currentOffering;
    if (current != null && _offeringMatchesAudience(current, audience)) {
      return current;
    }
    return null;
  }

  List<Package> packagesForAudience(PaywallAudience audience) {
    final seen = <String>{};
    final collected = <Package>[];
    void addAll(Iterable<Package> packages) {
      for (final package in packages) {
        if (!_packageBelongsTo(package, audience)) continue;
        final key = package.storeProduct.identifier;
        if (!seen.add(key)) continue;
        collected.add(package);
      }
    }

    final dedicated = offeringForAudience(audience);
    if (dedicated != null) addAll(dedicated.availablePackages);

    final all = offerings?.all ?? const <String, Offering>{};
    for (final entry in all.entries) {
      if (!_offeringKeyMatchesAudience(entry.key, audience)) continue;
      addAll(entry.value.availablePackages);
    }
    if (collected.isEmpty && currentOffering != null) {
      addAll(currentOffering!.availablePackages);
    }
    if (collected.isEmpty) {
      for (final offering in (offerings?.all.values ?? const <Offering>[])) {
        for (final package in offering.availablePackages) {
          final key = package.storeProduct.identifier;
          if (seen.add(key)) collected.add(package);
        }
      }
    }
    return collected;
  }

  bool _offeringKeyMatchesAudience(String key, PaywallAudience audience) {
    final id = key.toLowerCase();
    if (audience == PaywallAudience.teacher) {
      return id.contains('lehrer') || id.contains('teacher');
    }
    return id.contains('schueler') || id.contains('student');
  }

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
      if (!hasStoreProducts) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        offerings = await Purchases.getOfferings();
      }
      // Never put dashboard / sideload copy in the UI — App Review treats
      // that as a broken In-App Purchase screen (Guideline 2.1(b)).
      error = null;
    } catch (exception) {
      debugPrint('RevenueCat refresh failed: $exception');
      error = null;
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
      return PurchaseOutcome.unavailable;
    }
    return purchase(package);
  }

  Future<PurchaseOutcome> presentPaywall({PaywallAudience? audience}) async {
    if (!configured) return PurchaseOutcome.unavailable;
    if (!paywallSupported) {
      return PurchaseOutcome.unavailable;
    }
    final offering = audience == null
        ? _anyOfferingWithPackages()
        : offeringForAudience(audience) ?? _anyOfferingWithPackages();
    if (offering == null || offering.availablePackages.isEmpty) {
      return PurchaseOutcome.unavailable;
    }
    try {
      final result = await presentRevenueCatPaywall(offering: offering);
      return _outcomeFromPaywall(result);
    } catch (exception) {
      debugPrint('RevenueCat paywall failed: $exception');
      return PurchaseOutcome.error;
    }
  }

  Future<PurchaseOutcome> presentPaywallIfNeeded({
    PaywallAudience? audience,
  }) async {
    if (!configured) return PurchaseOutcome.unavailable;
    if (hasNotisPro) return PurchaseOutcome.success;
    if (!paywallSupported) {
      return PurchaseOutcome.unavailable;
    }
    final offering = audience == null
        ? currentOffering
        : offeringForAudience(audience);
    try {
      final result = await presentRevenueCatPaywallIfNeeded(
        entitlementId: audience == PaywallAudience.teacher
            ? RevenueCatConfig.lehrerPro
            : RevenueCatConfig.schuelerPro,
        offering: offering,
      );
      return _outcomeFromPaywall(result);
    } catch (exception) {
      debugPrint('RevenueCat paywallIfNeeded failed: $exception');
      return PurchaseOutcome.error;
    }
  }

  Future<void> presentCustomerCenter() async {
    if (!configured || !paywallSupported) return;
    await presentRevenueCatCustomerCenter(
      onRestoreCompleted: (info) {
        if (info is CustomerInfo) _applyCustomerInfo(info);
      },
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
    if (_looksLikeInternalCopy(error!)) {
      error = null;
    }
    notifyListeners();
    return PurchaseOutcome.error;
  }

  bool _looksLikeInternalCopy(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('offering') ||
        lower.contains('sideload') ||
        lower.contains('revenuecat') ||
        lower.contains('test store') ||
        lower.contains('test-store') ||
        lower.contains('appl_');
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

  void applyCustomerInfo(CustomerInfo info) => _applyCustomerInfo(info);

  void _applyCustomerInfo(CustomerInfo info) {
    customerInfo = info;
    final active = info.entitlements.active.keys.toSet();
    tier = active.intersection(RevenueCatConfig.teacherEntitlements).isNotEmpty
        ? AppTier.pro
        : active
              .intersection(RevenueCatConfig.studentProEntitlements)
              .isNotEmpty
        ? AppTier.pro
        : active.intersection({
            ...RevenueCatConfig.teacherLiteEntitlements,
            ...RevenueCatConfig.studentLiteEntitlements,
          }).isNotEmpty
        ? AppTier.lite
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

  bool _offeringMatchesAudience(Offering offering, PaywallAudience audience) {
    final packages = offering.availablePackages;
    if (packages.isEmpty) return false;
    return packages.every((package) => _packageBelongsTo(package, audience));
  }

  bool _packageBelongsTo(Package package, PaywallAudience audience) {
    final blob =
        '${package.identifier} ${package.storeProduct.identifier} ${package.storeProduct.title}'
            .toLowerCase();
    final teacherHit = blob.contains('lehrer') || blob.contains('teacher');
    final studentHit =
        blob.contains('schueler') ||
        blob.contains('schüler') ||
        blob.contains('student');
    if (audience == PaywallAudience.teacher) {
      return teacherHit && !studentHit;
    }
    if (studentHit) return true;
    return !teacherHit;
  }
}

final revenueCatBillingProvider = ChangeNotifierProvider<RevenueCatBilling>(
  (ref) => RevenueCatBilling(),
);
