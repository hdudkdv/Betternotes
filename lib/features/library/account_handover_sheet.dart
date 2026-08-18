import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'account_library_service.dart';

Future<LibraryHandoverAction?> showAccountHandoverSheet(
  BuildContext context, {
  required int notebookCount,
  required bool canSaveToCloud,
  bool canLock = true,
}) {
  return showModalBottomSheet<LibraryHandoverAction>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              const SizedBox(height: 16),
              Text(
                l10n.accountHandoverTitle,
                style: AppTheme.headline(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accountHandoverBody(notebookCount),
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.accountHandoverDelete),
                subtitle: Text(l10n.accountHandoverDeleteHint),
                onTap: () =>
                    Navigator.pop(ctx, LibraryHandoverAction.deleteLocal),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: canSaveToCloud,
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(l10n.accountHandoverCloud),
                subtitle: Text(
                  canSaveToCloud
                      ? l10n.accountHandoverCloudHint
                      : l10n.accountHandoverCloudUnavailable,
                ),
                onTap: canSaveToCloud
                    ? () =>
                          Navigator.pop(ctx, LibraryHandoverAction.saveToCloud)
                    : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: canLock,
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.accountHandoverLock),
                subtitle: Text(
                  canLock
                      ? l10n.accountHandoverLockHint
                      : l10n.accountHandoverLockUnavailable,
                ),
                onTap: canLock
                    ? () => Navigator.pop(ctx, LibraryHandoverAction.lockLocal)
                    : null,
              ),
            ],
          ),
        ),
      );
    },
  );
}
