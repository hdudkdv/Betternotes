import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../app/theme.dart';
import '../../data/models/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../import_export/subject_notebook_link.dart';
import '../library/providers/library_providers.dart';
import 'timetable_model.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  String _dayLabel(AppLocalizations l10n, int day) {
    switch (day) {
      case 0:
        return l10n.mondayShort;
      case 1:
        return l10n.tuesdayShort;
      case 2:
        return l10n.wednesdayShort;
      case 3:
        return l10n.thursdayShort;
      case 4:
        return l10n.fridayShort;
      default:
        return '';
    }
  }

  Future<void> _editSlot(
    BuildContext context,
    WidgetRef ref,
    int day,
    int period,
  ) async {
    final table = ref.read(timetableProvider);
    final folders = await ref.read(allFoldersProvider.future);
    if (!context.mounted) return;
    final existing =
        table.slotAt(day, period) ?? TimetableSlot(day: day, period: period);
    final result = await showDialog<_SlotEditResult?>(
      context: context,
      builder: (context) => _SlotEditorDialog(
        dayLabel: _dayLabel(AppLocalizations.of(context)!, day),
        period: table.periods[period],
        initial: existing,
        folders: folders,
      ),
    );
    if (result == null) return;
    if (result.slot.isEmpty) {
      await ref.read(timetableProvider.notifier).clearSlot(day, period);
      return;
    }
    final slot = await _attachCreatedFolders(
      ref,
      result.slot,
      createFirst: result.createFirstFolder,
      createSecond: result.createSecondFolder,
    );
    await ref.read(timetableProvider.notifier).setSlot(slot);
  }

  Future<TimetableSlot> _attachCreatedFolders(
    WidgetRef ref,
    TimetableSlot slot, {
    required bool createFirst,
    required bool createSecond,
  }) async {
    var first = slot.first;
    var second = slot.second;
    if (createFirst) {
      first = await _createOrReuseSubjectFolder(ref, first);
    }
    if (slot.split && createSecond) {
      second = await _createOrReuseSubjectFolder(ref, second);
    }
    return TimetableSlot(
      day: slot.day,
      period: slot.period,
      split: slot.split,
      first: first,
      second: second,
    );
  }

  Future<TimetableLesson> _createOrReuseSubjectFolder(
    WidgetRef ref,
    TimetableLesson lesson,
  ) async {
    final name = lesson.subject.trim();
    if (name.isEmpty || lesson.folderId != null) return lesson;
    final folders = await ref.read(allFoldersProvider.future);
    final existing = folderMatchingSubject(folders, name);
    if (existing != null) {
      return lessonFromFolder(existing).copyWith(room: lesson.room);
    }
    final created = await ref
        .read(notebookRepositoryProvider)
        .createFolder(name: name, colorValue: colorForSubject(name));
    refreshLibraryLists(ref);
    return lessonFromFolder(created).copyWith(room: lesson.room);
  }

  Future<void> _editPeriod(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final period = ref.read(timetableProvider).periods[index];
    final result = await showDialog<TimetablePeriod>(
      context: context,
      builder: (context) =>
          _PeriodTimeDialog(title: l10n.editPeriod, initial: period),
    );
    if (result == null) return;
    await ref.read(timetableProvider.notifier).setPeriod(index, result);
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final table = ref.read(timetableProvider);
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                table.title,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey600,
                  width: 0.6,
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _pdfCell('', bold: true),
                      for (var d = 0; d < Timetable.dayCount; d++)
                        _pdfCell(_dayLabel(l10n, d), bold: true),
                    ],
                  ),
                  for (var p = 0; p < table.periods.length; p++)
                    pw.TableRow(
                      children: [
                        _pdfCell(
                          '${table.periods[p].label}\n${table.periods[p].timeRange}',
                          bold: true,
                          small: true,
                        ),
                        for (var d = 0; d < Timetable.dayCount; d++)
                          _pdfCell(_slotPdfText(table.slotAt(d, p))),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${table.title.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    bool small = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: small ? 9 : 11,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _slotPdfText(TimetableSlot? slot) {
    if (slot == null || slot.isEmpty) return '';
    if (!slot.split) {
      final room = slot.first.room;
      return room.isEmpty ? slot.first.subject : '${slot.first.subject}\n$room';
    }
    final a = slot.first.subject;
    final b = slot.second.subject;
    return '$a\n/\n$b';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final table = ref.watch(timetableProvider);
    final now = ref.watch(nowLessonProvider);

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(l10n.timetable, style: AppTheme.headline()),
        actions: [
          IconButton(
            tooltip: l10n.shareExport,
            onPressed: () => _share(context, ref),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'add':
                  await ref.read(timetableProvider.notifier).addPeriod();
                case 'remove':
                  await ref.read(timetableProvider.notifier).removeLastPeriod();
                case 'rename':
                  final c = TextEditingController(text: table.title);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.rename),
                      content: TextField(controller: c, autofocus: true),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && c.text.trim().isNotEmpty) {
                    await ref
                        .read(timetableProvider.notifier)
                        .setTitle(c.text.trim());
                  }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
              PopupMenuItem(value: 'add', child: Text(l10n.addPeriod)),
              PopupMenuItem(value: 'remove', child: Text(l10n.removePeriod)),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (now != null)
            _NowBanner(now: now, dayLabel: _dayLabel(l10n, now.day)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              l10n.timetableHint,
              style: AppTheme.body(
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppTheme.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: SingleChildScrollView(
                child: _TimetableGrid(
                  table: table,
                  dayLabel: (d) => _dayLabel(l10n, d),
                  onTapSlot: (day, period) =>
                      _editSlot(context, ref, day, period),
                  onTapPeriod: (p) => _editPeriod(context, ref, p),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowBanner extends ConsumerWidget {
  const _NowBanner({required this.now, required this.dayLabel});

  final NowLesson now;
  final String dayLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color(displayLessonColor(now.lesson)).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color(displayLessonColor(now.lesson)),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(displayLessonColor(now.lesson)),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.nowLesson(
                now.lesson.subject,
                '$dayLabel · ${now.timeRange}',
              ),
              style: AppTheme.body(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.ink,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.openLinkedNotebook,
            onPressed: () => openNotebookForSubject(
              context: context,
              ref: ref,
              repo: ref.read(notebookRepositoryProvider),
              subject: now.lesson.subject,
              folderId: now.lesson.folderId,
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
    );
  }
}

// ─── Time wheel pickers ─────────────────────────────────────────────────────

class TimeWheelPicker extends StatefulWidget {
  const TimeWheelPicker({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  State<TimeWheelPicker> createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<TimeWheelPicker> {
  late FixedExtentScrollController _hour;
  late FixedExtentScrollController _minute;

  @override
  void initState() {
    super.initState();
    final h = (widget.minutes ~/ 60).clamp(0, 23);
    final m = (widget.minutes % 60).clamp(0, 59);
    _hour = FixedExtentScrollController(initialItem: h);
    _minute = FixedExtentScrollController(initialItem: m);
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  void _emit() {
    final h = _hour.selectedItem.clamp(0, 23);
    final m = _minute.selectedItem.clamp(0, 59);
    widget.onChanged(h * 60 + m);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            child: CupertinoPicker(
              scrollController: _hour,
              itemExtent: 36,
              magnification: 1.1,
              useMagnifier: true,
              onSelectedItemChanged: (_) => _emit(),
              children: [
                for (var h = 0; h < 24; h++)
                  Center(
                    child: Text(
                      h.toString().padLeft(2, '0'),
                      style: AppTheme.body(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            ':',
            style: AppTheme.body(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: _minute,
              itemExtent: 36,
              magnification: 1.1,
              useMagnifier: true,
              onSelectedItemChanged: (_) => _emit(),
              children: [
                for (var m = 0; m < 60; m++)
                  Center(
                    child: Text(
                      m.toString().padLeft(2, '0'),
                      style: AppTheme.body(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTimeDialog extends StatefulWidget {
  const _PeriodTimeDialog({required this.title, required this.initial});

  final String title;
  final TimetablePeriod initial;

  @override
  State<_PeriodTimeDialog> createState() => _PeriodTimeDialogState();
}

class _PeriodTimeDialogState extends State<_PeriodTimeDialog> {
  late String _label;
  late int _start;
  late int _end;
  late TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _label = widget.initial.label;
    _start = widget.initial.startMinutes;
    _end = widget.initial.endMinutes;
    _labelCtrl = TextEditingController(text: _label);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = (_end - _start).clamp(0, 24 * 60);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _labelCtrl,
                decoration: InputDecoration(labelText: l10n.periodLabel),
                onChanged: (v) => _label = v,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.periodStart,
                style: AppTheme.body(fontWeight: FontWeight.w700),
              ),
              TimeWheelPicker(
                minutes: _start,
                onChanged: (v) => setState(() {
                  _start = v;
                  if (_end <= _start) _end = _start + 90;
                }),
              ),
              Text(
                l10n.periodEnd,
                style: AppTheme.body(fontWeight: FontWeight.w700),
              ),
              TimeWheelPicker(
                minutes: _end,
                onChanged: (v) => setState(() => _end = v),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.blockDuration(duration),
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                  fontSize: 15,
                ),
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
            Navigator.pop(
              context,
              TimetablePeriod(
                label: _label.trim().isEmpty
                    ? widget.initial.label
                    : _label.trim(),
                startMinutes: _start,
                endMinutes: _end <= _start ? _start + 90 : _end,
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

// ─── Slot editor (block / split + folder link) ──────────────────────────────

class _SlotEditResult {
  const _SlotEditResult({
    required this.slot,
    this.createFirstFolder = false,
    this.createSecondFolder = false,
  });

  final TimetableSlot slot;
  final bool createFirstFolder;
  final bool createSecondFolder;
}

class _SlotEditorDialog extends StatefulWidget {
  const _SlotEditorDialog({
    required this.dayLabel,
    required this.period,
    required this.initial,
    required this.folders,
  });

  final String dayLabel;
  final TimetablePeriod period;
  final TimetableSlot initial;
  final List<LibraryFolder> folders;

  @override
  State<_SlotEditorDialog> createState() => _SlotEditorDialogState();
}

class _SlotEditorDialogState extends State<_SlotEditorDialog> {
  late bool _split;
  late TimetableLesson _first;
  late TimetableLesson _second;
  late TextEditingController _room1;
  late TextEditingController _room2;
  late TextEditingController _subject1;
  late TextEditingController _subject2;
  late bool _createFolder1;
  late bool _createFolder2;

  @override
  void initState() {
    super.initState();
    _split = widget.initial.split;
    _first = widget.initial.first;
    _second = widget.initial.second;
    _room1 = TextEditingController(text: _first.room);
    _room2 = TextEditingController(text: _second.room);
    _subject1 = TextEditingController(text: _first.subject);
    _subject2 = TextEditingController(text: _second.subject);
    _createFolder1 = _first.folderId == null;
    _createFolder2 = _second.folderId == null;
  }

  @override
  void dispose() {
    _room1.dispose();
    _room2.dispose();
    _subject1.dispose();
    _subject2.dispose();
    super.dispose();
  }

  void _applyFolder(bool firstHalf, LibraryFolder? folder) {
    setState(() {
      if (folder == null) {
        if (firstHalf) {
          _first = _first.copyWith(clearFolder: true);
          _createFolder1 = true;
        } else {
          _second = _second.copyWith(clearFolder: true);
          _createFolder2 = true;
        }
        return;
      }
      final lesson = lessonFromFolder(
        folder,
      ).copyWith(room: firstHalf ? _room1.text : _room2.text);
      if (firstHalf) {
        _first = lesson;
        _subject1.text = folder.name;
        _createFolder1 = false;
      } else {
        _second = lesson;
        _subject2.text = folder.name;
        _createFolder2 = false;
      }
    });
  }

  TimetableSlot _buildResult() {
    var first = _first.copyWith(
      subject: _subject1.text.trim(),
      room: _room1.text.trim(),
      colorValue: _first.folderId == null
          ? colorForSubject(_subject1.text)
          : _first.colorValue,
    );
    var second = _second.copyWith(
      subject: _subject2.text.trim(),
      room: _room2.text.trim(),
      colorValue: _second.folderId == null
          ? colorForSubject(_subject2.text)
          : _second.colorValue,
    );
    if (!_split) {
      second = const TimetableLesson();
    }
    return TimetableSlot(
      day: widget.initial.day,
      period: widget.initial.period,
      split: _split,
      first: first,
      second: second,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mid = formatHm(widget.period.splitAtMinutes);

    return AlertDialog(
      title: Text('${widget.dayLabel} · ${widget.period.timeRange}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.blockMode,
                style: AppTheme.body(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.fullBlock),
                    icon: const Icon(Icons.crop_portrait, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.splitBlock),
                    icon: const Icon(Icons.vertical_split, size: 16),
                  ),
                ],
                selected: {_split},
                onSelectionChanged: (s) => setState(() => _split = s.first),
              ),
              const SizedBox(height: 6),
              Text(
                _split
                    ? l10n.splitBlockHint(
                        '${widget.period.start}–$mid',
                        '$mid–${widget.period.end}',
                      )
                    : l10n.fullBlockHint(widget.period.durationMinutes),
                style: AppTheme.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.inkMuted,
                ),
              ),
              const SizedBox(height: 16),
              _lessonFields(
                l10n: l10n,
                title: _split ? l10n.firstHalf : l10n.subject,
                subjectCtrl: _subject1,
                roomCtrl: _room1,
                lesson: _first,
                createFolder: _createFolder1,
                onCreateFolder: (v) => setState(() => _createFolder1 = v),
                onFolder: (f) => _applyFolder(true, f),
                onSubject: (v) => setState(() {
                  _first = _first.copyWith(subject: v, clearFolder: true);
                  if (_first.folderId == null) _createFolder1 = true;
                }),
              ),
              if (_split) ...[
                const SizedBox(height: 16),
                Divider(color: AppTheme.ink.withValues(alpha: 0.15)),
                const SizedBox(height: 8),
                _lessonFields(
                  l10n: l10n,
                  title: l10n.secondHalf,
                  subjectCtrl: _subject2,
                  roomCtrl: _room2,
                  lesson: _second,
                  createFolder: _createFolder2,
                  onCreateFolder: (v) => setState(() => _createFolder2 = v),
                  onFolder: (f) => _applyFolder(false, f),
                  onSubject: (v) => setState(() {
                    _second = _second.copyWith(subject: v, clearFolder: true);
                    if (_second.folderId == null) _createFolder2 = true;
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (!widget.initial.isEmpty)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _SlotEditResult(
                slot: TimetableSlot(
                  day: widget.initial.day,
                  period: widget.initial.period,
                ),
              ),
            ),
            child: Text(l10n.clear),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final slot = _buildResult();
            Navigator.pop(
              context,
              _SlotEditResult(
                slot: slot,
                createFirstFolder:
                    _createFolder1 && slot.first.folderId == null,
                createSecondFolder:
                    _split && _createFolder2 && slot.second.folderId == null,
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Widget _lessonFields({
    required AppLocalizations l10n,
    required String title,
    required TextEditingController subjectCtrl,
    required TextEditingController roomCtrl,
    required TimetableLesson lesson,
    required bool createFolder,
    required ValueChanged<bool> onCreateFolder,
    required ValueChanged<LibraryFolder?> onFolder,
    required ValueChanged<String> onSubject,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Color(displayLessonColor(lesson)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.body(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.folders.isNotEmpty) ...[
          Text(
            l10n.linkFolder,
            style: AppTheme.body(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            key: ValueKey(lesson.folderId ?? 'none'),
            initialValue: lesson.folderId,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.noFolderLink),
              ),
              for (final f in widget.folders)
                DropdownMenuItem<String?>(
                  value: f.id,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Color(f.colorValue),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(child: Text(f.name)),
                    ],
                  ),
                ),
            ],
            onChanged: (id) {
              if (id == null) {
                onFolder(null);
                return;
              }
              final folder = widget.folders.firstWhere((f) => f.id == id);
              onFolder(folder);
            },
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: subjectCtrl,
          decoration: InputDecoration(
            labelText: l10n.subject,
            hintText: l10n.subjectHint,
          ),
          onChanged: onSubject,
        ),
        if (lesson.folderId == null) ...[
          const SizedBox(height: 4),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: createFolder,
            onChanged: (v) => onCreateFolder(v ?? false),
            title: Text(
              l10n.createSubjectFolder,
              style: AppTheme.body(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Text(
              l10n.createSubjectFolderHint,
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.inkMuted,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: roomCtrl,
          decoration: InputDecoration(
            labelText: l10n.room,
            hintText: l10n.roomHint,
          ),
        ),
      ],
    );
  }
}

// ─── Grid ───────────────────────────────────────────────────────────────────

class _TimetableGrid extends StatelessWidget {
  const _TimetableGrid({
    required this.table,
    required this.dayLabel,
    required this.onTapSlot,
    required this.onTapPeriod,
  });

  final Timetable table;
  final String Function(int day) dayLabel;
  final void Function(int day, int period) onTapSlot;
  final ValueChanged<int> onTapPeriod;

  static const _colW = 124.0;
  static const _timeW = 96.0;
  static const _rowH = 102.0;

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultColumnWidth: const FixedColumnWidth(_colW),
      columnWidths: const {0: FixedColumnWidth(_timeW)},
      border: TableBorder.all(
        color: AppTheme.ink.withValues(alpha: 0.18),
        width: 1,
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppTheme.paperDeep),
          children: [
            _headerCell(''),
            for (var d = 0; d < Timetable.dayCount; d++)
              _headerCell(dayLabel(d)),
          ],
        ),
        for (var p = 0; p < table.periods.length; p++)
          TableRow(
            children: [
              InkWell(
                onTap: () => onTapPeriod(p),
                child: SizedBox(
                  height: _rowH,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          table.periods[p].label,
                          style: AppTheme.body(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            table.periods[p].timeRange,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: AppTheme.body(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.inkMuted,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${table.periods[p].durationMinutes}′',
                          style: AppTheme.body(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              for (var d = 0; d < Timetable.dayCount; d++)
                _slotCell(table.slotAt(d, p), () => onTapSlot(d, p)),
            ],
          ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return SizedBox(
      height: 44,
      child: Center(
        child: Text(
          text,
          style: AppTheme.body(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppTheme.ink,
          ),
        ),
      ),
    );
  }

  Widget _slotCell(TimetableSlot? slot, VoidCallback onTap) {
    final s = slot;
    final empty = s == null || s.isEmpty;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: _rowH,
        child: empty
            ? Center(
                child: Icon(
                  Icons.add,
                  size: 18,
                  color: AppTheme.ink.withValues(alpha: 0.35),
                ),
              )
            : s.split
            ? Column(
                children: [
                  Expanded(child: _half(s.first, top: true)),
                  Expanded(child: _half(s.second, top: false)),
                ],
              )
            : _half(s.first, top: true, fill: true),
      ),
    );
  }

  Widget _half(TimetableLesson lesson, {required bool top, bool fill = false}) {
    if (lesson.isEmpty) {
      return Container(
        width: double.infinity,
        color: AppTheme.card,
        alignment: Alignment.center,
        child: Icon(
          Icons.add,
          size: 14,
          color: AppTheme.ink.withValues(alpha: 0.25),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Color(displayLessonColor(lesson)).withValues(alpha: 0.22),
        border: Border(
          bottom: top && !fill
              ? BorderSide(color: AppTheme.ink.withValues(alpha: 0.12))
              : BorderSide.none,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lesson.subject,
            maxLines: fill ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppTheme.ink,
              height: 1.1,
            ),
          ),
          if (lesson.room.isNotEmpty)
            Text(
              lesson.room,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact entry card for the library home.
class TimetableHomeCard extends ConsumerWidget {
  const TimetableHomeCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final table = ref.watch(timetableProvider);
    final now = ref.watch(nowLessonProvider);
    final today = (DateTime.now().weekday - 1).clamp(0, 4);
    final todaySlots = [
      for (var p = 0; p < table.periods.length; p++)
        if (table.slotAt(today, p) != null && !table.slotAt(today, p)!.isEmpty)
          table.slotAt(today, p)!,
    ];

    final subtitle = now != null
        ? l10n.nowLessonShort(now.lesson.subject)
        : todaySlots.isEmpty
        ? l10n.timetableEmptyToday
        : l10n.timetableTodayPreview(
            todaySlots.take(3).map((s) => s.displayLabel).join(' · '),
          );

    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: now != null
                      ? Color(
                          displayLessonColor(now.lesson),
                        ).withValues(alpha: 0.25)
                      : AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_view_week_rounded,
                  color: now != null
                      ? Color(displayLessonColor(now.lesson))
                      : AppTheme.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.timetable,
                      style: AppTheme.headline(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.ink.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner on the library when a linked subject is currently on.
class NowSubjectBanner extends ConsumerWidget {
  const NowSubjectBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowLessonProvider);
    if (now == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final folders = ref.watch(allFoldersProvider).valueOrNull ?? [];
    LibraryFolder? folder;
    if (now.lesson.folderId != null) {
      for (final f in folders) {
        if (f.id == now.lesson.folderId) {
          folder = f;
          break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Material(
        color: Color(displayLessonColor(now.lesson)).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: folder == null
              ? null
              : () => ref.read(currentFolderIdProvider.notifier).state =
                    folder!.id,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(displayLessonColor(now.lesson)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.schedule, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.nowOn,
                        style: AppTheme.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkMuted,
                        ),
                      ),
                      Text(
                        folder?.name ?? now.lesson.subject,
                        style: AppTheme.headline(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      Text(
                        now.timeRange,
                        style: AppTheme.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (folder != null)
                  Icon(
                    Icons.folder_open_rounded,
                    color: Color(displayLessonColor(now.lesson)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
