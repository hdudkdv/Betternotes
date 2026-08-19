import '../entitlements/entitlement_model.dart';
import '../library/providers/library_providers.dart';

/// One of the six public Notis plans: role × paid level.
enum NotisPlanId {
  studentFree,
  studentLite,
  studentPro,
  teacherFree,
  teacherLite,
  teacherPro,
}

class NotisPlan {
  const NotisPlan({
    required this.id,
    required this.paid,
    required this.role,
    required this.titleDe,
    required this.titleEn,
    required this.priceDe,
    required this.priceEn,
    required this.pointsDe,
    required this.pointsEn,
  });

  final NotisPlanId id;
  final PaidTier paid;
  final AppUserRole role;
  final String titleDe;
  final String titleEn;
  final String priceDe;
  final String priceEn;
  final List<String> pointsDe;
  final List<String> pointsEn;

  String title(bool german) => german ? titleDe : titleEn;
  String price(bool german) => german ? priceDe : priceEn;
  List<String> points(bool german) => german ? pointsDe : pointsEn;

  bool get isTeacher => role == AppUserRole.teacher;
  bool get isPaid => paid != PaidTier.free;
}

/// Product matrix. Store SKUs are Lite/Pro per role; Free is the default.
abstract final class PlanCatalog {
  static const liteMarketplaceBuys = 3;
  static const proMarketplaceLoans = 5;

  static const studentFree = NotisPlan(
    id: NotisPlanId.studentFree,
    paid: PaidTier.free,
    role: AppUserRole.student,
    titleDe: 'Schüler Free',
    titleEn: 'Student Free',
    priceDe: 'Kostenlos',
    priceEn: 'Free',
    pointsDe: [
      'Notizen, Sticker und Notizzettel',
      'Marketplace nur mit Coins',
    ],
    pointsEn: [
      'Notes, stickers and sticky notes',
      'Marketplace with coins only',
    ],
  );

  static const studentLite = NotisPlan(
    id: NotisPlanId.studentLite,
    paid: PaidTier.lite,
    role: AppUserRole.student,
    titleDe: 'Schüler Lite',
    titleEn: 'Student Lite',
    priceDe: '4,99 € / Jahr oder 20 € einmalig',
    priceEn: '€4.99 / year or €20 lifetime',
    pointsDe: [
      'Wöchentliches Backup',
      'Online-Sync für 5 Notizbücher gleichzeitig',
      '3 Marketplace-Artikel dauerhaft kaufen',
      'Danach weitere Artikel mit Coins aus Werbung',
    ],
    pointsEn: [
      'Weekly backup',
      'Online sync for 5 notebooks at a time',
      'Buy 3 marketplace items permanently',
      'Then more items with coins from ads',
    ],
  );

  static const studentPro = NotisPlan(
    id: NotisPlanId.studentPro,
    paid: PaidTier.pro,
    role: AppUserRole.student,
    titleDe: 'Schüler Pro',
    titleEn: 'Student Pro',
    priceDe: '9,99 € / Jahr oder 30 € einmalig',
    priceEn: '€9.99 / year or €30 lifetime',
    pointsDe: [
      'Tägliches Backup',
      'Unbegrenzter Online-Sync',
      '5 Marketplace-Artikel gleichzeitig leihen',
    ],
    pointsEn: [
      'Daily backup',
      'Unlimited online sync',
      'Borrow 5 marketplace items at a time',
    ],
  );

  static const teacherFree = NotisPlan(
    id: NotisPlanId.teacherFree,
    paid: PaidTier.free,
    role: AppUserRole.teacher,
    titleDe: 'Lehrer Free',
    titleEn: 'Teacher Free',
    priceDe: 'Kostenlos',
    priceEn: 'Free',
    pointsDe: [
      'Klassen, Stundenplan und Aufgaben lokal',
      'Marketplace nur mit Coins',
    ],
    pointsEn: [
      'Classes, timetable and assignments on device',
      'Marketplace with coins only',
    ],
  );

  static const teacherLite = NotisPlan(
    id: NotisPlanId.teacherLite,
    paid: PaidTier.lite,
    role: AppUserRole.teacher,
    titleDe: 'Lehrer Lite',
    titleEn: 'Teacher Lite',
    priceDe: '1,99 € / Monat',
    priceEn: '€1.99 / month',
    pointsDe: [
      'Wöchentliches Backup',
      'Online-Sync für 5 Notizbücher gleichzeitig',
      'Zugriff auf den Lehrmittel-Austausch',
      '3 Marketplace-Artikel dauerhaft kaufen',
      'Danach weitere Artikel mit Coins aus Werbung',
    ],
    pointsEn: [
      'Weekly backup',
      'Online sync for 5 notebooks at a time',
      'Teacher exchange access',
      'Buy 3 marketplace items permanently',
      'Then more items with coins from ads',
    ],
  );

  static const teacherPro = NotisPlan(
    id: NotisPlanId.teacherPro,
    paid: PaidTier.pro,
    role: AppUserRole.teacher,
    titleDe: 'Lehrer Pro',
    titleEn: 'Teacher Pro',
    priceDe: '9,99 € / Monat',
    priceEn: '€9.99 / month',
    pointsDe: [
      'Tägliches Backup',
      'Lehrer-Whiteboard',
      '5 Marketplace-Artikel gleichzeitig leihen',
      '5 Marketplace-Leihgaben pro Klasse',
    ],
    pointsEn: [
      'Daily backup',
      'Teacher whiteboard',
      'Borrow 5 marketplace items at a time',
      '5 marketplace loans per class',
    ],
  );

  static const all = <NotisPlan>[
    studentFree,
    studentLite,
    studentPro,
    teacherFree,
    teacherLite,
    teacherPro,
  ];

  static const paidStorePlans = <NotisPlan>[
    studentLite,
    studentPro,
    teacherLite,
    teacherPro,
  ];

  static NotisPlan resolve({
    required AppUserRole role,
    required PaidTier paid,
  }) {
    final teacher = role == AppUserRole.teacher;
    return switch (paid) {
      PaidTier.free => teacher ? teacherFree : studentFree,
      PaidTier.lite => teacher ? teacherLite : studentLite,
      PaidTier.pro => teacher ? teacherPro : studentPro,
    };
  }

  static List<NotisPlan> paidFor(AppUserRole role) => [
    for (final plan in paidStorePlans)
      if (plan.role == role) plan,
  ];

  /// Core features that Lite and Pro include (not marketplace extras).
  static const liteFeatures = <String>{
    FeatureKeys.premiumPaper,
    FeatureKeys.premiumCover,
    FeatureKeys.sessionCollab,
    FeatureKeys.cloudSync,
    FeatureKeys.studyMode,
  };

  static const proOnlyFeatures = <String>{
    FeatureKeys.asyncCollab,
  };
}
