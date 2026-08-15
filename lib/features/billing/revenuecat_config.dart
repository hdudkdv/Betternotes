/// Public RevenueCat identifiers used by the app.
///
/// Store product IDs stay in the RevenueCat dashboard. The app only checks
/// entitlements and package types so offerings can change without a release.
abstract final class RevenueCatConfig {
  /// Test Store public API key. Production `appl_` / `goog_` keys override
  /// this via `--dart-define`.
  static const testApiKey = 'test_soJyMEtzmxcEsiuRYJLyOzgnznS';

  static const androidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const iosKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
  static const webKey = String.fromEnvironment('REVENUECAT_WEB_API_KEY');

  /// Entitlement created in the RevenueCat dashboard.
  static const notisPro = 'Notis Pro';

  /// Legacy / extra entitlements still recognised if present.
  static const pro = 'pro';
  static const proPlus = 'pro_plus';
  static const teacher = 'teacher';

  static const packageLifetime = 'lifetime';
  static const packageYearly = 'yearly';
  static const packageMonthly = 'monthly';
}
