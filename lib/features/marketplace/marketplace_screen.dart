import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../entitlements/ad_config.dart';
import '../entitlements/entitlement_model.dart';
import '../entitlements/rewarded_ad_mock.dart';
import '../entitlements/rewarded_ad_service.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  String _featureLabel(AppLocalizations l10n, String key) => switch (key) {
    FeatureKeys.premiumPaper => l10n.featurePremiumPaper,
    FeatureKeys.premiumCover => l10n.featurePremiumCover,
    FeatureKeys.audioTranscription => l10n.featureAudioTranscription,
    FeatureKeys.pdfCompress => l10n.featurePdfCompress,
    FeatureKeys.handwritingOcr => l10n.featureHandwritingOcr,
    FeatureKeys.noForcedAds => l10n.featureNoForcedAds,
    FeatureKeys.sessionCollab => l10n.featureSessionCollab,
    FeatureKeys.asyncCollab => l10n.featureAsyncCollab,
    FeatureKeys.whiteboard => l10n.featureWhiteboard,
    FeatureKeys.cloudSync => l10n.featureCloudSync,
    FeatureKeys.aiAssistant => l10n.featureAiAssistant,
    FeatureKeys.studyMode => l10n.featureStudyMode,
    _ => key,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entitlements = ref.watch(entitlementProvider);
    final ads = ref.watch(rewardedAdServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.marketplace, style: AppTheme.headline())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            l10n.marketplaceHint,
            style: AppTheme.body(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.monetization_on_outlined),
            title: Text(
              l10n.coinsBalance(entitlements.coins),
              style: AppTheme.body(fontWeight: FontWeight.w700),
            ),
            trailing: TextButton(
              onPressed: () => runRewardedUnlock(
                context: context,
                ref: ref,
                coinReward: AdConfig.coinsPerRewardedAd,
              ),
              child: Text(l10n.watchAdForCoins),
            ),
          ),
          if (ads.privacyOptionsRequired)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.adPrivacyOptions),
              subtitle: Text(l10n.adPrivacyOptionsHint),
              onTap: () => ads.showPrivacyOptions(),
            ),
          const SizedBox(height: 8),
          for (final key in FeatureKeys.all)
            _FeatureRow(
              label: _featureLabel(l10n, key),
              unlocked: entitlements.hasAccess(key),
              coinCost: FeatureKeys.coinCost(key),
              onUnlockCoins: () async {
                final ok = await ref
                    .read(entitlementProvider.notifier)
                    .unlockWithCoins(key);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? l10n.featureUnlocked : l10n.notEnoughCoins,
                    ),
                  ),
                );
              },
              onWatchAd: () => runRewardedUnlock(
                context: context,
                ref: ref,
                featureKey: key,
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.unlocked,
    required this.coinCost,
    required this.onUnlockCoins,
    required this.onWatchAd,
  });

  final String label;
  final bool unlocked;
  final int coinCost;
  final VoidCallback onUnlockCoins;
  final VoidCallback onWatchAd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        color: unlocked ? AppTheme.accent : AppTheme.inkMuted,
      ),
      title: Text(
        label,
        style: AppTheme.body(fontWeight: FontWeight.w700, color: AppTheme.ink),
      ),
      subtitle: Text(
        unlocked ? l10n.featureAvailable : l10n.unlockWithCoins(coinCost),
        style: AppTheme.body(
          fontWeight: FontWeight.w600,
          color: AppTheme.inkMuted,
          fontSize: 13,
        ),
      ),
      trailing: unlocked
          ? null
          : PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'coins') onUnlockCoins();
                if (v == 'ad') onWatchAd();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'coins',
                  child: Text(l10n.unlockWithCoins(coinCost)),
                ),
                PopupMenuItem(value: 'ad', child: Text(l10n.watchRewardedAd)),
              ],
            ),
    );
  }
}
