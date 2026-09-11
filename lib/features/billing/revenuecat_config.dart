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
  /// Dashboard entitlement identifiers (RevenueCat → Entitlements).
  static const schuelerLite = 'schuelerLite';
  static const schuelerPro = 'schuelerPro';
  static const lehrerLite = 'lehrer_lite';
  static const lehrerPro = 'lehrer_pro';

  static const packageLifetime = 'lifetime';
  static const packageYearly = 'yearly';
  static const packageMonthly = 'monthly';

  /// RevenueCat offering identifiers (dashboard → Offerings).
  /// Current: `schueler` / `lehrer`; `default` is the mixed catalog.
  static const offeringStudent = 'schueler';
  static const offeringTeacher = 'lehrer';
  static const offeringStudentAliases = [
    'schueler',
    'Schüler',
    'Schueler',
    'student',
  ];
  static const offeringTeacherAliases = [
    'lehrer',
    'Lehrer',
    'teacher',
  ];

  static const teacherEntitlements = {lehrerPro, teacher};
  static const teacherLiteEntitlements = {lehrerLite};
  static const studentProEntitlements = {
    schuelerPro,
    'schueler_pro',
    notisPro,
    proPlus,
  };
  static const studentLiteEntitlements = {
    schuelerLite,
    'schueler_lite',
    pro,
  };

  /// Exact App Store product IDs from the RevenueCat product catalog.
  static const storeProductIds = [
    'schueler_lite_yearly',
    'schueler_pro_yearly',
    'schueler_Lite_lifetime',
    'schueler_Pro_lifetime',
    'lehrer_lite',
    'lehrer_pro',
  ];
}

enum PaywallAudience { student, teacher }
