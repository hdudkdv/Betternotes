import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../entitlements/ad_config.dart';
import '../entitlements/entitlement_model.dart';
import '../entitlements/rewarded_ad_mock.dart';
import '../entitlements/rewarded_ad_service.dart';
import '../packs/pack_catalog.dart';
import '../tools/assistant/gemma_runtime.dart';
import '../tools/assistant/gemma_setup.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(entitlementProvider).adsEnabled) {
        unawaited(ref.read(rewardedAdServiceProvider).preload());
      }
      unawaited(ref.read(gemmaRuntimeProvider).restore());
    });
  }

  String _featureLabel(
    BuildContext context,
    AppLocalizations l10n,
    String key,
  ) => switch (key) {
    FeatureKeys.aiAssistant => l10n.featureAiAssistant,
    FeatureKeys.pdfCompress => l10n.featurePdfCompress,
    FeatureKeys.handwritingOcr => l10n.featureHandwritingOcr,
    FeatureKeys.audioTranscription => l10n.featureAudioTranscription,
    FeatureKeys.chartPack => l10n.featureChartPack,
    FeatureKeys.calcPlus => l10n.featureCalcPlus,
    FeatureKeys.formulaPack => l10n.featureFormulaPack,
    FeatureKeys.helperPack => l10n.featureHelperPack,
    _ =>
      PackCatalog.byKey(
            key,
          )?.title(Localizations.localeOf(context).languageCode == 'de') ??
          key,
  };

  String _featureInfo(
    BuildContext context,
    AppLocalizations l10n,
    String key,
  ) => switch (key) {
    FeatureKeys.aiAssistant => l10n.featureInfoAiAssistant,
    FeatureKeys.pdfCompress => l10n.featureInfoPdfCompress,
    FeatureKeys.handwritingOcr => l10n.featureInfoHandwritingOcr,
    FeatureKeys.audioTranscription => l10n.featureInfoAudioTranscription,
    FeatureKeys.chartPack => l10n.featureInfoChartPack,
    FeatureKeys.calcPlus => l10n.featureInfoCalcPlus,
    FeatureKeys.formulaPack => l10n.featureInfoFormulaPack,
    FeatureKeys.helperPack => l10n.featureInfoHelperPack,
    _ =>
      PackCatalog.byKey(
            key,
          )?.body(Localizations.localeOf(context).languageCode == 'de') ??
          l10n.marketplaceMoreInfo,
  };

  Future<void> _unlockCoins(
    BuildContext context,
    WidgetRef ref,
    String key,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final entitlements = ref.read(entitlementProvider);
    if (FeatureKeys.marketplace.contains(key) &&
        entitlements.paidTier == PaidTier.pro) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.marketplaceNeedPro)));
      return;
    }
    final ok = await ref
        .read(entitlementProvider.notifier)
        .unlockWithCoins(key);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.featureUnlocked : l10n.notEnoughCoins)),
    );
    if (ok && key == FeatureKeys.aiAssistant && context.mounted) {
      await showGemmaSetupSheet(context);
    }
  }

  Future<void> _borrow(
    BuildContext context,
    WidgetRef ref,
    String key,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final entitlements = ref.read(entitlementProvider);
    if (entitlements.paidTier != PaidTier.pro) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.marketplaceNeedPro)));
      return;
    }
    if (!entitlements.canLoanMarketplace) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.marketplaceLoanCap)));
      return;
    }
    final ok = await ref.read(entitlementProvider.notifier).borrowFeature(key);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.featureUnlocked : l10n.marketplaceLoanCap)),
    );
    if (ok && key == FeatureKeys.aiAssistant && context.mounted) {
      await showGemmaSetupSheet(context);
    }
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
  Widget build(BuildContext context) {
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
          if (entitlements.paidTier == PaidTier.lite) ...[
            const SizedBox(height: 8),
            Text(
              l10n.marketplaceBuySlots(
                entitlements.marketplacePurchases >
                        entitlements.marketplaceBuyLimit
                    ? entitlements.marketplaceBuyLimit
                    : entitlements.marketplacePurchases,
                entitlements.marketplaceBuyLimit,
              ),
              style: AppTheme.body(fontWeight: FontWeight.w700),
            ),
            if (entitlements.adsEnabled) ...[
              const SizedBox(height: 4),
              Text(
                l10n.marketplaceLiteAfterHint,
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
            ],
          ],
          if (entitlements.paidTier == PaidTier.pro) ...[
            const SizedBox(height: 8),
            Text(
              l10n.marketplaceLoanSlots(
                entitlements.marketplaceLoans,
                entitlements.marketplaceLoanLimit,
              ),
              style: AppTheme.body(fontWeight: FontWeight.w700),
            ),
          ],
          if (entitlements.paidTier != PaidTier.pro) ...[
            const SizedBox(height: 16),
            _AdsPremiumCard(
              entitlements: entitlements,
              ads: ads,
              onWatchAd: () => runRewardedUnlock(
                context: context,
                ref: ref,
                coinReward: AdConfig.coinsPerRewardedAd,
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 16),
          _GemmaCard(
            unlocked: gemmaOn,
            loaned: entitlements.loaned.contains(FeatureKeys.aiAssistant),
            paidTier: entitlements.paidTier,
            coinCost: gemmaCost,
            modelReady: ref.watch(gemmaRuntimeProvider).isReady,
            onUnlock: entitlements.paidTier == PaidTier.pro
                ? () => _borrow(context, ref, FeatureKeys.aiAssistant)
                : () => _unlockCoins(context, ref, FeatureKeys.aiAssistant),
            onReturn: entitlements.loaned.contains(FeatureKeys.aiAssistant)
                ? () => ref
                      .read(entitlementProvider.notifier)
                      .returnLoan(FeatureKeys.aiAssistant)
                : null,
            onSetup: () => showGemmaSetupSheet(context),
            onInfo: () => _showInfo(
              context,
              title: l10n.gemmaTitle,
              body: l10n.featureInfoAiAssistant,
            ),
          ),
          for (final group in PackCatalog.groups) ...[
            const SizedBox(height: 20),
            Text(switch (group.id) {
              'study' => l10n.marketplaceGroupStudy,
              'work' => l10n.marketplaceGroupWork,
              _ => l10n.marketplaceGroupLife,
            }, style: AppTheme.body(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            for (final key in group.keys)
              if (key != FeatureKeys.aiAssistant)
                _FeatureRow(
                  label: _featureLabel(context, l10n, key),
                  unlocked: entitlements.hasAccess(key),
                  loaned: entitlements.loaned.contains(key),
                  coinCost: FeatureKeys.coinCost(key),
                  paidTier: entitlements.paidTier,
                  onUnlock: entitlements.paidTier == PaidTier.pro
                      ? () => _borrow(context, ref, key)
                      : () => _unlockCoins(context, ref, key),
                  onReturn: entitlements.loaned.contains(key)
                      ? () => ref
                            .read(entitlementProvider.notifier)
                            .returnLoan(key)
                      : null,
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
    required this.loaned,
    required this.paidTier,
    required this.coinCost,
    required this.modelReady,
    required this.onUnlock,
    required this.onSetup,
    required this.onInfo,
    this.onReturn,
  });

  final bool unlocked;
  final bool loaned;
  final PaidTier paidTier;
  final int coinCost;
  final bool modelReady;
  final VoidCallback onUnlock;
  final VoidCallback onSetup;
  final VoidCallback onInfo;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppTheme.palette;
    return Material(
      color: palette.surfaceRaised,
      borderRadius: BorderRadius.circular(palette.radius + 8),
      child: InkWell(
        onTap: unlocked ? onSetup : onUnlock,
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
                    child: Icon(Icons.school_outlined, color: palette.accent),
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
                              ? (loaned
                                    ? l10n.marketplaceBorrow
                                    : (modelReady
                                          ? l10n.gemmaReady
                                          : l10n.gemmaNeedsSetup))
                              : paidTier == PaidTier.pro
                              ? l10n.marketplaceBorrow
                              : l10n.unlockWithCoins(coinCost),
                          style: AppTheme.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: unlocked ? palette.accent : palette.inkMuted,
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
                  if (loaned && onReturn != null)
                    TextButton(
                      onPressed: onReturn,
                      child: Text(l10n.marketplaceReturnLoan),
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
    required this.loaned,
    required this.coinCost,
    required this.paidTier,
    required this.onUnlock,
    required this.onInfo,
    this.onReturn,
  });

  final String label;
  final bool unlocked;
  final bool loaned;
  final int coinCost;
  final PaidTier paidTier;
  final VoidCallback onUnlock;
  final VoidCallback onInfo;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = unlocked
        ? (loaned ? l10n.marketplaceBorrow : l10n.featureAvailable)
        : paidTier == PaidTier.pro
        ? l10n.marketplaceBorrow
        : l10n.unlockWithCoins(coinCost);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: unlocked && !loaned ? null : (loaned ? onReturn : onUnlock),
      leading: Icon(
        unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        color: unlocked ? AppTheme.accent : AppTheme.inkMuted,
      ),
      title: Text(
        label,
        style: AppTheme.body(fontWeight: FontWeight.w700, color: AppTheme.ink),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.body(
          fontWeight: FontWeight.w600,
          color: AppTheme.inkMuted,
          fontSize: 13,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loaned && onReturn != null)
            TextButton(
              onPressed: onReturn,
              child: Text(l10n.marketplaceReturnLoan),
            ),
          IconButton(
            tooltip: l10n.marketplaceMoreInfo,
            onPressed: onInfo,
            icon: const Icon(Icons.info_outline, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AdsPremiumCard extends StatelessWidget {
  const _AdsPremiumCard({
    required this.entitlements,
    required this.ads,
    required this.onWatchAd,
  });

  final EntitlementState entitlements;
  final RewardedAdService ads;
  final VoidCallback onWatchAd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showAds = entitlements.adsEnabled;
    return Material(
      color: AppTheme.palette.surfaceRaised,
      borderRadius: BorderRadius.circular(AppTheme.palette.radius + 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  showAds
                      ? Icons.smart_display_outlined
                      : Icons.monetization_on_outlined,
                  color: AppTheme.inkMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    showAds ? l10n.adsForCoinsTitle : l10n.coinsBalance(entitlements.coins),
                    style: AppTheme.body(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Text(
                showAds
                    ? l10n.adsForCoinsHint
                    : l10n.marketplaceLiteCoinsHint,
                style: AppTheme.body(
                  fontSize: 13,
                  color: AppTheme.inkMuted,
                  height: 1.35,
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.monetization_on_outlined),
              title: Text(
                l10n.coinsBalance(entitlements.coins),
                style: AppTheme.body(fontWeight: FontWeight.w700),
              ),
              trailing: showAds
                  ? TextButton(
                      onPressed: onWatchAd,
                      child: Text(l10n.watchAdForCoins),
                    )
                  : null,
            ),
            if (showAds && ads.privacyOptionsRequired)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.adPrivacyOptions),
                subtitle: Text(l10n.adPrivacyOptionsHint),
                onTap: ads.showPrivacyOptions,
              ),
          ],
        ),
      ),
    );
  }
}
