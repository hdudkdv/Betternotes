import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/content_models.dart';
import '../../../../data/repositories/notebook_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../editor_chrome.dart';
import 'editor_sheet.dart';

Future<PageLocalSnapshot?> showPageSnapshotsSheet(
  BuildContext context, {
  required NotebookRepository repository,
  required String pageId,
}) {
  return showEditorSheet<PageLocalSnapshot>(
    context,
    builder: (context) => _PageSnapshotsSheet(
      repository: repository,
      pageId: pageId,
    ),
  );
}

class _PageSnapshotsSheet extends StatefulWidget {
  const _PageSnapshotsSheet({
    required this.repository,
    required this.pageId,
  });

  final NotebookRepository repository;
  final String pageId;

  @override
  State<_PageSnapshotsSheet> createState() => _PageSnapshotsSheetState();
}

class _PageSnapshotsSheetState extends State<_PageSnapshotsSheet> {
  late Future<List<PageLocalSnapshot>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getPageSnapshots(widget.pageId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.repository.getPageSnapshots(widget.pageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = DateFormat.yMMMd().add_Hm();

    return EditorSheet(
      title: l10n.restoreSnapshot,
      children: [
        FutureBuilder<List<PageLocalSnapshot>>(
          future: _future,
          builder: (context, snapshot) {
            final items = snapshot.data;
            if (items == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: Text(
                  l10n.noSnapshotsYet,
                  style: AppTheme.body(color: EditorChrome.onDarkMuted),
                ),
              );
            }
            return Column(
              children: [
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.history_rounded,
                      color: EditorChrome.onDark,
                    ),
                    title: Text(
                      l10n.snapshotLabel(format.format(item.createdAt)),
                      style: AppTheme.body(
                        color: EditorChrome.onDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item.label,
                      style: AppTheme.body(
                        color: EditorChrome.onDarkMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: l10n.deleteSnapshot,
                      onPressed: () async {
                        await widget.repository.deletePageSnapshot(
                          widget.pageId,
                          item.id,
                        );
                        await _reload();
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: EditorChrome.onDarkMuted,
                      ),
                    ),
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.restoreSnapshot),
                          content: Text(l10n.confirmRestoreSnapshot),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(MaterialLocalizations.of(context)
                                  .cancelButtonLabel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.restoreSnapshot),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        Navigator.pop(context, item);
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
