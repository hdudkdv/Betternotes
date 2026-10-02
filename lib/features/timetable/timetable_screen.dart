import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../app/theme.dart';
import '../../data/models/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../import_export/subject_notebook_link.dart';
import '../library/providers/library_providers.dart';
import '../teacher/gradebook/gradebook_store.dart';
import 'timetable_model.dart';
import 'timetable_pdf_import.dart';

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
    int period, {
    TimetableWeek week = TimetableWeek.both,
    required bool abWeeksEnabled,
  }) async {
    final table = ref.read(timetableProvider);
    final folders = await ref.read(allFoldersProvider.future);
    if (!context.mounted) return;
    final existing =
        table.slotAt(day, period, week: abWeeksEnabled ? week : null) ??
        TimetableSlot(
          day: day,
          period: period,
          week: abWeeksEnabled ? week : TimetableWeek.both,
        );
    final result = await showDialog<_SlotEditResult?>(
      context: context,
      builder: (context) => _SlotEditorDialog(
        dayLabel: _dayLabel(AppLocalizations.of(context)!, day),
        period: table.periods[period],
        initial: existing,
        folders: folders,
        showClassField: ref.read(settingsProvider).isTeacher,
        defaultSchoolClass: '',
        abWeeksEnabled: abWeeksEnabled,
        editWeek: week,
      ),
    );
    if (result == null) return;
    if (result.slot.isEmpty) {
      await ref
          .read(timetableProvider.notifier)
          .clearSlot(
            day,
            period,
            week: abWeeksEnabled ? result.slot.week : null,
          );
      return;
    }
    final slot = await _attachCreatedFolders(
      ref,
      result.slot,
      createFirst: result.createFirstFolder,
      createSecond: result.createSecondFolder,
    );
    await ref.read(timetableProvider.notifier).setSlot(slot);
    if (ref.read(settingsProvider).isTeacher) {
      await ref.read(gradebookProvider.notifier).ensureClasses([
        if (slot.first.schoolClass.trim().isNotEmpty) slot.first.schoolClass,
        if (slot.split && slot.second.schoolClass.trim().isNotEmpty)
          slot.second.schoolClass,
      ]);
    }
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
      week: slot.week,
      startMinutes: slot.startMinutes,
      endMinutes: slot.endMinutes,
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
      return lessonFromFolder(existing).copyWith(
        room: lesson.room,
        schoolClass: lesson.schoolClass,
      );
    }
    final created = await ref
        .read(notebookRepositoryProvider)
        .createFolder(name: name, colorValue: colorForSubject(name));
    refreshLibraryLists(ref);
    return lessonFromFolder(created).copyWith(
      room: lesson.room,
      schoolClass: lesson.schoolClass,
    );
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

  Future<void> _importPlan(
    BuildContext context,
    WidgetRef ref, {
    required bool scan,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    var loading = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final imported = scan
          ? await const TimetablePdfImport().scanOrPickImage()
          : await const TimetablePdfImport().pickPdf();
      if (context.mounted && loading) {
        Navigator.pop(context);
        loading = false;
      }
      if (!context.mounted || imported == null) return;
      if (imported.slots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importTimetableEmpty)),
        );
        return;
      }
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(scan ? l10n.importTimetableScan : l10n.importTimetablePdf),
          content: Text(l10n.importTimetableFound(imported.lessonCount)),
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
      if (ok != true || !context.mounted) return;
      await ref.read(timetableProvider.notifier).importUniversityPlan(
            title: imported.title,
            slots: imported.slots,
          );
      if (!ref.read(settingsProvider).abWeeksEnabled) {
        await ref.read(settingsProvider.notifier).setAbWeeksEnabled(true);
      }
    } catch (_) {
      if (context.mounted && loading) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importTimetableFailed)),
        );
      }
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final table = ref.read(timetableProvider);
    final settings = ref.read(settingsProvider);
    final week = settings.abWeeksEnabled
        ? currentAbWeek(DateTime.now(), swapped: settings.abWeeksSwapped)
        : null;
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
                          _pdfCell(
                            _slotPdfText(
                              table.slotAt(d, p, week: week),
                              fallbackTime: table.periods[p].timeRange,
                            ),
                          ),
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

  Future<void> _openGrades(BuildContext context, WidgetRef ref) async {
    final current = ref.read(currentLessonClassProvider);
    context.push(
      current == null
          ? '/teacher/grades'
          : '/teacher/grades?class=${Uri.encodeQueryComponent(current)}',
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

  static String _slotPdfText(
    TimetableSlot? slot, {
    String fallbackTime = '',
  }) {
    if (slot == null || slot.isEmpty) return '';
    String line(TimetableLesson lesson) {
      final extra = [
        if (lesson.schoolClass.trim().isNotEmpty) lesson.schoolClass.trim(),
        if (lesson.room.isNotEmpty) lesson.room,
      ].join(' · ');
      return extra.isEmpty ? lesson.subject : '${lesson.subject}\n$extra';
    }

    final time = slot.hasCustomTime ? slot.timeRange : fallbackTime;
    final body = !slot.split
        ? line(slot.first)
        : '${line(slot.first)}\n/\n${line(slot.second)}';
    return time.isEmpty ? body : '$time\n$body';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final table = ref.watch(timetableProvider);
    final now = ref.watch(nowLessonProvider);
    final isTeacher = ref.watch(settingsProvider).isTeacher;
    final settings = ref.watch(settingsProvider);
    final isUniversity = settings.isUniversity;
    final todayWeek = currentAbWeek(
      DateTime.now(),
      swapped: settings.abWeeksSwapped,
    );
    final previewWeek = ref.watch(timetablePreviewWeekProvider);
    final abWeek = (settings.abWeeksEnabled || isUniversity)
        ? (previewWeek ?? todayWeek)
        : null;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(l10n.timetable, style: AppTheme.headline()),
        actions: [
          if (isTeacher)
            IconButton(
              tooltip: l10n.timetableOpenGradebook,
              onPressed: () => _openGrades(context, ref),
              icon: const Icon(Icons.bar_chart_rounded),
            ),
          if (isUniversity)
            IconButton(
              tooltip: l10n.importTimetablePdf,
              onPressed: () => _importPlan(context, ref, scan: false),
              icon: const Icon(Icons.upload_file_outlined),
            ),
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
                case 'grades':
                  _openGrades(context, ref);
                case 'importPdf':
                  await _importPlan(context, ref, scan: false);
                case 'importScan':
                  await _importPlan(context, ref, scan: true);
                case 'university':
                  await ref
                      .read(timetableProvider.notifier)
                      .applyPeriodTemplate(
                        Timetable.universitySemesterPeriods(),
                      );
                  if (!settings.abWeeksEnabled) {
                    await ref
                        .read(settingsProvider.notifier)
                        .setAbWeeksEnabled(true);
                  }
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
              if (isUniversity) ...[
                PopupMenuItem(
                  value: 'importPdf',
                  child: Text(l10n.importTimetablePdf),
                ),
                PopupMenuItem(
                  value: 'importScan',
                  child: Text(l10n.importTimetableScan),
                ),
                PopupMenuItem(
                  value: 'university',
                  child: Text(l10n.universityPeriodTemplate),
                ),
              ],
              if (isTeacher)
                PopupMenuItem(
                  value: 'grades',
                  child: Text(l10n.teacherGradeReport),
                ),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.calendarWeekParity(
                    '${isoWeekNumber(DateTime.now())}',
                    isoWeekNumber(DateTime.now()).isOdd
                        ? l10n.weekOdd
                        : l10n.weekEven,
                  ),
                  style: AppTheme.body(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                if (isUniversity) ...[
                  Text(
                    table.title,
                    style: AppTheme.headline(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(l10n.thisWeek),
                        selected: previewWeek == null,
                        onSelected: (_) => ref
                            .read(timetablePreviewWeekProvider.notifier)
                            .state = null,
                      ),
                      FilterChip(
                        label: Text(l10n.weekA),
                        selected: previewWeek == TimetableWeek.a,
                        onSelected: (_) => ref
                            .read(timetablePreviewWeekProvider.notifier)
                            .state = TimetableWeek.a,
                      ),
                      FilterChip(
                        label: Text(l10n.weekB),
                        selected: previewWeek == TimetableWeek.b,
                        onSelected: (_) => ref
                            .read(timetablePreviewWeekProvider.notifier)
                            .state = TimetableWeek.b,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!isUniversity)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                isTeacher ? l10n.timetableTeacherHint : l10n.timetableHint,
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
                  week: abWeek,
                  universityStyle: isUniversity,
                  dayLabel: (d) => _dayLabel(l10n, d),
                  onTapSlot: (day, period) => _editSlot(
                    context,
                    ref,
                    day,
                    period,
                    week: abWeek ?? TimetableWeek.both,
                    abWeeksEnabled: settings.abWeeksEnabled || isUniversity,
                  ),
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
              now.lesson.schoolClass.trim().isEmpty
                  ? l10n.nowLesson(
                      now.lesson.subject,
                      '$dayLabel · ${now.timeRange}',
                    )
                  : l10n.nowLessonWithClass(
                      now.lesson.schoolClass.trim(),
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
    this.showClassField = false,
    this.defaultSchoolClass = '',
    this.abWeeksEnabled = false,
    this.editWeek = TimetableWeek.both,
  });

  final String dayLabel;
  final TimetablePeriod period;
  final TimetableSlot initial;
  final List<LibraryFolder> folders;
  final bool showClassField;
  final String defaultSchoolClass;
  final bool abWeeksEnabled;
  final TimetableWeek editWeek;

  @override
  State<_SlotEditorDialog> createState() => _SlotEditorDialogState();
}

class _SlotEditorDialogState extends State<_SlotEditorDialog> {
  late bool _split;
  late TimetableLesson _first;
  late TimetableLesson _second;
  late TextEditingController _room1;
  late TextEditingController _room2;
  late TextEditingController _class1;
  late TextEditingController _class2;
  late TextEditingController _subject1;
  late TextEditingController _subject2;
  late bool _createFolder1;
  late bool _createFolder2;
  late TimetableWeek _week;
  late int _start;
  late int _end;

  @override
  void initState() {
    super.initState();
    _split = widget.initial.split;
    _first = widget.initial.first;
    _second = widget.initial.second;
    _start = widget.initial.startMinutes ?? widget.period.startMinutes;
    _end = widget.initial.endMinutes ?? widget.period.endMinutes;
    _room1 = TextEditingController(text: _first.room);
    _room2 = TextEditingController(text: _second.room);
    _class1 = TextEditingController(
      text: _first.schoolClass.trim().isNotEmpty
          ? _first.schoolClass
          : widget.defaultSchoolClass,
    );
    _class2 = TextEditingController(
      text: _second.schoolClass.trim().isNotEmpty
          ? _second.schoolClass
          : widget.defaultSchoolClass,
    );
    _subject1 = TextEditingController(text: _first.subject);
    _subject2 = TextEditingController(text: _second.subject);
    _createFolder1 = _first.folderId == null;
    _createFolder2 = _second.folderId == null;
    _week = widget.initial.week;
  }

  @override
  void dispose() {
    _room1.dispose();
    _room2.dispose();
    _class1.dispose();
    _class2.dispose();
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
      ).copyWith(
        room: firstHalf ? _room1.text : _room2.text,
        schoolClass: firstHalf ? _class1.text : _class2.text,
      );
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
      schoolClass: _class1.text.trim(),
      colorValue: _first.folderId == null
          ? colorForSubject(_subject1.text)
          : _first.colorValue,
    );
    var second = _second.copyWith(
      subject: _subject2.text.trim(),
      room: _room2.text.trim(),
      schoolClass: _class2.text.trim(),
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
      week: widget.abWeeksEnabled ? _week : TimetableWeek.both,
      startMinutes: _start,
      endMinutes: _end <= _start ? _start + 45 : _end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effective = widget.period.copyWith(
      startMinutes: _start,
      endMinutes: _end <= _start ? _start + 45 : _end,
    );
    final mid = formatHm(effective.splitAtMinutes);

    return AlertDialog(
      title: Text('${widget.dayLabel} · ${effective.timeRange}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.lessonTime,
                style: AppTheme.body(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.periodStart,
                style: AppTheme.body(fontWeight: FontWeight.w700),
              ),
              TimeWheelPicker(
                minutes: _start,
                onChanged: (v) => setState(() {
                  _start = v;
                  if (_end <= _start) _end = _start + 45;
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
                l10n.blockDuration(effective.durationMinutes),
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.abWeeksEnabled) ...[
                Text(
                  l10n.abWeeks,
                  style: AppTheme.body(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.slotAppliesToBothWeeks),
                      selected: _week == TimetableWeek.both,
                      onSelected: (_) =>
                          setState(() => _week = TimetableWeek.both),
                    ),
                    ChoiceChip(
                      label: Text(l10n.slotOddWeek),
                      selected: _week == TimetableWeek.a,
                      onSelected: (_) =>
                          setState(() => _week = TimetableWeek.a),
                    ),
                    ChoiceChip(
                      label: Text(l10n.slotEvenWeek),
                      selected: _week == TimetableWeek.b,
                      onSelected: (_) =>
                          setState(() => _week = TimetableWeek.b),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
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
                        '${effective.start}–$mid',
                        '$mid–${effective.end}',
                      )
                    : l10n.fullBlockHint(effective.durationMinutes),
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
                classCtrl: _class1,
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
                  classCtrl: _class2,
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
                  week: widget.abWeeksEnabled ? _week : TimetableWeek.both,
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
    required TextEditingController classCtrl,
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
        if (widget.showClassField) ...[
          const SizedBox(height: 10),
          TextField(
            controller: classCtrl,
            decoration: InputDecoration(
              labelText: l10n.schoolClass,
              hintText: l10n.timetableClassHint,
            ),
          ),
        ],
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
    this.week,
    this.universityStyle = false,
  });

  final Timetable table;
  final TimetableWeek? week;
  final bool universityStyle;
  final String Function(int day) dayLabel;
  final void Function(int day, int period) onTapSlot;
  final ValueChanged<int> onTapPeriod;

  double get _colW => universityStyle ? 138.0 : 124.0;
  double get _timeW => universityStyle ? 78.0 : 96.0;
  double get _rowH => universityStyle ? 94.0 : 102.0;

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultColumnWidth: FixedColumnWidth(_colW),
      columnWidths: {0: FixedColumnWidth(_timeW)},
      border: TableBorder.all(
        color: AppTheme.ink.withValues(alpha: universityStyle ? 0.28 : 0.18),
        width: universityStyle ? 0.8 : 1,
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: universityStyle ? AppTheme.ink : AppTheme.paperDeep,
          ),
          children: [
            _headerCell(''),
            for (var d = 0; d < Timetable.dayCount; d++)
              _headerCell(dayLabel(d)),
          ],
        ),
        for (var p = 0; p < table.periods.length; p++)
          TableRow(
            decoration: table.periodOverlapsAnother(p)
                ? BoxDecoration(
                    color: AppTheme.accentSoft.withValues(alpha: 0.35),
                  )
                : null,
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
                    child: universityStyle
                        ? _universityTime(context, p)
                        : _schoolTime(context, p),
                  ),
                ),
              ),
              for (var d = 0; d < Timetable.dayCount; d++)
                _slotCell(
                  context,
                  table.slotAt(d, p, week: week),
                  () => onTapSlot(d, p),
                  timeLabel: table.periodFor(d, p, week: week).timeRange,
                  overlapping: table.periodOverlapsAnother(p),
                ),
            ],
          ),
      ],
    );
  }

  Widget _universityTime(BuildContext context, int p) {
    final period = table.periods[p];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          period.start,
          style: AppTheme.body(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AppTheme.ink,
            height: 1.05,
          ),
        ),
        Text(
          '–',
          style: AppTheme.body(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.inkMuted,
            height: 1,
          ),
        ),
        Text(
          period.end,
          style: AppTheme.body(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AppTheme.ink,
            height: 1.05,
          ),
        ),
        if (table.periodOverlapsAnother(p))
          Text(
            AppLocalizations.of(context)!.overlappingPeriod,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppTheme.accent,
            ),
          ),
      ],
    );
  }

  Widget _schoolTime(BuildContext context, int p) {
    return Column(
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
        if (table.periodOverlapsAnother(p))
          Text(
            AppLocalizations.of(context)!.overlappingPeriod,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.accent,
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
    );
  }

  Widget _headerCell(String text) {
    return SizedBox(
      height: universityStyle ? 40 : 44,
      child: Center(
        child: Text(
          text,
          style: AppTheme.body(
            fontWeight: FontWeight.w800,
            fontSize: universityStyle ? 13 : 14,
            color: universityStyle ? AppTheme.onAccent : AppTheme.ink,
          ),
        ),
      ),
    );
  }

  Widget _slotCell(
    BuildContext context,
    TimetableSlot? slot,
    VoidCallback onTap, {
    String? timeLabel,
    bool overlapping = false,
  }) {
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
                  size: universityStyle ? 14 : 18,
                  color: AppTheme.ink.withValues(
                    alpha: overlapping ? 0.18 : 0.35,
                  ),
                ),
              )
            : s.split
            ? Column(
                children: [
                  Expanded(
                    child: _half(
                      context,
                      s.first,
                      top: true,
                      timeLabel: universityStyle ? null : timeLabel,
                      week: s.week,
                    ),
                  ),
                  Expanded(
                    child: _half(
                      context,
                      s.second,
                      top: false,
                      week: s.week,
                    ),
                  ),
                ],
              )
            : _half(
                context,
                s.first,
                top: true,
                fill: true,
                timeLabel: universityStyle ? null : timeLabel,
                week: s.week,
              ),
      ),
    );
  }

  Widget _half(
    BuildContext context,
    TimetableLesson lesson, {
    required bool top,
    bool fill = false,
    String? timeLabel,
    TimetableWeek week = TimetableWeek.both,
  }) {
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
    final color = Color(displayLessonColor(lesson));
    final l10n = AppLocalizations.of(context);
    final weekLabel = switch (week) {
      TimetableWeek.both => l10n?.weekWeeklyShort ?? 'wöch.',
      TimetableWeek.a => l10n?.weekOddShort ?? 'UW',
      TimetableWeek.b => l10n?.weekEvenShort ?? 'GW',
    };
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(universityStyle ? 7 : 8, 5, 6, 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: universityStyle ? 0.18 : 0.22),
        border: Border(
          left: universityStyle
              ? BorderSide(color: color, width: 4)
              : BorderSide.none,
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
              fontSize: universityStyle ? 12 : 13,
              color: AppTheme.ink,
              height: 1.1,
            ),
          ),
          if (timeLabel != null && timeLabel.isNotEmpty)
            Text(
              timeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
              ),
            ),
          if (lesson.schoolClass.trim().isNotEmpty || lesson.room.isNotEmpty)
            Text(
              [
                if (lesson.schoolClass.trim().isNotEmpty)
                  lesson.schoolClass.trim(),
                if (lesson.room.isNotEmpty) lesson.room,
              ].join(' · '),
              maxLines: universityStyle ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkMuted,
                height: 1.15,
              ),
            ),
          if (universityStyle)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                weekLabel,
                style: AppTheme.body(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.2,
                ),
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
    final settings = ref.watch(settingsProvider);
    final week = settings.abWeeksEnabled
        ? currentAbWeek(DateTime.now(), swapped: settings.abWeeksSwapped)
        : null;
    final today = (DateTime.now().weekday - 1).clamp(0, 4);
    final todaySlots = [
      for (var p = 0; p < table.periods.length; p++)
        if (table.slotAt(today, p, week: week) != null &&
            !table.slotAt(today, p, week: week)!.isEmpty)
          table.slotAt(today, p, week: week)!,
    ];

    final heading = l10n.timetable;
    final className = now?.lesson.schoolClass.trim() ?? '';
    final subtitle = now != null
        ? (className.isEmpty
              ? l10n.nowLessonShort(now.lesson.subject)
              : l10n.nowLessonShortWithClass(className, now.lesson.subject))
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
                      heading,
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
