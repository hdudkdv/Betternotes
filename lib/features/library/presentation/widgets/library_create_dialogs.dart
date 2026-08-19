import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/content_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_size.dart';
import '../../../entitlements/entitlement_model.dart';
import '../../../entitlements/rewarded_ad_mock.dart';
import '../../../editor/domain/ink_models.dart';

String _paperFormatLabel(AppLocalizations l10n, PaperFormat format) =>
    switch (format) {
      PaperFormat.a2 => 'A2',
      PaperFormat.a3 => 'A3',
      PaperFormat.a4 => 'A4',
      PaperFormat.a5 => 'A5',
      PaperFormat.a6 => 'A6',
      PaperFormat.letter => l10n.paperLetter,
      PaperFormat.legal => l10n.paperLegal,
      PaperFormat.tabloid => l10n.paperTabloid,
    };

Widget _sectionLabel(String text) {
  return Text(
    text,
    style: AppTheme.body(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: AppTheme.ink,
    ),
  );
}

Widget _colorPicker({
  required int selected,
  required ValueChanged<int> onSelect,
}) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final c in coverPalette)
        GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color(c),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected == c ? AppTheme.accent : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
        ),
    ],
  );
}

Widget _iconPicker({
  required String selected,
  required ValueChanged<String> onSelect,
}) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final key in folderIconKeys)
        GestureDetector(
          onTap: () => onSelect(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected == key ? AppTheme.accentSoft : AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected == key ? AppTheme.accent : AppTheme.outline,
                width: selected == key ? 2 : 1,
              ),
            ),
            child: Icon(
              folderIconFor(key),
              color: selected == key ? AppTheme.accent : AppTheme.inkMuted,
            ),
          ),
        ),
    ],
  );
}

class NotebookCreateResult {
  const NotebookCreateResult({
    required this.title,
    required this.color,
    required this.template,
    required this.canvasMode,
    required this.paperFormat,
    required this.orientation,
    this.favorite = false,
    this.schoolClass,
  });

  final String title;
  final int color;
  final PageTemplate template;
  final CanvasMode canvasMode;
  final PaperFormat paperFormat;
  final PageOrientation orientation;
  final bool favorite;
  final int? schoolClass;
}

