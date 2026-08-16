import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models/notebook.dart';
import '../../l10n/app_localizations.dart';
import '../library/providers/library_providers.dart';
import '../sync/sync_engine.dart';
import 'import_export_providers.dart';
import 'import_models.dart';

class ImportNotebookPickerScreen extends ConsumerStatefulWidget {
  const ImportNotebookPickerScreen({super.key, this.initialFiles});

  final List<InboxFile>? initialFiles;

  @override
  ConsumerState<ImportNotebookPickerScreen> createState() =>
      _ImportNotebookPickerScreenState();
}

class _ImportNotebookPickerScreenState
    extends ConsumerState<ImportNotebookPickerScreen> {
  List<InboxFile> _files = const [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final fromRoute = widget.initialFiles;
    final fromIntake = ref.read(shareIntakeProvider).takePending();
    _files = fromRoute ?? fromIntake ?? const [];
  }

  Future<void> _pickMoreFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    final inbox = ref.read(inboxServiceProvider);
    final staged = <InboxFile>[];
    for (final f in result.files) {
      final bytes = f.bytes;
      if (bytes != null) {
        staged.add(
          await inbox.stageBytes(
            bytes: bytes,
            name: f.name,
          ),
        );
        continue;
      }
      final path = f.path;
      if (path == null) continue;
      staged.add(
        await inbox.stagePath(
          sourcePath: path,
          name: f.name,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _files = [..._files, ...staged]);
  }

  Future<void> _importInto(Notebook notebook) async {
    if (_files.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pipeline = ref.read(importPipelineProvider);
      ImportResult? last;
      for (final file in _files) {
        last = await pipeline.importFile(
          notebookId: notebook.id,
          file: file,
        );
      }
      if (kIsWeb) {
        await ref.read(syncEngineProvider).flush(force: true);
      }
      if (!mounted) return;
      final pageId = last?.firstPageId;
      final uri = pageId == null
          ? '/notebook/${notebook.id}'
          : '/notebook/${notebook.id}?pageId=$pageId';
      context.go(uri);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _createAndImport() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: _files.isEmpty
          ? l10n.importNewNotebookTitle
          : _files.first.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importCreateNotebook),
        content: TextField(
          controller: controller,
          autofocus: true,
                      decoration: InputDecoration(labelText: l10n.title),
        ),
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
    if (ok != true || !mounted) return;
    final title = controller.text.trim().isEmpty
        ? l10n.importNewNotebookTitle
        : controller.text.trim();
    final notebook = await ref
        .read(notebookRepositoryProvider)
        .createNotebook(title: title, coverColor: 0xFF1D4E89);
    ref.invalidate(notebooksProvider);
    await _importInto(notebook);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notebooksAsync = ref.watch(allNotebooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importIntoNotebook),
        actions: [
          IconButton(
            tooltip: l10n.importAddFiles,
            onPressed: _busy ? null : _pickMoreFiles,
            icon: const Icon(Icons.attach_file),
          ),
        ],
      ),
      body: _busy
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.importingFiles, style: AppTheme.body()),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  l10n.importPickNotebookHint,
                  style: AppTheme.body(color: AppTheme.inkMuted),
                ),
                const SizedBox(height: 12),
                if (_files.isEmpty)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.folder_open_outlined),
                      title: Text(l10n.importNoFilesYet),
                      subtitle: Text(l10n.importAddFilesHint),
                      onTap: _pickMoreFiles,
                    ),
                  )
                else
                  ..._files.map(
                    (f) => ListTile(
                      leading: Icon(_iconFor(f)),
                      title: Text(f.name),
                      subtitle: Text(f.extension.toUpperCase()),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: AppTheme.body(color: const Color(0xFFB42318)),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _files.isEmpty ? null : _createAndImport,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: Text(l10n.importCreateNotebook),
                ),
                const SizedBox(height: 20),
                Text(l10n.importExistingNotebooks, style: AppTheme.headline(fontSize: 18)),
                const SizedBox(height: 8),
                notebooksAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('$e'),
                  data: (notebooks) {
                    if (notebooks.isEmpty) {
                      return Text(
                        l10n.noNotebooksYet,
                        style: AppTheme.body(color: AppTheme.inkMuted),
                      );
                    }
                    return Column(
                      children: [
                        for (final nb in notebooks)
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(nb.coverColor),
                            ),
                            title: Text(nb.title),
                            subtitle: Text(l10n.pageCount(nb.pageCount)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _files.isEmpty
                                ? null
                                : () => _importInto(nb),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }

  IconData _iconFor(InboxFile file) {
    return switch (classifyImport(name: file.name, mimeType: file.mimeType)) {
      ImportKind.pdf => Icons.picture_as_pdf_outlined,
      ImportKind.image => Icons.image_outlined,
      ImportKind.office => Icons.description_outlined,
      ImportKind.goodnotes => Icons.auto_stories_outlined,
      ImportKind.archive => Icons.folder_zip_outlined,
      ImportKind.text => Icons.notes_outlined,
      ImportKind.attachment => Icons.attach_file,
    };
  }
}
