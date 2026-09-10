/// Public RevenueCat identifiers used by the app.
///
/// Store product IDs stay in the RevenueCat dashboard. The app checks
/// entitlements so offerings can change without a release.
abstract final class RevenueCatConfig {
  static const androidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const iosKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: 'appl_SBgKLVYImUisVHmGZoKQHkXsoTd',
  );
  static const webKey = String.fromEnvironment('REVENUECAT_WEB_API_KEY');

  static const notisPro = 'Notis Pro';
  static const pro = 'pro';
  static const proPlus = 'pro_plus';
  static const teacher = 'teacher';
  static const schuelerLite = 'schueler_lite';
  static const schuelerPro = 'schueler_pro';
  static const lehrerLite = 'lehrer_lite';
  static const lehrerPro = 'lehrer_pro';

  static const packageLifetime = 'lifetime';
  static const packageYearly = 'yearly';
  static const packageMonthly = 'monthly';

  /// RevenueCat offering identifiers (dashboard → Offerings).
  /// Paywalls are named "Schüler" and "Lehrer" and attached to these offerings.
  static const offeringStudent = 'Schüler';
  static const offeringTeacher = 'Lehrer';
  static const offeringStudentAliases = [
    'Schüler',
    'Schueler',
    'schueler',
    'student',
    'schuelerLite',
    'schuelerPro',
    'schueler_lite_annual',
    'Schueler_lite_lifetime',
    'Schueler_Pro_annual',
    'Schueler_Pro_lifetime',
  ];
  static const offeringTeacherAliases = [
    'Lehrer',
    'lehrer',
    'teacher',
    'lehrer_lite',
    'lehrer_pro',
  ];

  static const teacherEntitlements = {lehrerPro, teacher};
  static const teacherLiteEntitlements = {lehrerLite};
  static const studentProEntitlements = {schuelerPro, notisPro, proPlus};
  static const studentLiteEntitlements = {schuelerLite, pro};

  /// App Store / Play product IDs. Used when RevenueCat offerings come back
  /// empty so StoreKit can still load the SKUs attached to the app.
  static const storeProductIds = [
    'schueler_lite',
    'schueler_pro',
    'lehrer_lite',
    'lehrer_pro',
    'schueler_lite_annual',
    'schueler_lite_lifetime',
    'schueler_pro_annual',
    'schueler_pro_lifetime',
    'Schueler_lite_lifetime',
    'Schueler_Pro_annual',
    'Schueler_Pro_lifetime',
    'lehrer_lite_monthly',
    'lehrer_pro_monthly',
    'notis_lite',
    'notis_pro',
  ];
}

enum PaywallAudience { student, teacher }
