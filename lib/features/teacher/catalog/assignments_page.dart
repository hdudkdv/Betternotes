import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../planner/education_settings.dart';
import '../../scanner/document_scanner_service.dart';
import '../../timetable/timetable_model.dart';
import '../../library/providers/library_providers.dart';
import 'assignment_editor_page.dart';
import 'assignment_live_panel.dart';
import 'catalog_models.dart';
import 'catalog_store.dart';

class AssignmentsPage extends ConsumerStatefulWidget {
  const AssignmentsPage({super.key});

  @override
  ConsumerState<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends ConsumerState<AssignmentsPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.watch(catalogProvider.notifier);
    final items = notifier.search(query: _query.text);
    final unlocked = notifier.hasUnlockedPublicPool;
    return Stack(
      children: [
        items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.teacherNoAssignments,
                        textAlign: TextAlign.center,
                        style: AppTheme.body(color: AppTheme.inkMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.teacherAssignmentsHint,
                        textAlign: TextAlign.center,
                        style: AppTheme.body(
                          color: AppTheme.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: items.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.teacherAssignmentsHint,
                          style: AppTheme.body(color: AppTheme.inkMuted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          unlocked
                              ? l10n.assignmentPoolUnlocked
                              : l10n.assignmentPoolLocked,
                          style: AppTheme.body(
                            color: AppTheme.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _query,
                          decoration: InputDecoration(
                            labelText: l10n.teacherMaterialSearch,
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    );
                  }
                  return _AssignmentTile(item: items[index - 1]);
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateSheet(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.teacherNewAssignment),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note_outlined),
              title: Text(l10n.teacherNewAssignment),
              onTap: () => Navigator.pop(context, 'new'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.teacherImportPdf),
              subtitle: Text(l10n.teacherImportPdfHint),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(l10n.teacherImportScan),
              subtitle: Text(l10n.teacherImportScanHint),
              onTap: () => Navigator.pop(context, 'scan'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case 'new':
        await _createBlank(context, ref);
      case 'pdf':
        await _importPdf(context, ref);
      case 'scan':
        await _importScan(context, ref);
    }
  }

  Future<void> _createBlank(BuildContext context, WidgetRef ref) async {
    final defaults = catalogDefaults(ref);
    final item = CatalogItem.create(
      title: '',
      subject: defaults.subject,
      schoolClass: defaults.schoolClass,
      germanState: defaults.germanState,
    );
    await ref.read(catalogProvider.notifier).upsert(item);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AssignmentEditorPage(itemId: item.id),
      ),
    );
  }

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null || !context.mounted) return;
    final title = result.files.first.name.replaceAll(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );
    await _runImport(context, ref, () {
      final defaults = catalogDefaults(ref);
      return ref
          .read(catalogImportServiceProvider)
          .fromPdfBytes(
            bytes: bytes,
            title: title,
            subject: defaults.subject,
            schoolClass: defaults.schoolClass,
            germanState: defaults.germanState,
          );
    });
  }

  Future<void> _importScan(BuildContext context, WidgetRef ref) async {
    final paths = await const DocumentScannerService().scanPages();
    if (paths.isEmpty || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await _runImport(context, ref, () {
      final defaults = catalogDefaults(ref);
      return ref
          .read(catalogImportServiceProvider)
          .fromImagePaths(
            paths: paths,
            title: l10n.teacherImportedScanTitle,
            subject: defaults.subject,
            schoolClass: defaults.schoolClass,
            germanState: defaults.germanState,
          );
    });
  }

  Future<void> _runImport(
    BuildContext context,
    WidgetRef ref,
    Future<CatalogItem> Function() import,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    var opened = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.teacherImporting)),
          ],
        ),
      ),
    );
    try {
      final item = await import();
      await ref.read(catalogProvider.notifier).upsert(item);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      opened = false;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => AssignmentEditorPage(itemId: item.id),
        ),
      );
    } catch (_) {
      if (context.mounted && opened) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.teacherImportFailed)));
      }
    }
  }
}

class _AssignmentTile extends ConsumerWidget {
  const _AssignmentTile({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = GermanState.values.where((s) => s.name == item.germanState);
    final stateLabel = state.isEmpty ? item.germanState : state.first.label(l10n);
    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          item.title.trim().isEmpty ? l10n.teacherUntitledAssignment : item.title,
          style: AppTheme.headline(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (item.needsReview)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(l10n.teacherNeedsReview),
                ),
              if (item.subject.trim().isNotEmpty) Text(item.subject),
              if (item.schoolClass.trim().isNotEmpty) Text(item.schoolClass),
              if (stateLabel.isNotEmpty) Text(stateLabel),
              Text(l10n.teacherTaskCount(item.tasks.length)),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'print':
                await printCatalogItem(item);
              case 'delete':
                await ref.read(catalogProvider.notifier).delete(item.id);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'print', child: Text(l10n.assignmentPrint)),
            PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => AssignmentEditorPage(itemId: item.id),
            ),
          );
        },
      ),
    );
  }
}

({String subject, String schoolClass, String germanState}) catalogDefaults(
  WidgetRef ref,
) {
  final settings = ref.read(settingsProvider);
  final table = ref.read(timetableProvider);
  final now = table.lessonAt(DateTime.now());
  final catalog = ref.read(catalogProvider);
  final live = now?.lesson.subject.trim() ?? '';
  final fallback = table.distinctSubjectNames();
  return (
    subject: live.isNotEmpty
        ? live
        : (fallback.isNotEmpty ? fallback.first : ''),
    schoolClass: catalog.isEmpty ? '' : catalog.first.schoolClass,
    germanState: settings.germanState.name,
  );
}
