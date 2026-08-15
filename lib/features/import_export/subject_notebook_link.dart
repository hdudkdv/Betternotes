import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../l10n/app_localizations.dart';
import '../library/providers/library_providers.dart';
import '../planner/planner_model.dart';

/// Resolves a notebook linked to a subject (by subjectKey or folder title match).
Future<Notebook?> findNotebookForSubject({
  required NotebookRepository repo,
  required String subject,
  String? folderId,
}) async {
  final key = subjectKey(subject);
  if (key.isEmpty && (folderId == null || folderId.isEmpty)) return null;
  final notebooks = await repo.getNotebooks();
  for (final nb in notebooks) {
    if (folderId != null && folderId.isNotEmpty && nb.folderId == folderId) {
      return nb;
    }
  }
  for (final nb in notebooks) {
    final sk = nb.subjectKey?.trim().toLowerCase();
    if (sk != null && sk.isNotEmpty && sk == key) return nb;
  }
  for (final nb in notebooks) {
    if (nb.title.trim().toLowerCase() == key) return nb;
  }
  return null;
}

Future<void> openNotebookForSubject({
  required BuildContext context,
  required WidgetRef ref,
  required NotebookRepository repo,
  required String subject,
  String? folderId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final existing = await findNotebookForSubject(
    repo: repo,
    subject: subject,
    folderId: folderId,
  );
  if (!context.mounted) return;
  if (existing != null) {
    context.push('/notebook/${existing.id}');
    return;
  }
  final create = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        subject.trim().isEmpty ? l10n.newNotebook : subject.trim(),
      ),
      content: Text(l10n.createNotebookForSubjectHint),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.create),
        ),
      ],
    ),
  );
  if (create != true || !context.mounted) return;
  final nb = await repo.createNotebook(
    title: subject.trim().isEmpty ? l10n.newNotebook : subject.trim(),
    coverColor: 0xFF1D4E89,
    folderId: folderId,
  );
  await repo.updateNotebook(
    nb.copyWith(
      subjectKey: subjectKey(subject),
      updatedAt: DateTime.now(),
    ),
  );
  refreshLibraryLists(ref);
  if (!context.mounted) return;
  context.push('/notebook/${nb.id}');
}
