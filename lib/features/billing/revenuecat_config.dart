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
  /// Prefer the role umbrellas; the rest are extra per-product offerings.
  static const offeringStudent = 'schueler';
  static const offeringTeacher = 'lehrer';
  static const offeringStudentAliases = [
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
    'lehrer',
    'teacher',
    'lehrer_lite',
    'lehrer_pro',
  ];

  static const teacherEntitlements = {lehrerPro, teacher};
  static const teacherLiteEntitlements = {lehrerLite};
  static const studentProEntitlements = {schuelerPro, notisPro, proPlus};
  static const studentLiteEntitlements = {schuelerLite, pro};
}

enum PaywallAudience { student, teacher }
