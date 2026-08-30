import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

Future<void> showComingSoonSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 20),
              Text(
                l10n.commerceComingSoonTitle,
                style: AppTheme.headline(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.commerceComingSoonBody,
                style: AppTheme.body(color: AppTheme.inkMuted, height: 1.45),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.close),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.marketplaceSoonBadge,
              style: AppTheme.body(
                fontWeight: FontWeight.w800,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.commerceComingSoonTitle,
              style: AppTheme.headline(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.commerceComingSoonBody,
              style: AppTheme.body(
                color: AppTheme.inkMuted,
                height: 1.45,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
