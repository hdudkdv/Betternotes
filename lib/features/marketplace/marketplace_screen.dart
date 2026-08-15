import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../entitlements/entitlement_model.dart';

/// Placeholder store for optional add-ons that not every user needs.
class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entitlements = ref.watch(entitlementProvider);
    final items = <_MarketItem>[
      _MarketItem(
        keyName: FeatureKeys.handwritingOcr,
        icon: Icons.draw_outlined,
        title: l10n.featureHandwritingOcr,
        subtitle: l10n.marketplaceInkOcrHint,
      ),
      _MarketItem(
        keyName: FeatureKeys.cloudSync,
        icon: Icons.cloud_outlined,
        title: l10n.featureCloudSync,
        subtitle: l10n.marketplaceCloudHint,
      ),
      _MarketItem(
        keyName: FeatureKeys.audioTranscription,
        icon: Icons.mic_none_rounded,
        title: l10n.featureAudioTranscription,
        subtitle: l10n.marketplaceComingSoon,
      ),
      _MarketItem(
        keyName: FeatureKeys.pdfCompress,
        icon: Icons.compress_rounded,
        title: l10n.featurePdfCompress,
        subtitle: l10n.marketplaceComingSoon,
      ),
      _MarketItem(
        keyName: FeatureKeys.asyncCollab,
        icon: Icons.groups_outlined,
        title: l10n.featureAsyncCollab,
        subtitle: l10n.marketplaceComingSoon,
      ),
      _MarketItem(
        keyName: FeatureKeys.whiteboard,
        icon: Icons.cast_for_education_outlined,
        title: l10n.featureWhiteboard,
        subtitle: l10n.marketplaceComingSoon,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.marketplace, style: AppTheme.headline()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(l10n.marketplaceHint, style: AppTheme.body(color: AppTheme.inkMuted)),
          const SizedBox(height: 16),
          for (final item in items)
            Card(
              elevation: 0,
              color: AppTheme.card,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(item.icon, color: AppTheme.accent),
                title: Text(
                  item.title,
                  style: AppTheme.body(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(item.subtitle),
                trailing: Text(
                  entitlements.hasAccess(item.keyName)
                      ? l10n.featureAvailable
                      : l10n.marketplaceSoonBadge,
                  style: AppTheme.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketItem {
  const _MarketItem({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
}
