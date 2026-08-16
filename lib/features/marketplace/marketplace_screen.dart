import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../entitlements/ad_config.dart';
import '../entitlements/entitlement_model.dart';
import '../entitlements/rewarded_ad_mock.dart';
import '../entitlements/rewarded_ad_service.dart';
import '../packs/pack_catalog.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  String _featureLabel(BuildContext context, AppLocalizations l10n, String key) =>
      switch (key) {
    FeatureKeys.aiAssistant => l10n.featureAiAssistant,
    FeatureKeys.chartPack => l10n.featureChartPack,
    FeatureKeys.calcPlus => l10n.featureCalcPlus,
    FeatureKeys.formulaPack => l10n.featureFormulaPack,
    FeatureKeys.helperPack => l10n.featureHelperPack,
    _ => PackCatalog.byKey(key)?.title(
            Localizations.localeOf(context).languageCode == 'de',
          ) ??
          key,
  };

  String _featureInfo(BuildContext context, AppLocalizations l10n, String key) =>
      switch (key) {
    FeatureKeys.aiAssistant => l10n.featureInfoAiAssistant,
    FeatureKeys.chartPack => l10n.featureInfoChartPack,
    FeatureKeys.calcPlus => l10n.featureInfoCalcPlus,
    FeatureKeys.formulaPack => l10n.featureInfoFormulaPack,
    FeatureKeys.helperPack => l10n.featureInfoHelperPack,
    _ => PackCatalog.byKey(key)?.body(
            Localizations.localeOf(context).languageCode == 'de',
          ) ??
          l10n.marketplaceMoreInfo,
  };

  Future<void> _unlockCoins(
    BuildContext context,
    WidgetRef ref,
    String key,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ref.read(entitlementProvider.notifier).unlockWithCoins(key);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.featureUnlocked : l10n.notEnoughCoins),
      ),
    );
  }

  Future<void> _showInfo(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.paper,
        title: Text(
          title,
          style: AppTheme.headline(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        content: Text(body, style: AppTheme.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entitlements = ref.watch(entitlementProvider);
    final ads = ref.watch(rewardedAdServiceProvider);
    final gemmaOn = entitlements.hasAccess(FeatureKeys.aiAssistant);
    final gemmaCost = FeatureKeys.coinCost(FeatureKeys.aiAssistant);

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
          _GemmaCard(
            unlocked: gemmaOn,
            coinCost: gemmaCost,
            onUnlock: () =>
                _unlockCoins(context, ref, FeatureKeys.aiAssistant),
            onInfo: () => _showInfo(
              context,
              title: l10n.gemmaTitle,
              body: l10n.featureInfoAiAssistant,
            ),
          ),
          for (final group in PackCatalog.groups) ...[
            const SizedBox(height: 20),
            Text(
              switch (group.id) {
                'study' => l10n.marketplaceGroupStudy,
                'work' => l10n.marketplaceGroupWork,
                _ => l10n.marketplaceGroupLife,
              },
              style: AppTheme.body(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            for (final key in group.keys)
              if (key != FeatureKeys.aiAssistant)
                _FeatureRow(
                  label: _featureLabel(context, l10n, key),
                  unlocked: entitlements.hasAccess(key),
                  coinCost: FeatureKeys.coinCost(key),
                  onUnlock: () => _unlockCoins(context, ref, key),
                  onInfo: () => _showInfo(
                    context,
                    title: _featureLabel(context, l10n, key),
                    body: _featureInfo(context, l10n, key),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _GemmaCard extends StatelessWidget {
  const _GemmaCard({
    required this.unlocked,
    required this.coinCost,
    required this.onUnlock,
    required this.onInfo,
  });

  final bool unlocked;
  final int coinCost;
  final VoidCallback onUnlock;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppTheme.palette;
    return Material(
      color: palette.surfaceRaised,
      borderRadius: BorderRadius.circular(palette.radius + 8),
      child: InkWell(
        onTap: unlocked ? null : onUnlock,
        borderRadius: BorderRadius.circular(palette.radius + 8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(palette.radius + 8),
            border: Border.all(
              color: unlocked ? palette.accent : palette.outline,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.gemmaTitle,
                          style: AppTheme.headline(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.ink,
                          ),
                        ),
                        Text(
                          unlocked
                              ? l10n.gemmaReady
                              : l10n.unlockWithCoins(coinCost),
                          style: AppTheme.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: unlocked
                                ? palette.accent
                                : palette.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    unlocked
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    color: unlocked ? palette.accent : palette.inkMuted,
                  ),
                  IconButton(
                    tooltip: l10n.marketplaceMoreInfo,
                    onPressed: onInfo,
                    icon: const Icon(Icons.info_outline, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 10),
                child: Text(
                  l10n.gemmaSubtitle,
                  style: AppTheme.body(fontSize: 13, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.unlocked,
    required this.coinCost,
    required this.onUnlock,
    required this.onInfo,
  });

  final String label;
  final bool unlocked;
  final int coinCost;
  final VoidCallback onUnlock;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: unlocked ? null : onUnlock,
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
      trailing: IconButton(
        tooltip: l10n.marketplaceMoreInfo,
        onPressed: onInfo,
        icon: const Icon(Icons.info_outline, size: 20),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
