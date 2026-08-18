import 'package:betternotes/features/billing/plan_catalog.dart';
import 'package:betternotes/features/entitlements/entitlement_model.dart';
import 'package:betternotes/features/library/providers/library_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('six public plans: role × Free/Lite/Pro', () {
    expect(PlanCatalog.all, hasLength(6));
    expect(
      PlanCatalog.all.map((plan) => (plan.role, plan.paid)).toSet(),
      {
        (AppUserRole.student, PaidTier.free),
        (AppUserRole.student, PaidTier.lite),
        (AppUserRole.student, PaidTier.pro),
        (AppUserRole.teacher, PaidTier.free),
        (AppUserRole.teacher, PaidTier.lite),
        (AppUserRole.teacher, PaidTier.pro),
      },
    );
  });

  test('resolve maps role and paid level', () {
    expect(
      PlanCatalog.resolve(
        role: AppUserRole.student,
        paid: PaidTier.lite,
      ).id,
      NotisPlanId.studentLite,
    );
    expect(
      PlanCatalog.resolve(
        role: AppUserRole.teacher,
        paid: PaidTier.pro,
      ).id,
      NotisPlanId.teacherPro,
    );
  });

  test('ads are a coin faucet for free and lite after three buys', () {
    expect(const EntitlementState().adsEnabled, isTrue);
    expect(const EntitlementState(tier: AppTier.lite).adsEnabled, isFalse);
    expect(
      EntitlementState(
        tier: AppTier.lite,
        unlocked: FeatureKeys.marketplace.take(3).toSet(),
      ).adsEnabled,
      isTrue,
    );
    expect(const EntitlementState(tier: AppTier.pro).adsEnabled, isFalse);
  });

  test('free and lite buy marketplace extras with coins; pro loans', () {
    const free = EntitlementState(coins: 999);
    const lite = EntitlementState(tier: AppTier.lite, coins: 999);
    expect(free.canBuyMarketplace, isTrue);
    expect(lite.marketplaceBuyLimit, PlanCatalog.liteMarketplaceBuys);
    expect(lite.canBuyMarketplace, isTrue);
    expect(lite.canLoanMarketplace, isFalse);
    expect(lite.hasAccess(FeatureKeys.aiAssistant), isFalse);
    expect(lite.hasAccess(FeatureKeys.cloudSync), isTrue);
    expect(lite.hasAccess(FeatureKeys.asyncCollab), isFalse);
  });

  test('lite keeps buying after three; ads then turn on', () {
    var state = const EntitlementState(tier: AppTier.lite, coins: 999);
    final extras = FeatureKeys.marketplace.take(4).toList();
    for (var i = 0; i < 3; i++) {
      state = EntitlementState(
        tier: AppTier.lite,
        coins: state.coins,
        unlocked: {...state.unlocked, extras[i]},
      );
      expect(state.canBuyMarketplace, isTrue);
    }
    expect(state.marketplacePurchases, 3);
    expect(state.adsEnabled, isTrue);
    expect(state.hasAccess(extras[0]), isTrue);
    expect(state.hasAccess(extras[3]), isFalse);
  });

  test('pro loans five extras and can swap them', () {
    var state = const EntitlementState(tier: AppTier.pro);
    expect(state.marketplaceLoanLimit, PlanCatalog.proMarketplaceLoans);
    expect(state.canLoanMarketplace, isTrue);
    expect(state.hasAccess(FeatureKeys.asyncCollab), isTrue);
    expect(state.hasAccess(FeatureKeys.aiAssistant), isFalse);

    final extras = FeatureKeys.marketplace.take(6).toList();
    state = state.copyWith(loaned: extras.take(5).toSet());
    expect(state.marketplaceLoans, 5);
    expect(state.canLoanMarketplace, isFalse);
    expect(state.hasAccess(extras[0]), isTrue);
    expect(state.hasAccess(extras[5]), isFalse);

    state = state.copyWith(
      loaned: {for (final key in state.loaned) if (key != extras[0]) key},
    );
    expect(state.hasAccess(extras[0]), isFalse);
    expect(state.canLoanMarketplace, isTrue);
  });

  test('loans stop working after leaving pro', () {
    const loaned = EntitlementState(
      tier: AppTier.pro,
      loaned: {FeatureKeys.aiAssistant},
    );
    expect(loaned.hasAccess(FeatureKeys.aiAssistant), isTrue);
    expect(
      loaned.copyWith(tier: AppTier.lite).hasAccess(FeatureKeys.aiAssistant),
      isFalse,
    );
  });

  test('whiteboard is teacher pro only', () {
    expect(
      const EntitlementState(tier: AppTier.pro).hasAccess(
        FeatureKeys.whiteboard,
        isTeacherRole: false,
      ),
      isFalse,
    );
    expect(
      const EntitlementState(tier: AppTier.lite).hasAccess(
        FeatureKeys.whiteboard,
        isTeacherRole: true,
      ),
      isFalse,
    );
    expect(
      const EntitlementState(tier: AppTier.pro).hasAccess(
        FeatureKeys.whiteboard,
        isTeacherRole: true,
      ),
      isTrue,
    );
  });

  test('notifier lets free and lite buy with coins; pro loans', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final entitlements = EntitlementNotifier(prefs);
    await entitlements.addCoins(999);
    expect(await entitlements.unlockWithCoins(FeatureKeys.aiAssistant), isTrue);
    expect(await entitlements.borrowFeature(FeatureKeys.pdfCompress), isFalse);

    await entitlements.setTier(AppTier.lite);
    await entitlements.addCoins(999);
    expect(await entitlements.unlockWithCoins(FeatureKeys.pdfCompress), isTrue);
    expect(await entitlements.unlockWithCoins(FeatureKeys.handwritingOcr), isTrue);
    expect(await entitlements.unlockWithCoins(FeatureKeys.chartPack), isTrue);
    expect(entitlements.state.adsEnabled, isTrue);
    expect(await entitlements.borrowFeature(FeatureKeys.calcPlus), isFalse);

    await entitlements.setTier(AppTier.pro);
    expect(await entitlements.unlockWithCoins(FeatureKeys.calcPlus), isFalse);
    expect(await entitlements.borrowFeature(FeatureKeys.calcPlus), isTrue);
    await entitlements.returnLoan(FeatureKeys.calcPlus);
    expect(entitlements.state.hasAccess(FeatureKeys.calcPlus), isFalse);
  });

  test('legacy stored pro becomes lite; proPlus becomes pro', () {
    expect(
      EntitlementState.fromJson({'tier': 'pro'}).paidTier,
      PaidTier.lite,
    );
    expect(
      EntitlementState.fromJson({'tier': 'proPlus'}).paidTier,
      PaidTier.pro,
    );
    expect(
      EntitlementState.fromJson({'tier': 'teacher', 'paidTier': 'pro'}).paidTier,
      PaidTier.pro,
    );
  });
}
