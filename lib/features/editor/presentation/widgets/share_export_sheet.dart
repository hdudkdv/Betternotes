import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../entitlements/entitlement_model.dart';
import '../editor_chrome.dart';
import 'editor_sheet.dart';

enum ShareExportAction {
  printPdf,
  sharePdf,
  shareCurrentPage,
  sharePageAsImage,
  savePageAsTemplate,
  indexHandwriting,
}

Future<ShareExportAction?> showShareExportSheet(BuildContext context) {
  return showEditorSheet<ShareExportAction>(
    context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return Consumer(
        builder: (context, ref, _) {
          final entitlements = ref.watch(entitlementProvider);
          return EditorSheet(
            title: l10n.shareExport,
            children: [
              EditorSheetTile(
                icon: Icons.print_outlined,
                label: l10n.printPdf,
                chevron: false,
                onTap: () => Navigator.pop(context, ShareExportAction.printPdf),
              ),
              EditorSheetTile(
                icon: Icons.ios_share_outlined,
                label: l10n.sharePdf,
                chevron: false,
                onTap: () => Navigator.pop(context, ShareExportAction.sharePdf),
              ),
              EditorSheetTile(
                icon: Icons.crop_portrait,
                label: l10n.shareCurrentPage,
                chevron: false,
                onTap: () =>
                    Navigator.pop(context, ShareExportAction.shareCurrentPage),
              ),
              EditorSheetTile(
                icon: Icons.image_outlined,
                label: l10n.exportPageAsImage,
                chevron: false,
                onTap: () =>
                    Navigator.pop(context, ShareExportAction.sharePageAsImage),
              ),
              EditorSheetTile(
                icon: Icons.dashboard_customize_outlined,
                label: l10n.savePageAsTemplate,
                chevron: false,
                onTap: () => Navigator.pop(
                  context,
                  ShareExportAction.savePageAsTemplate,
                ),
              ),
              const SizedBox(height: 14),
              EditorSheetGroup(l10n.exportExtras),
              _GatedExtraTile(
                icon: Icons.compress_outlined,
                title: l10n.featurePdfCompress,
                unlocked: entitlements.hasAccess(FeatureKeys.pdfCompress),
                coinCost: FeatureKeys.coinCost(FeatureKeys.pdfCompress),
              ),
              _GatedExtraTile(
                icon: Icons.document_scanner_outlined,
                title: l10n.featureHandwritingOcr,
                unlocked: entitlements.hasAccess(FeatureKeys.handwritingOcr),
                unlockedHint: l10n.marketplaceInkOcrHint,
                coinCost: FeatureKeys.coinCost(FeatureKeys.handwritingOcr),
                onUnlocked: () => Navigator.pop(
                  context,
                  ShareExportAction.indexHandwriting,
                ),
              ),
              _GatedExtraTile(
                icon: Icons.mic_none_outlined,
                title: l10n.featureAudioTranscription,
                unlocked: entitlements.hasAccess(
                  FeatureKeys.audioTranscription,
                ),
                coinCost: FeatureKeys.coinCost(FeatureKeys.audioTranscription),
              ),
            ],
          );
        },
      );
    },
  );
}

class _GatedExtraTile extends StatelessWidget {
  const _GatedExtraTile({
    required this.icon,
    required this.title,
    required this.unlocked,
    required this.coinCost,
    this.onUnlocked,
    this.unlockedHint,
  });

  final IconData icon;
  final String title;
  final bool unlocked;
  final int coinCost;
  final VoidCallback? onUnlocked;
  final String? unlockedHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = !unlocked;
    return Opacity(
      opacity: muted ? 0.45 : 1,
      child: EditorSheetTile(
        icon: icon,
        label: title,
        subtitle: unlocked
            ? (unlockedHint ?? l10n.comingSoonGate)
            : l10n.unlockWithCoins(coinCost),
        trailing: Icon(
          unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
          size: 20,
          color: EditorChrome.onDarkMuted,
        ),
        onTap: unlocked
            ? (onUnlocked ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.comingSoonGate)),
                    );
                  })
            : () => context.push('/marketplace'),
      ),
    );
  }
}
