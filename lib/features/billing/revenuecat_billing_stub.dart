import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entitlements/entitlement_model.dart';

enum PurchaseOutcome { success, cancelled, error, unavailable }

enum PackageType {
  unknown,
  custom,
  lifetime,
  annual,
  sixMonth,
  threeMonth,
  twoMonth,
  monthly,
  weekly,
}

enum ProductCategory { subscription, nonSubscription }

class StoreProduct {
  String get title => '';
  String get description => '';
  String get priceString => '';
  String get identifier => '';
  ProductCategory? get productCategory => null;
  String? get subscriptionPeriod => null;
}

class Package {
  StoreProduct get storeProduct => StoreProduct();
  PackageType get packageType => PackageType.unknown;
}

class Offering {
  List<Package> get availablePackages => const [];
  Package? get lifetime => null;
  Package? get annual => null;
  Package? get monthly => null;
  Package? getPackage(String id) => null;
}

class Offerings {
  Offering? get current => null;
  Map<String, Offering> get all => const {};
}

class CustomerInfo {}

class RevenueCatBilling extends ChangeNotifier {
  bool configured = false;
  String? error;
  String? userMessage;
  bool purchasing = false;
  AppTier tier = AppTier.free;
  Offerings? offerings;
  CustomerInfo? customerInfo;

  bool get hasNotisPro => false;
  bool get usesTestStore => false;
  bool get paywallSupported => false;
  bool get hasStoreProducts => false;

  Offering? get currentOffering => null;
  Offering? offeringForAudience(Object audience) => null;
  List<Package> packagesForAudience(Object audience) => const [];
  List<StoreProduct> productsForAudience(Object audience) => const [];
  Package? packageForProduct(StoreProduct product) => null;
  Package? get lifetimePackage => null;
  Package? get yearlyPackage => null;
  Package? get monthlyPackage => null;

  Future<void> initialize({String? appUserId}) async {
    configured = false;
    error = null;
    notifyListeners();
  }

  Future<void> syncAppUser(String? appUserId) async {}

  Future<void> refresh() async {}

  Future<PurchaseOutcome> restorePurchases() async =>
      PurchaseOutcome.unavailable;

  Future<PurchaseOutcome> purchase(Package package) async =>
      PurchaseOutcome.unavailable;

  Future<PurchaseOutcome> purchaseProduct(StoreProduct product) async =>
      PurchaseOutcome.unavailable;

  Future<PurchaseOutcome> purchaseNamed(String packageId) async =>
      PurchaseOutcome.unavailable;

  Future<PurchaseOutcome> presentPaywall({
    Object? audience,
    BuildContext? context,
  }) async => PurchaseOutcome.unavailable;

  Future<PurchaseOutcome> presentPaywallIfNeeded({Object? audience}) async =>
      PurchaseOutcome.unavailable;

  void applyCustomerInfo(Object info) {}

  Future<void> presentCustomerCenter() async {}
}

final revenueCatBillingProvider = ChangeNotifierProvider<RevenueCatBilling>(
  (ref) => RevenueCatBilling(),
);
