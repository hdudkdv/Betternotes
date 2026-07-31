import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'entitlement_model.dart';
import 'rewarded_ad_service.dart';

/// Fallback for platforms without AdMob: the user confirms a stand-in “video”.
Future<bool> showRewardedAdMock(
  BuildContext context, {
  required String title,
  required String body,
  int coinReward = 15,
  String? unlockFeature,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppTheme.paper,
        title: Text(
          title,
          style: AppTheme.headline(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8D9C8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.rewardedAdDemoBadge,
                style: AppTheme.body(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: AppTheme.body(
                fontWeight: FontWeight.w600,
                color: AppTheme.inkMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.watchRewardedAd),
          ),
        ],
      );
    },
  );
  return go == true;
}

/// Grants [featureKey] or [coinReward] after a rewarded ad has been watched.
///
/// Uses AdMob where available and falls back to [showRewardedAdMock] on
/// platforms without ads or when no ad fills.
Future<void> runRewardedUnlock({
  required BuildContext context,
  required WidgetRef ref,
  String? featureKey,
  int coinReward = 15,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final ads = ref.read(rewardedAdServiceProvider);

  var rewarded = false;
  if (ads.isSupported) {
    if (!ads.hasAd) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.rewardedAdLoading),
          duration: const Duration(seconds: 1),
        ),
      );
    }
    switch (await ads.show()) {
      case RewardedAdOutcome.earned:
        rewarded = true;
      case RewardedAdOutcome.dismissed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.rewardedAdNotFinished)),
        );
        return;
      case RewardedAdOutcome.unavailable:
        break;
    }
  }

  if (!rewarded) {
    if (!context.mounted) return;
    final ok = await showRewardedAdMock(
      context,
      title: l10n.rewardedAdTitle,
      body: featureKey == null
          ? l10n.rewardedAdCoinsBody(coinReward)
          : l10n.rewardedAdFeatureBody,
      coinReward: coinReward,
      unlockFeature: featureKey,
    );
    if (!ok) return;
  }

  final notifier = ref.read(entitlementProvider.notifier);
  if (featureKey != null) {
    await notifier.unlockFeature(featureKey);
  } else {
    await notifier.addCoins(coinReward);
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        featureKey != null
            ? l10n.featureUnlocked
            : l10n.coinsEarned(coinReward),
      ),
    ),
  );
}
