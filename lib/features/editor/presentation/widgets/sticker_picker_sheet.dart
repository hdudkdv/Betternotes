import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/sticker_catalog.dart';

Future<StickerDef?> showStickerPicker(BuildContext context) {
  return showModalBottomSheet<StickerDef>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _StickerPickerSheet(),
  );
}

class _StickerPickerSheet extends StatelessWidget {
  const _StickerPickerSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.stickers,
              style: AppTheme.headline(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.stickersHint,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final pack in StickerCatalog.packs) ...[
                    Text(
                      switch (pack) {
                        'marks' => l10n.stickerPackMarks,
                        'mood' => l10n.stickerPackMood,
                        _ => l10n.stickerPackSchool,
                      },
                      style: AppTheme.body(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final sticker in StickerCatalog.forPack(pack))
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(context, sticker),
                            child: Ink(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.palette.surfaceRaised,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.outline),
                              ),
                              child: Center(
                                child: Text(
                                  sticker.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
