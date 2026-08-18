import 'package:betternotes/features/entitlements/entitlement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free keeps ads on as a coin faucet', () {
    const free = EntitlementState();
    expect(free.adsEnabled, isTrue);
    expect(free.canClaimDailyCoins, isFalse);

    final unlocked = free.copyWith(unlocked: {FeatureKeys.noForcedAds});
    expect(unlocked.adsEnabled, isTrue);
    expect(unlocked.canClaimDailyCoins, isFalse);
  });

  test('lite turns ads on after three marketplace buys; pro never does', () {
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
}