Future<NotebookCreateResult?> promptCreateNotebook(
  BuildContext context, {
  required PageTemplate defaultTemplate,
  CanvasMode initialMode = CanvasMode.page,
}) {
  return showDialog<NotebookCreateResult>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      var title = initialMode == CanvasMode.infinite
          ? l10n.untitledInfinite
          : l10n.untitledNotebook;
      var color = coverPalette.first;
      var template = defaultTemplate;
      var favorite = false;
      var mode = initialMode;
      var paperFormat = PaperFormat.a4;
      var orientation = PageOrientation.portrait;
      int? schoolClass;
      final maxH = MediaQuery.sizeOf(context).height * 0.72;

      return Consumer(
        builder: (context, ref, _) => StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(
                mode == CanvasMode.infinite
                    ? l10n.newInfiniteDocument
                    : l10n.newNotebook,
              ),
              content: SizedBox(
                width: 460,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          autofocus: true,
                          decoration: InputDecoration(hintText: l10n.title),
                          onChanged: (v) => title = v.trim().isEmpty
                              ? (mode == CanvasMode.infinite
                                    ? l10n.untitledInfinite
                                    : l10n.untitledNotebook)
                              : v.trim(),
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel(l10n.documentType),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ModeCard(
                                selected: mode == CanvasMode.page,
                                icon: Icons.article_outlined,
                                title: l10n.pageMode,
                                subtitle: l10n.pageModeHint,
                                onTap: () =>
                                    setLocal(() => mode = CanvasMode.page),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ModeCard(
                                selected: mode == CanvasMode.infinite,
                                icon: Icons.all_out_outlined,
                                title: l10n.infiniteDocument,
                                subtitle: l10n.infiniteDocumentShortHint,
                                onTap: () =>
                                    setLocal(() => mode = CanvasMode.infinite),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (mode == CanvasMode.page) ...[
                          _sectionLabel(l10n.paperSize),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<PaperFormat>(
                            initialValue: paperFormat,
                            items: [
                              for (final format in PaperFormat.values)
                                DropdownMenuItem(
                                  value: format,
                                  child: Text(_paperFormatLabel(l10n, format)),
                                ),
                            ],
                            onChanged: (format) {
                              if (format != null) {
                                setLocal(() => paperFormat = format);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _sectionLabel(l10n.pageOrientation),
                          const SizedBox(height: 8),
                          SegmentedButton<PageOrientation>(
                            segments: [
                              ButtonSegment(
                                value: PageOrientation.portrait,
                                icon: const Icon(Icons.crop_portrait_rounded),
                                label: Text(l10n.portrait),
                              ),
                              ButtonSegment(
                                value: PageOrientation.landscape,
                                icon: const Icon(Icons.crop_landscape_rounded),
                                label: Text(l10n.landscape),
                              ),
                            ],
                            selected: {orientation},
                            onSelectionChanged: (selection) =>
                                setLocal(() => orientation = selection.first),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _sectionLabel(l10n.schoolClass),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          initialValue: schoolClass,
                          decoration: InputDecoration(
                            hintText: l10n.schoolClassHint,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(l10n.schoolClassNone),
                            ),
                            for (var grade = 5; grade <= 13; grade++)
                              DropdownMenuItem<int?>(
                                value: grade,
                                child: Text(l10n.schoolClassValue(grade)),
                              ),
                          ],
                          onChanged: (value) =>
                              setLocal(() => schoolClass = value),
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel(l10n.cover),
                        const SizedBox(height: 8),
                        _colorPicker(
                          selected: color,
                          onSelect: (c) async {
                            final premium = coverPalette.indexOf(c) >= 3;
                            if (premium &&
                                !ref
                                    .read(entitlementProvider)
                                    .hasAccess(FeatureKeys.premiumCover)) {
                              await runRewardedUnlock(
                                context: context,
                                ref: ref,
                                featureKey: FeatureKeys.premiumCover,
                              );
                              return;
                            }
                            setLocal(() => color = c);
                          },
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel(l10n.template),
                        const SizedBox(height: 8),
                        SegmentedButton<PageTemplate>(
                          segments: [
                            ButtonSegment(
                              value: PageTemplate.blank,
                              label: Text(l10n.blank),
                            ),
                            ButtonSegment(
                              value: PageTemplate.lined,
                              label: Text(l10n.lined),
                            ),
                            ButtonSegment(
                              value: PageTemplate.grid,
                              label: Text(l10n.grid),
                            ),
                          ],
                          selected: {template},
                          onSelectionChanged: (s) =>
                              setLocal(() => template = s.first),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.markFavorite,
                            style: AppTheme.body(fontWeight: FontWeight.w600),
                          ),
                          value: favorite,
                          onChanged: (v) => setLocal(() => favorite = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    NotebookCreateResult(
                      title: title,
                      color: color,
                      template: template,
                      canvasMode: mode,
                      paperFormat: paperFormat,
                      orientation: orientation,
                      favorite: favorite,
                      schoolClass: schoolClass,
                    ),
                  ),
                  child: Text(l10n.create),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class FolderCreateResult {
  const FolderCreateResult({
    required this.name,
    required this.color,
    required this.iconKey,
  });

  final String name;
  final int color;
  final String iconKey;
}

Future<FolderCreateResult?> promptCreateOrEditFolder(
  BuildContext context, {
  LibraryFolder? existing,
}) {
  return showDialog<FolderCreateResult>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      var name = existing?.name ?? '';
      var color = existing?.colorValue ?? coverPalette[1];
      var iconKey = existing?.iconKey ?? 'folder';
      final controller = TextEditingController(text: name);

      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(existing == null ? l10n.newFolder : l10n.editFolder),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(hintText: l10n.folderName),
                      onChanged: (v) => name = v,
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel(l10n.color),
                    const SizedBox(height: 8),
                    _colorPicker(
                      selected: color,
                      onSelect: (c) => setLocal(() => color = c),
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel(l10n.folderIcon),
                    const SizedBox(height: 8),
                    _iconPicker(
                      selected: iconKey,
                      onSelect: (k) => setLocal(() => iconKey = k),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final n = controller.text.trim();
                  if (n.isEmpty) return;
                  Navigator.pop(
                    context,
                    FolderCreateResult(name: n, color: color, iconKey: iconKey),
                  );
                },
                child: Text(existing == null ? l10n.create : l10n.save),
              ),
            ],
          );
        },
      );
    },
  );
}

class DeckCreateResult {
  const DeckCreateResult({required this.title, required this.color});

  final String title;
  final int color;
}

Future<DeckCreateResult?> promptCreateDeck(BuildContext context) {
  return showDialog<DeckCreateResult>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      var title = l10n.untitledDeck;
      var color = coverPalette[3];
      final controller = TextEditingController(text: title);

      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(l10n.newFlashcardDeck),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(hintText: l10n.title),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel(l10n.color),
                  const SizedBox(height: 8),
                  _colorPicker(
                    selected: color,
                    onSelect: (c) => setLocal(() => color = c),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final t = controller.text.trim();
                  if (t.isEmpty) return;
                  Navigator.pop(
                    context,
                    DeckCreateResult(title: t, color: color),
                  );
                },
                child: Text(l10n.create),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.accentSoft : AppTheme.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.accent : AppTheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? AppTheme.accent : AppTheme.inkMuted),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTheme.body(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showLibraryCreateSheet(
  BuildContext context, {
  required VoidCallback onFolder,
  required VoidCallback onNotebook,
  required VoidCallback onInfinite,
  required VoidCallback onFlashcards,
  VoidCallback? onScanPages,
  VoidCallback? onJoinNearby,
}) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.ink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              if (onJoinNearby != null)
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner_rounded),
                  title: Text(
                    l10n.nearbyJoinFromLibrary,
                    style: AppTheme.body(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(l10n.nearbyJoinFromLibraryHint),
                  onTap: () {
                    Navigator.pop(context);
                    onJoinNearby();
                  },
                ),
              ListTile(
                leading: Icon(Icons.folder_outlined, color: AppTheme.ink),
                title: Text(
                  l10n.newFolder,
                  style: AppTheme.body(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onFolder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(
                  l10n.newNotebook,
                  style: AppTheme.body(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onNotebook();
                },
              ),
              ListTile(
                leading: Icon(Icons.all_out_outlined, color: AppTheme.accent),
                title: Text(
                  l10n.newInfiniteDocument,
                  style: AppTheme.body(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onInfinite();
                },
              ),
              if (onScanPages != null)
                ListTile(
                  leading: const Icon(Icons.document_scanner_outlined),
                  title: Text(
                    l10n.scanPages,
                    style: AppTheme.body(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(l10n.scanPagesHint),
                  onTap: () {
                    Navigator.pop(context);
                    onScanPages();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.style_outlined),
                title: Text(
                  l10n.newFlashcardDeck,
                  style: AppTheme.body(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onFlashcards();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
