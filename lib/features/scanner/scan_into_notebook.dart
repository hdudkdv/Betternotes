import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../editor/domain/ink_models.dart';
import '../editor/providers/open_tabs_provider.dart';
import '../library/providers/library_providers.dart';
import 'document_scanner_service.dart';

/// Scans sheets and drops them into [notebookId], or a new notebook.
Future<void> scanIntoNotebook(
  BuildContext context,
  WidgetRef ref, {
  String? notebookId,
  String? suggestedTitle,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final paths = await const DocumentScannerService().scanPages();
  if (paths.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.scanFailed)));
    }
    return;
  }

  final repo = ref.read(notebookRepositoryProvider);
  var id = notebookId;
  if (id == null) {
    final title =
        suggestedTitle ??
        l10n.scannedNotebookTitle(DateFormat('dd.MM.yyyy').format(DateTime.now()));
    final notebook = await repo.createNotebook(
      title: title,
      coverColor: 0xFF1D4E89,
      template: PageTemplate.blank,
      folderId: ref.read(currentFolderIdProvider),
    );
    id = notebook.id;
  }

  final created = await ref
      .read(pdfServiceProvider)
      .importScannedImages(notebookId: id, imagePaths: paths);
  refreshLibraryLists(ref);
  if (!context.mounted) return;
  ref.read(openNotebookTabsProvider.notifier).open(id);
  context.push('/notebook/$id');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.scanAddedPages(created.length))),
  );
}
