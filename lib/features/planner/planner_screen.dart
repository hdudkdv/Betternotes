import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../import_export/csv_service.dart';
import '../import_export/subject_notebook_link.dart';
import '../library/providers/library_providers.dart';
import '../scanner/document_scanner_service.dart';
import '../scanner/scan_into_notebook.dart';
import '../timetable/timetable_model.dart';
import 'education_settings.dart';
import 'grade_attachment_store.dart';
import 'grade_calculator.dart';
import 'grade_period.dart';
import 'grade_pickers.dart';
import 'grade_value_codec.dart';
import 'grade_view_helpers.dart';
import 'planner_model.dart';
import 'school_year.dart';

String periodLabel(GradePeriod period, AppLocalizations l10n) =>
    switch (period) {
      GradePeriod.h1 => l10n.periodH1,
      GradePeriod.h2 => l10n.periodH2,
      GradePeriod.q1 => l10n.periodQ1,
      GradePeriod.q2 => l10n.periodQ2,
      GradePeriod.q3 => l10n.periodQ3,
      GradePeriod.q4 => l10n.periodQ4,
      GradePeriod.abiExam => l10n.periodAbiExam,
      GradePeriod.semester => l10n.periodSemester,
    };

String _weekdayLabel(AppLocalizations l10n, int weekday) => switch (weekday) {
  DateTime.monday => l10n.weekdayMon,
  DateTime.tuesday => l10n.weekdayTue,
  DateTime.wednesday => l10n.weekdayWed,
  DateTime.thursday => l10n.weekdayThu,
  DateTime.friday => l10n.weekdayFri,
  DateTime.saturday => l10n.weekdaySat,
  _ => l10n.weekdaySun,
};

// ─── Home: three equal cells ───────────────────────────────────────────────

class LibrarySchoolRow extends ConsumerWidget {
  const LibrarySchoolRow({
    super.key,
    required this.onTimetable,
    required this.onGrades,
    required this.onCalendar,
  });

  final VoidCallback onTimetable;
  final VoidCallback onGrades;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final table = ref.watch(timetableProvider);
    final planner = ref.watch(plannerProvider);
    final now = ref.watch(nowLessonProvider);
    final settings = ref.watch(settingsProvider);
    final subjects = table.distinctSubjectNames();
    final calc = GradeCalculator(
      level: settings.educationLevel,
      grades: planner.gradesForLevel(settings.educationLevel),
      subjectWeights: planner.subjectWeights,
      subjects: subjects,
      courseCount: settings.abiCourseCount,
      examCount: settings.abiExamCount,
      targetEcts: settings.targetEcts,
    );
    final avg = switch (settings.educationLevel) {
      EducationLevel.university => calc.uniPrognosis().gpa,
      EducationLevel.sek2 =>
        calc.abiPrognosis().projectedNote ??
            calc.abiPrognosis().currentPointAverage,
      EducationLevel.sek1 => calc.overallSubjectAverage(),
    };
    final upcoming = planner.upcoming(limit: 1);
    final today = (DateTime.now().weekday - DateTime.monday).clamp(0, 4);
    final todaySlots = [
      for (var p = 0; p < table.periods.length; p++)
        if (table.slotAt(today, p) != null && !table.slotAt(today, p)!.isEmpty)
          table.slotAt(today, p)!,
    ];

    final ttSub = now != null
        ? l10n.nowLessonShort(now.lesson.subject)
        : todaySlots.isEmpty
        ? l10n.timetableEmptyToday
        : todaySlots.take(2).map((s) => s.displayLabel).join(' · ');

    final gradesSub = avg != null
        ? l10n.gradeAverageShort(avg.toStringAsFixed(2))
        : subjects.isEmpty
        ? l10n.gradesNeedTimetable
        : l10n.noGradesYet;

    final calSub = upcoming.isEmpty
        ? l10n.plannerEmptyHint
        : (upcoming.first.title.trim().isEmpty
              ? upcoming.first.displaySubject
              : upcoming.first.title);

    return Row(
      children: [
        Expanded(
          child: _HomeCell(
            title: l10n.timetable,
            subtitle: ttSub,
            icon: Icons.calendar_view_week_rounded,
            color: AppTheme.accent,
            soft: AppTheme.accentSoft,
            onTap: onTimetable,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HomeCell(
            title: l10n.grades,
            subtitle: gradesSub,
            icon: Icons.grade_rounded,
            color: const Color(0xFF8B5E3C),
            soft: AppTheme.accentSoft,
            onTap: onGrades,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HomeCell(
            title: l10n.calendar,
            subtitle: calSub,
            icon: Icons.event_note_rounded,
            color: const Color(0xFF1D4E89),
            soft: const Color(0xFFD6E2F0),
            onTap: onCalendar,
          ),
        ),
      ],
    );
  }
}

class _HomeCell extends StatelessWidget {
  const _HomeCell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.headline(
                  fontSize: 14,
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
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

// ─── Calendar screen ───────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  bool _eventsExpanded = false;

  Future<void> _editEvent([PlannerEvent? existing]) async {
    final wasNew = existing == null;
    final result = await showModalBottomSheet<PlannerEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _EventEditorSheet(initial: existing, defaultDay: _selectedDay),
    );
    if (result == null) return;
    await ref.read(plannerProvider.notifier).upsertEvent(result);
    if (!mounted) return;
    if (wasNew && result.kind == PlannerEventKind.exam) {
      await _maybeCreateGradeForExam(result);
    }
  }

  Future<void> _maybeCreateGradeForExam(PlannerEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    final create = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.paper,
        title: Text(l10n.createGradeFromExam),
        content: Text(l10n.createGradeFromExamBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (create != true || !mounted) return;
    final settings = ref.read(settingsProvider);
    final subject = event.subject.trim().isEmpty
        ? event.title.trim()
        : event.subject.trim();
    final grade = GradeEntry.create(
      value: null,
      date: event.start,
      subject: subject,
      title: event.title,
      category: GradeCategory.major,
      scale: settings.educationLevel.defaultScale,
      period: GradePeriodX.defaultFor(settings.educationLevel),
      educationLevel: settings.educationLevel,
      schoolYearStart: SchoolYear.fromDate(event.start).startYear,
      eventId: event.id,
    );
    await ref.read(plannerProvider.notifier).upsertGrade(grade);
    await ref
        .read(plannerProvider.notifier)
        .upsertEvent(event.copyWith(gradeId: grade.id));
    if (!mounted) return;
    final scan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.paper,
        title: Text(l10n.scanExam),
        content: Text(l10n.scanExamBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.scanPages),
          ),
        ],
      ),
    );
    if (scan == true && mounted) {
      await scanIntoNotebook(
        context,
        ref,
        suggestedTitle: event.title.trim().isEmpty
            ? null
            : event.title.trim(),
      );
    }
  }

  Future<void> _shareEvent(PlannerEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    final text = event.toShareText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.shareAppointment,
                style: AppTheme.headline(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.copiedForForward)),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(l10n.copyForForward),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: event.toIcs()));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.icsCopied)));
                  }
                },
                icon: const Icon(Icons.event_available_rounded),
                label: Text(l10n.copyIcs),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deviceCalendarComingSoon,
                style: AppTheme.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.inkMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planner = ref.watch(plannerProvider);
    final settings = ref.watch(settingsProvider);
    final holiday = SchoolHolidays.holidayOn(
      settings.germanState,
      _selectedDay,
      l10n,
    );
    final events = planner.eventsOn(_selectedDay);
    final monthLabel = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendar)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editEvent(),
        icon: const Icon(Icons.add),
        label: Text(l10n.addAppointment),
      ),
      body: Column(
        children: [
          const _WeekdayHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _selectedDay = DateTime(
                          _selectedDay.year,
                          _selectedDay.month - 1,
                          1,
                        );
                      }),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        style: AppTheme.headline(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _selectedDay = DateTime(
                          _selectedDay.year,
                          _selectedDay.month + 1,
                          1,
                        );
                      }),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                Text(
                  l10n.holidaysForState(settings.germanState.label(l10n)),
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.inkMuted,
                  ),
                ),
                const SizedBox(height: 10),
                _MonthGrid(
                  month: DateTime(_selectedDay.year, _selectedDay.month),
                  selected: _selectedDay,
                  state: settings.germanState,
                  onSelect: (d) => setState(() => _selectedDay = d),
                ),
                if (holiday != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.holidayBanner(holiday.name),
                      style: AppTheme.body(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                InkWell(
                  onTap: () =>
                      setState(() => _eventsExpanded = !_eventsExpanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.appointmentsOnDay(
                              DateFormat.MMMd(
                                Localizations.localeOf(context).toString(),
                              ).format(_selectedDay),
                            ),
                            style: AppTheme.body(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${events.length}',
                          style: AppTheme.body(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                        Icon(
                          _eventsExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _eventsExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: events.isEmpty
                        ? Text(
                            l10n.noAppointmentsYet,
                            style: AppTheme.body(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.inkMuted,
                            ),
                          )
                        : Column(
                            children: [
                              for (final event in events)
                                _EventTile(
                                  event: event,
                                  onTap: () => _editEvent(event),
                                  onShare: () => _shareEvent(event),
                                  onDelete: () => ref
                                      .read(plannerProvider.notifier)
                                      .deleteEvent(event.id),
                                ),
                            ],
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

/// The weekday row remains visible while the month and the appointments scroll.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.mondayShort,
      l10n.tuesdayShort,
      l10n.wednesdayShort,
      l10n.thursdayShort,
      l10n.fridayShort,
      l10n.saturdayShort,
      l10n.sundayShort,
    ];
    return Material(
      color: AppTheme.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
        child: Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: AppTheme.body(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.state,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final GermanState state;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final planner = ref.watch(plannerProvider);
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = first.weekday;
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ((startWeekday - 1) + daysInMonth + 6) ~/ 7 * 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final dayNum = index - (startWeekday - 1) + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(month.year, month.month, dayNum);
            final isSelected =
                day.year == selected.year &&
                day.month == selected.month &&
                day.day == selected.day;
            final dayEvents = planner.eventsOn(day);
            final hasEvents = dayEvents.isNotEmpty;
            final isHoliday =
                SchoolHolidays.holidayOn(state, day, l10n) != null;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelect(day),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.ink
                      : isHoliday
                      ? AppTheme.accentSoft
                      : AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasEvents && !isSelected
                        ? AppTheme.accent
                        : Colors.transparent,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '$dayNum',
                        style: AppTheme.body(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected ? AppTheme.onAccent : AppTheme.ink,
                        ),
                      ),
                    ),
                    if (dayEvents.isNotEmpty)
                      Positioned(
                        top: 5,
                        left: 5,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final event in dayEvents.take(3))
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(right: 2),
                                decoration: BoxDecoration(
                                  color: Color(event.colorValue),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (dayEvents.length > 3)
                              Text(
                                '+${dayEvents.length - 3}',
                                style: AppTheme.body(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? AppTheme.onAccent
                                      : AppTheme.inkMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  final PlannerEvent event;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm().format(event.start);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(event.colorValue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title.trim().isEmpty
                            ? event.displaySubject
                            : event.title,
                        style: AppTheme.body(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.ink,
                        ),
                      ),
                      Text(
                        [
                          time,
                          if (event.subject.trim().isNotEmpty)
                            event.subject.trim(),
                        ].join(' · '),
                        style: AppTheme.body(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_outlined),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventEditorSheet extends ConsumerStatefulWidget {
  const _EventEditorSheet({this.initial, required this.defaultDay});

  final PlannerEvent? initial;
  final DateTime defaultDay;

  @override
  ConsumerState<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends ConsumerState<_EventEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late DateTime _start;
  DateTime? _end;
  String _subject = '';
  int _color = 0xFF0F6E56;
  String? _folderId;
  PlannerEventKind _kind = PlannerEventKind.appointment;
  EventRecurrence? _recurrence;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?.title ?? '');
    _note = TextEditingController(text: i?.note ?? '');
    _start =
        i?.start ??
        DateTime(
          widget.defaultDay.year,
          widget.defaultDay.month,
          widget.defaultDay.day,
          9,
        );
    _end = i?.end;
    _subject = i?.subject ?? '';
    _folderId = i?.folderId;
    _kind = i?.kind ?? PlannerEventKind.appointment;
    _color = i?.colorValue ?? 0xFF0F6E56;
    _recurrence = i?.recurrence;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool end}) async {
    final base = end ? (_end ?? _start.add(const Duration(hours: 1))) : _start;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    final next = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (end) {
        _end = next;
      } else {
        _start = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final table = ref.watch(timetableProvider);
    final dayIndex = Timetable.dayIndexFromWeekday(_start.weekday);
    final dayLessons = table.distinctLessons(day: dayIndex);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null
                  ? l10n.addAppointment
                  : l10n.editAppointment,
              style: AppTheme.headline(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.title),
            ),
            const SizedBox(height: 12),
            Text(
              dayIndex == null
                  ? l10n.subjectFromTimetableWeekend
                  : l10n.subjectFromTimetableDay,
              style: AppTheme.body(
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            if (dayLessons.isEmpty)
              Text(
                l10n.noSubjectsThatDay,
                style: AppTheme.body(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.inkMuted,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final lesson in dayLessons)
                    ChoiceChip(
                      label: Text(
                        lesson.subject,
                        style: AppTheme.body(
                          fontWeight: FontWeight.w700,
                          color:
                              subjectKey(_subject) == subjectKey(lesson.subject)
                              // Sits on the saturated subject colour.
                              ? Colors.white
                              : AppTheme.ink,
                        ),
                      ),
                      selected:
                          subjectKey(_subject) == subjectKey(lesson.subject),
                      selectedColor: Color(lesson.colorValue),
                      backgroundColor: AppTheme.card,
                      onSelected: (_) => setState(() {
                        _subject = lesson.subject;
                        _folderId = lesson.folderId;
                        _color = lesson.colorValue;
                        if (_title.text.trim().isEmpty) {
                          _title.text = lesson.subject;
                        }
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            SegmentedButton<PlannerEventKind>(
              segments: [
                ButtonSegment(
                  value: PlannerEventKind.appointment,
                  label: Text(l10n.kindAppointment),
                ),
                ButtonSegment(
                  value: PlannerEventKind.exam,
                  label: Text(l10n.kindExam),
                ),
                ButtonSegment(
                  value: PlannerEventKind.homework,
                  label: Text(l10n.kindHomework),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.startsAt),
              subtitle: Text(DateFormat.yMMMd().add_Hm().format(_start)),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () => _pickDateTime(end: false),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.endsAt),
              subtitle: Text(
                _end == null
                    ? l10n.optional
                    : DateFormat.yMMMd().add_Hm().format(_end!),
              ),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () => _pickDateTime(end: true),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.repeatEvent),
              value: _recurrence != null,
              onChanged: (enabled) => setState(() {
                _recurrence = enabled
                    ? EventRecurrence(
                        frequency: RecurrenceFrequency.weekly,
                        weekdays: [_start.weekday],
                        until: _start.add(const Duration(days: 90)),
                      )
                    : null;
              }),
            ),
            if (_recurrence case final recurrence?) ...[
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: recurrence.frequency,
                decoration: InputDecoration(labelText: l10n.repeatFrequency),
                items: [
                  DropdownMenuItem(
                    value: RecurrenceFrequency.daily,
                    child: Text(l10n.repeatDaily),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceFrequency.weekly,
                    child: Text(l10n.repeatWeekly),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceFrequency.monthly,
                    child: Text(l10n.repeatMonthly),
                  ),
                ],
                onChanged: (frequency) {
                  if (frequency == null) return;
                  setState(
                    () => _recurrence = EventRecurrence(
                      frequency: frequency,
                      interval: recurrence.interval,
                      weekdays: recurrence.weekdays,
                      until: recurrence.until,
                    ),
                  );
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: recurrence.interval,
                decoration: InputDecoration(labelText: l10n.repeatInterval),
                items: [
                  for (final interval in [1, 2, 3, 4])
                    DropdownMenuItem(
                      value: interval,
                      child: Text(l10n.repeatEvery(interval)),
                    ),
                ],
                onChanged: (interval) {
                  if (interval == null) return;
                  setState(
                    () => _recurrence = EventRecurrence(
                      frequency: recurrence.frequency,
                      interval: interval,
                      weekdays: recurrence.weekdays,
                      until: recurrence.until,
                    ),
                  );
                },
              ),
              if (recurrence.frequency == RecurrenceFrequency.weekly)
                Wrap(
                  spacing: 4,
                  children: [
                    for (var weekday = 1; weekday <= 7; weekday++)
                      FilterChip(
                        label: Text(_weekdayLabel(l10n, weekday)),
                        selected: recurrence.weekdays.contains(weekday),
                        onSelected: (selected) {
                          final weekdays = [...recurrence.weekdays];
                          if (selected) {
                            weekdays.add(weekday);
                          } else {
                            weekdays.remove(weekday);
                          }
                          if (weekdays.isEmpty) return;
                          setState(
                            () => _recurrence = EventRecurrence(
                              frequency: recurrence.frequency,
                              interval: recurrence.interval,
                              weekdays: weekdays..sort(),
                              until: recurrence.until,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.repeatUntil),
                subtitle: Text(DateFormat.yMMMd().format(recurrence.until)),
                trailing: const Icon(Icons.event_available_outlined),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: recurrence.until,
                    firstDate: DateTime(_start.year, _start.month, _start.day),
                    lastDate: DateTime(2100),
                  );
                  if (date == null || !mounted) return;
                  setState(
                    () => _recurrence = EventRecurrence(
                      frequency: recurrence.frequency,
                      interval: recurrence.interval,
                      weekdays: recurrence.weekdays,
                      until: date,
                    ),
                  );
                },
              ),
            ],
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.noteOptional),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final title = _title.text.trim();
                if (title.isEmpty && _subject.isEmpty) return;
                final event =
                    (widget.initial ??
                            PlannerEvent.create(
                              title: title.isEmpty ? _subject : title,
                              start: _start,
                            ))
                        .copyWith(
                          title: title.isEmpty ? _subject : title,
                          subject: _subject,
                          start: _start,
                          end: _end,
                          folderId: _folderId,
                          clearFolder: _folderId == null,
                          note: _note.text.trim(),
                          kind: _kind,
                          colorValue: _color,
                          recurrence: _recurrence,
                        );
                Navigator.pop(context, event);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grades screen ─────────────────────────────────────────────────────────

class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  GradePeriod? _period;
  EducationLevel? _section;
  final Map<EducationLevel, SchoolYear> _yearByLevel = {};

  EducationLevel _activeSection(EducationLevel settingsDefault) =>
      _section ?? settingsDefault;

  SchoolYear _yearFor(EducationLevel level, PlannerState planner) {
    final existing = _yearByLevel[level];
    if (existing != null) return existing;
    final years = planner.yearsForLevel(level);
    return years.isEmpty ? SchoolYear.current() : years.first;
  }

  void _setYear(EducationLevel level, SchoolYear year) {
    setState(() => _yearByLevel[level] = year);
  }

  GradePeriod _activePeriod(EducationLevel level) {
    final allowed = GradePeriodX.forLevel(level);
    if (_period != null && allowed.contains(_period)) return _period!;
    return GradePeriodX.defaultFor(level);
  }

  Future<void> _editGrade({
    GradeEntry? existing,
    String? subject,
    EducationLevel? levelOverride,
    SchoolYear? yearOverride,
  }) async {
    final settings = ref.read(settingsProvider);
    final level =
        existing?.resolvedLevel ??
        levelOverride ??
        _activeSection(settings.educationLevel);
    final year =
        existing?.schoolYear ??
        yearOverride ??
        _yearFor(level, ref.read(plannerProvider));
    final result = await showModalBottomSheet<GradeEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _GradeEditorSheet(
        initial: existing,
        presetSubject: subject,
        defaultPeriod: _activePeriod(level),
        forcedLevel: level,
        forcedYear: year,
      ),
    );
    if (result == null) return;
    await ref.read(plannerProvider.notifier).upsertGrade(result);
  }

  Future<void> _editWeight(String subject, EducationLevel level) async {
    final planner = ref.read(plannerProvider);
    final l10n = AppLocalizations.of(context)!;
    var percent = planner.weightFor(subject).majorPercent;

    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.weightForSubject(subject),
                    style: AppTheme.headline(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.weightHint(
                      level.majorLabel(l10n),
                      level.minorLabel(l10n),
                    ),
                    style: AppTheme.body(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${level.majorLabel(l10n)}: $percent%',
                    style: AppTheme.body(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.ink,
                    ),
                  ),
                  Slider(
                    value: percent.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$percent%',
                    onChanged: (v) => setLocal(() => percent = v.round()),
                  ),
                  Text(
                    '${level.minorLabel(l10n)}: ${100 - percent}%',
                    style: AppTheme.body(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, percent),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result == null) return;
    await ref
        .read(plannerProvider.notifier)
        .setSubjectWeight(
          SubjectWeight(subject: subject, majorPercent: result),
        );
  }

  GradeCalculator _calcFor({
    required EducationLevel level,
    required SchoolYear year,
    required PlannerState planner,
    required AppSettings settings,
    required List<String> subjects,
  }) {
    return GradeCalculator(
      level: level,
      grades: planner.gradesForLevelYear(level, year),
      subjectWeights: planner.subjectWeights,
      subjects: subjects,
      courseCount: settings.abiCourseCount,
      examCount: settings.abiExamCount,
      targetEcts: settings.targetEcts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final table = ref.watch(timetableProvider);
    final planner = ref.watch(plannerProvider);
    final settings = ref.watch(settingsProvider);
    final level = _activeSection(settings.educationLevel);
    final year = _yearFor(level, planner);
    final period = _activePeriod(level);
    final lessons = table.distinctLessons();
    final levelGrades = planner.gradesForLevelYear(level, year);
    final subjects = <String>[for (final l in lessons) l.subject.trim()];
    for (final g in levelGrades) {
      final s = g.subject.trim();
      if (s.isEmpty) continue;
      if (!subjects.any((x) => subjectKey(x) == subjectKey(s))) {
        subjects.add(s);
      }
    }
    // Prefer subjects that actually have grades this year first, keep timetable ones.
    final calc = _calcFor(
      level: level,
      year: year,
      planner: planner,
      settings: settings,
      subjects: subjects,
    );
    final periods = GradePeriodX.forLevel(level);
    final knownYears = planner.yearsForLevel(level);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.grades),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              const csv = CsvService();
              final planner = ref.read(plannerProvider);
              if (value == 'export') {
                await csv.shareCsv(
                  csv.gradesToCsv(planner.grades),
                  'grades.csv',
                );
              } else if (value == 'import') {
                final raw = await csv.pickCsvText();
                if (raw == null) return;
                final entries = csv.parseGradesCsv(raw);
                for (final g in entries) {
                  await ref.read(plannerProvider.notifier).upsertGrade(g);
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.csvImportedGrades(entries.length)),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Text(l10n.csvExportGrades),
              ),
              PopupMenuItem(
                value: 'import',
                child: Text(l10n.csvImportGrades),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Compact filter bar: level · year · period
          Material(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (final section in const [
                        EducationLevel.university,
                        EducationLevel.sek2,
                        EducationLevel.sek1,
                      ]) ...[
                        if (section != EducationLevel.university)
                          const SizedBox(width: 6),
                        Expanded(
                          child: _SectionTab(
                            label: section.label(l10n),
                            selected: level == section,
                            count: planner.gradesForLevel(section).length,
                            onTap: () => setState(() {
                              _section = section;
                              _period = null;
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.previousSchoolYear,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _setYear(level, year.previous),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          year.label,
                          textAlign: TextAlign.center,
                          style: AppTheme.headline(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.nextSchoolYear,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _setYear(level, year.next),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  if (knownYears.length > 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final y in knownYears) ...[
                            ChoiceChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                y.label,
                                style: AppTheme.body(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: year == y
                                      ? AppTheme.onAccent
                                      : AppTheme.ink,
                                ),
                              ),
                              selected: year == y,
                              selectedColor: AppTheme.accent,
                              onSelected: (_) => _setYear(level, y),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  if (periods.length > 1) ...[
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final p in periods) ...[
                            ChoiceChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                periodLabel(p, l10n),
                                style: AppTheme.body(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: period == p
                                      ? AppTheme.onAccent
                                      : AppTheme.ink,
                                ),
                              ),
                              selected: period == p,
                              selectedColor: AppTheme.accent,
                              backgroundColor: AppTheme.card,
                              onSelected: (_) => setState(() => _period = p),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (level == EducationLevel.sek2)
            _AbiPrognosisCard(prognosis: calc.abiPrognosis())
          else if (level == EducationLevel.university)
            _UniPrognosisCard(prognosis: calc.uniPrognosis())
          else if (calc.overallSubjectAverage(period: period) != null)
            _Sek1SummaryCard(
              average: calc.overallSubjectAverage(period: period)!,
            ),
          const SizedBox(height: 16),
          if (subjects.isEmpty && levelGrades.isEmpty)
            Text(
              l10n.gradesEmptyYear(year.label),
              style: AppTheme.body(
                fontWeight: FontWeight.w600,
                color: AppTheme.inkMuted,
              ),
            )
          else if (subjects.isEmpty)
            Text(
              l10n.gradesNeedTimetable,
              style: AppTheme.body(
                fontWeight: FontWeight.w600,
                color: AppTheme.inkMuted,
              ),
            )
          else
            for (final subject in subjects)
              _SubjectGradeCard(
                subject: subject,
                color: _colorFor(lessons, subject),
                average: calc.subjectAverage(
                  subject,
                  period: level == EducationLevel.university ? null : period,
                ),
                weight: planner.weightFor(subject),
                gradeCount: planner
                    .gradesForSubject(
                      subject,
                      period: level == EducationLevel.university
                          ? null
                          : period,
                      level: level,
                      year: year,
                    )
                    .length,
                majorLabel: level.majorLabel(l10n),
                minorLabel: level.minorLabel(l10n),
                showWeight: level != EducationLevel.university,
                level: level,
                onAdd: () => _editGrade(
                  subject: subject,
                  levelOverride: level,
                  yearOverride: year,
                ),
                onWeight: () => _editWeight(subject, level),
                onOpen: () => _openSubject(subject, period, level, year),
              ),
        ],
      ),
    );
  }

  int _colorFor(List<TimetableLesson> lessons, String subject) {
    for (final l in lessons) {
      if (subjectKey(l.subject) == subjectKey(subject)) return l.colorValue;
    }
    return 0xFF0F6E56;
  }

  Future<void> _openSubject(
    String subject,
    GradePeriod period,
    EducationLevel level,
    SchoolYear year,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final grades = ref
                .watch(plannerProvider)
                .gradesForSubject(
                  subject,
                  period: level == EducationLevel.university ? null : period,
                  level: level,
                  year: year,
                );
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              minChildSize: 0.35,
              maxChildSize: 0.9,
              builder: (ctx, scroll) {
                return ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    Text(
                      subject,
                      style: AppTheme.headline(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      '${level.label(l10n)} · ${year.label}',
                      style: AppTheme.body(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(l10n.openLinkedNotebook),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(ctx);
                        openNotebookForSubject(
                          context: context,
                          ref: ref,
                          repo: ref.read(notebookRepositoryProvider),
                          subject: subject,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editGrade(
                          subject: subject,
                          levelOverride: level,
                          yearOverride: year,
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addGrade),
                    ),
                    if (grades.isEmpty)
                      Text(
                        l10n.noGradesYet,
                        style: AppTheme.body(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkMuted,
                        ),
                      )
                    else
                      for (final g in grades)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentSoft,
                            child: Text(
                              formatGradeValue(g),
                              style: AppTheme.body(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            g.title.trim().isEmpty
                                ? (g.category == GradeCategory.major
                                      ? level.majorLabel(l10n)
                                      : level.minorLabel(l10n))
                                : g.title,
                            style: AppTheme.body(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          subtitle: Text(
                            [
                              g.category == GradeCategory.major
                                  ? level.majorLabel(l10n)
                                  : level.minorLabel(l10n),
                              if (g.ects > 0)
                                '${g.ects.toStringAsFixed(0)} ECTS',
                              if (g.semesterLabel.isNotEmpty) g.semesterLabel,
                              if (g.attachmentPaths.isNotEmpty)
                                l10n.scanCount(g.attachmentPaths.length),
                              DateFormat.yMMMd().format(g.date),
                            ].join(' · '),
                            style: AppTheme.body(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => ref
                                .read(plannerProvider.notifier)
                                .deleteGrade(g.id),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _editGrade(existing: g, subject: subject);
                          },
                        ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.accent : AppTheme.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selected ? AppTheme.onAccent : AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: AppTheme.body(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: selected
                      ? AppTheme.onAccent.withValues(alpha: 0.8)
                      : AppTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sek1SummaryCard extends StatelessWidget {
  const _Sek1SummaryCard({required this.average});

  final double average;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            l10n.gradeAverage,
            style: AppTheme.body(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.ink,
            ),
          ),
          const Spacer(),
          Text(
            average.toStringAsFixed(2),
            style: AppTheme.headline(
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbiPrognosisCard extends StatelessWidget {
  const _AbiPrognosisCard({required this.prognosis});

  final AbiPrognosis prognosis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avg = prognosis.currentPointAverage;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.abiPrognosisTitle,
            style: AppTheme.headline(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          if (avg != null)
            Text(
              l10n.abiBlockProgress(
                prognosis.completedBlocks,
                avg.toStringAsFixed(1),
              ),
              style: AppTheme.body(
                fontWeight: FontWeight.w600,
                color: AppTheme.inkMuted,
              ),
            ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: prognosis.minPassProgress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppTheme.paperDeep,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.abiMinPassProgress(
              prognosis.collectedPoints.toStringAsFixed(0),
              prognosis.minPassTotal.toStringAsFixed(0),
            ),
            style: AppTheme.body(
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          if (prognosis.projectedTotal != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.abiProjectedPoints(
                prognosis.projectedTotal!.toStringAsFixed(0),
              ),
              style: AppTheme.body(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.ink,
              ),
            ),
            if (prognosis.projectedNote != null)
              Text(
                l10n.abiProjectedNote(
                  prognosis.projectedNote!.toStringAsFixed(1),
                ),
                style: AppTheme.headline(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppTheme.accent,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _UniPrognosisCard extends StatelessWidget {
  const _UniPrognosisCard({required this.prognosis});

  final UniPrognosis prognosis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.uniPrognosisTitle,
            style: AppTheme.headline(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (prognosis.gpa != null)
            Text(
              l10n.uniGpa(prognosis.gpa!.toStringAsFixed(2)),
              style: AppTheme.headline(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: AppTheme.accent,
              ),
            ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: prognosis.ectsProgress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppTheme.paperDeep,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.uniEctsProgress(
              prognosis.earnedEcts.toStringAsFixed(0),
              prognosis.targetEcts.toStringAsFixed(0),
            ),
            style: AppTheme.body(
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectGradeCard extends StatelessWidget {
  const _SubjectGradeCard({
    required this.subject,
    required this.color,
    required this.average,
    required this.weight,
    required this.gradeCount,
    required this.majorLabel,
    required this.minorLabel,
    required this.showWeight,
    required this.level,
    required this.onAdd,
    required this.onWeight,
    required this.onOpen,
  });

  final String subject;
  final int color;
  final double? average;
  final SubjectWeight weight;
  final int gradeCount;
  final String majorLabel;
  final String minorLabel;
  final bool showWeight;
  final EducationLevel level;
  final VoidCallback onAdd;
  final VoidCallback onWeight;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avgText = average == null
        ? '—'
        : level == EducationLevel.sek2
        ? average!.toStringAsFixed(0)
        : average!.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: AppTheme.body(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppTheme.ink,
                            ),
                          ),
                          if (showWeight)
                            Text(
                              l10n.weightSummary(
                                majorLabel,
                                weight.majorPercent,
                                minorLabel,
                                weight.minorPercent,
                              ),
                              style: AppTheme.body(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppTheme.inkMuted,
                              ),
                            ),
                          if (level == EducationLevel.sek2 && average != null)
                            Text(
                              l10n.roundedPoints(average!.toStringAsFixed(0)),
                              style: AppTheme.body(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppTheme.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      avgText,
                      style: AppTheme.headline(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      l10n.gradeCount(gradeCount),
                      style: AppTheme.body(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    const Spacer(),
                    if (showWeight)
                      TextButton(
                        onPressed: onWeight,
                        child: Text(l10n.setWeight),
                      ),
                    TextButton(onPressed: onAdd, child: Text(l10n.addGrade)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeEditorSheet extends ConsumerStatefulWidget {
  const _GradeEditorSheet({
    this.initial,
    this.presetSubject,
    required this.defaultPeriod,
    this.forcedLevel,
    this.forcedYear,
  });

  final GradeEntry? initial;
  final String? presetSubject;
  final GradePeriod defaultPeriod;
  final EducationLevel? forcedLevel;
  final SchoolYear? forcedYear;

  @override
  ConsumerState<_GradeEditorSheet> createState() => _GradeEditorSheetState();
}

class _GradeEditorSheetState extends ConsumerState<_GradeEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final String _gradeId;
  late DateTime _date;
  late String _subject;
  late GradeCategory _category;
  late GradePeriod _period;
  late bool _isAbiSubject;
  String? _folderId;
  double? _value;
  String? _eventId;
  int _ects = 5;
  String? _semester;
  late List<String> _attachments;
  late bool _editing;
  final _scans = GradeAttachmentStore();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _editing = i == null;
    _gradeId = i?.id ?? const Uuid().v4();
    _title = TextEditingController(text: i?.title ?? '');
    _note = TextEditingController(text: i?.note ?? '');
    _ects = i == null || i.ects <= 0 ? 5 : i.ects.round();
    final sem = i?.semesterLabel.trim() ?? '';
    _semester = sem.isEmpty ? null : sem;
    _date = i?.date ?? DateTime.now();
    _subject = i?.subject ?? widget.presetSubject ?? '';
    _category = i?.category ?? GradeCategory.major;
    _period = i?.period ?? widget.defaultPeriod;
    _isAbiSubject = i?.isAbiSubject ?? false;
    _folderId = i?.folderId;
    _value = i?.value;
    _eventId = i?.eventId;
    _attachments = [...(i?.attachmentPaths ?? const [])];
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _addScan() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.document_scanner_outlined),
                  title: Text(l10n.scanPages),
                  subtitle: Text(l10n.scanPagesHint),
                  onTap: () => Navigator.pop(ctx, 'scanner'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: Text(l10n.scanWithCamera),
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: Text(l10n.scanFromGallery),
                  onTap: () => Navigator.pop(ctx, 'gallery'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    if (choice == 'scanner') {
      final paths = await const DocumentScannerService().scanPages();
      if (paths.isEmpty || !mounted) return;
      final imported = <String>[];
      for (final src in paths) {
        final stored = await _scans.importFromPath(src);
        if (stored != null) imported.add(stored);
      }
      if (imported.isEmpty || !mounted) return;
      setState(() => _attachments = [..._attachments, ...imported]);
      return;
    }
    final path = choice == 'camera'
        ? await _scans.pickFromCamera()
        : await _scans.pickFromGallery();
    if (path == null || !mounted) return;
    setState(() => _attachments = [..._attachments, path]);
  }

  Future<void> _pickPastEvent() async {
    if (_subject.trim().isEmpty) return;
    final planner = ref.read(plannerProvider);
    final choices = planner.pastEventsForSubject(_subject);
    if (choices.isEmpty) return;
    final selected = await showModalBottomSheet<PlannerEvent>(
      context: context,
      backgroundColor: AppTheme.paper,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final event in choices)
              ListTile(
                leading: Icon(
                  event.kind == PlannerEventKind.exam
                      ? Icons.assignment_rounded
                      : Icons.event_outlined,
                  color: Color(event.colorValue),
                ),
                title: Text(
                  event.title.trim().isEmpty
                      ? event.displaySubject
                      : event.title,
                ),
                subtitle: Text(DateFormat.yMMMd().format(event.start)),
                onTap: () => Navigator.pop(context, event),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _eventId = selected.id;
      _date = selected.start;
      _title.text = selected.title;
      _category = selected.kind == PlannerEventKind.exam
          ? GradeCategory.major
          : _category;
    });
  }

  Future<void> _openScan(String path) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(child: gradeScanThumbnail(path, size: 400)),
      ),
    );
  }

  Widget _scanStrip({required bool editable}) {
    final l10n = AppLocalizations.of(context)!;
    if (_attachments.isEmpty && !editable) {
      return Text(
        l10n.noScansAttached,
        style: AppTheme.body(
          fontWeight: FontWeight.w600,
          color: AppTheme.inkMuted,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _attachments.length; i++)
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openScan(_attachments[i]),
                child: gradeScanThumbnail(_attachments[i]),
              ),
              if (editable)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Material(
                    color: AppTheme.ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() {
                        _attachments = [
                          for (var j = 0; j < _attachments.length; j++)
                            if (j != i) _attachments[j],
                        ];
                      }),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (editable)
          ActionChip(
            avatar: const Icon(Icons.document_scanner_outlined),
            label: Text(l10n.scanAdd),
            onPressed: _addScan,
          ),
      ],
    );
  }

  Widget _viewMode({
    required EducationLevel editLevel,
    required SchoolYear editYear,
    required AppLocalizations l10n,
  }) {
    final gradeLabel = _value == null
        ? '—'
        : formatGradeValue(
            GradeEntry(
              id: _gradeId,
              value: _value,
              date: _date,
              scale: editLevel.defaultScale,
              subject: _subject,
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.gradeDetails,
                style: AppTheme.headline(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l10n.editMode),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_subject.isEmpty ? '—' : _subject} · ${editLevel.label(l10n)} · ${editYear.label}',
          style: AppTheme.body(
            fontWeight: FontWeight.w600,
            color: AppTheme.inkMuted,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            gradeLabel,
            style: AppTheme.headline(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
            ),
          ),
        ),
        if (editLevel != EducationLevel.university) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              _category == GradeCategory.major
                  ? editLevel.majorLabel(l10n)
                  : editLevel.minorLabel(l10n),
              style: AppTheme.body(
                fontWeight: FontWeight.w700,
                color: AppTheme.inkMuted,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (editLevel == EducationLevel.university) ...[
          GradeDetailRow(label: l10n.ectsLabel, value: '$_ects'),
          GradeDetailRow(
            label: l10n.semesterShort,
            value: (_semester == null || _semester!.isEmpty) ? '—' : _semester!,
          ),
        ],
        GradeDetailRow(
          label: l10n.gradeTitle,
          value: _title.text.trim().isEmpty ? '—' : _title.text.trim(),
        ),
        GradeDetailRow(
          label: l10n.startsAt,
          value: DateFormat.yMMMd().format(_date),
        ),
        if (_note.text.trim().isNotEmpty)
          GradeDetailRow(label: l10n.noteOptional, value: _note.text.trim()),
        const SizedBox(height: 8),
        Text(
          l10n.scanAttachment,
          style: AppTheme.body(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        _scanStrip(editable: false),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final table = ref.watch(timetableProvider);
    final level = ref.watch(settingsProvider).educationLevel;
    final editLevel =
        widget.initial?.resolvedLevel ?? widget.forcedLevel ?? level;
    final editYear =
        widget.initial?.schoolYear ?? widget.forcedYear ?? SchoolYear.current();
    final scale = editLevel.defaultScale;
    final lessons = table.distinctLessons();
    final periods = GradePeriodX.forLevel(editLevel);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final semesters = semesterChoicesFor(
      editYear,
      extras: [
        ?_semester,
        for (final g in ref.watch(plannerProvider).grades)
          if (g.matchesLevel(editLevel)) g.semesterLabel,
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: !_editing
            ? _viewMode(editLevel: editLevel, editYear: editYear, l10n: l10n)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.initial == null
                              ? l10n.addGrade
                              : l10n.editGrade,
                          style: AppTheme.headline(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      if (widget.initial != null)
                        TextButton(
                          onPressed: () => setState(() => _editing = false),
                          child: Text(l10n.viewMode),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${editLevel.label(l10n)} · ${editYear.label}',
                    style: AppTheme.body(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.subject,
                    style: AppTheme.body(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (lessons.isEmpty)
                    Text(
                      l10n.gradesNeedTimetable,
                      style: AppTheme.body(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkMuted,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final lesson in lessons)
                          ChoiceChip(
                            label: Text(
                              lesson.subject,
                              style: AppTheme.body(
                                fontWeight: FontWeight.w700,
                                color:
                                    subjectKey(_subject) ==
                                        subjectKey(lesson.subject)
                                    // Sits on the saturated subject colour.
                                    ? Colors.white
                                    : AppTheme.ink,
                              ),
                            ),
                            selected:
                                subjectKey(_subject) ==
                                subjectKey(lesson.subject),
                            selectedColor: Color(lesson.colorValue),
                            backgroundColor: AppTheme.card,
                            onSelected: (_) => setState(() {
                              _subject = lesson.subject;
                              _folderId = lesson.folderId;
                            }),
                          ),
                      ],
                    ),
                  if (_subject.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _pickPastEvent,
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: Text(l10n.choosePastEvent),
                    ),
                  ],
                  if (periods.length > 1) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in periods)
                          ChoiceChip(
                            label: Text(
                              periodLabel(p, l10n),
                              style: AppTheme.body(
                                fontWeight: FontWeight.w700,
                                color: _period == p
                                    ? AppTheme.onAccent
                                    : AppTheme.ink,
                              ),
                            ),
                            selected: _period == p,
                            selectedColor: AppTheme.accent,
                            onSelected: (_) => setState(() => _period = p),
                          ),
                      ],
                    ),
                  ],
                  if (editLevel != EducationLevel.university) ...[
                    const SizedBox(height: 14),
                    SegmentedButton<GradeCategory>(
                      segments: [
                        ButtonSegment(
                          value: GradeCategory.major,
                          label: Text(editLevel.majorLabel(l10n)),
                        ),
                        ButtonSegment(
                          value: GradeCategory.minor,
                          label: Text(editLevel.minorLabel(l10n)),
                        ),
                      ],
                      selected: {_category},
                      onSelectionChanged: (s) =>
                          setState(() => _category = s.first),
                    ),
                  ],
                  if (editLevel == EducationLevel.sek2) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.markAbiSubject,
                        style: AppTheme.body(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      value: _isAbiSubject,
                      onChanged: (v) => setState(() => _isAbiSubject = v),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (scale == GradeScale.german)
                    Sek1GradePicker(
                      value: _value,
                      onChanged: (v) => setState(() => _value = v),
                    )
                  else if (scale == GradeScale.points)
                    Sek2PointsPicker(
                      value: _value?.round(),
                      onChanged: (v) => setState(() => _value = v.toDouble()),
                    )
                  else
                    UniGradePicker(
                      value: _value,
                      onChanged: (v) => setState(() => _value = v),
                    ),
                  if (editLevel == EducationLevel.university) ...[
                    const SizedBox(height: 14),
                    Text(
                      l10n.ectsLabel,
                      style: AppTheme.body(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final e in ectsChoices)
                          ChoiceChip(
                            label: Text(
                              '$e',
                              style: AppTheme.body(
                                fontWeight: FontWeight.w700,
                                color: _ects == e
                                    ? AppTheme.onAccent
                                    : AppTheme.ink,
                              ),
                            ),
                            selected: _ects == e,
                            selectedColor: AppTheme.accent,
                            onSelected: (_) => setState(() => _ects = e),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.semesterShort,
                      style: AppTheme.body(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in semesters)
                          ChoiceChip(
                            label: Text(
                              s,
                              style: AppTheme.body(
                                fontWeight: FontWeight.w700,
                                color: _semester == s
                                    ? AppTheme.onAccent
                                    : AppTheme.ink,
                              ),
                            ),
                            selected: _semester == s,
                            selectedColor: AppTheme.accent,
                            onSelected: (_) => setState(() => _semester = s),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: l10n.gradeTitle,
                      hintText: l10n.gradeTitleHint,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.startsAt),
                    subtitle: Text(DateFormat.yMMMd().format(_date)),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                  ),
                  TextField(
                    controller: _note,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l10n.noteOptional),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.scanAttachment,
                    style: AppTheme.body(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.scanAttachmentHint,
                    style: AppTheme.body(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _scanStrip(editable: true),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (_subject.trim().isEmpty) return;
                      final committed = await _scans.commitForGrade(
                        gradeId: _gradeId,
                        paths: _attachments,
                      );
                      final base =
                          widget.initial ??
                          GradeEntry(
                            id: _gradeId,
                            value: _value,
                            date: _date,
                            scale: scale,
                            period: _period,
                            educationLevel: editLevel,
                            schoolYearStart: editYear.startYear,
                            eventId: _eventId,
                          );
                      final grade = base.copyWith(
                        value: _value,
                        date: _date,
                        folderId: _folderId,
                        clearFolder: _folderId == null,
                        subject: _subject.trim(),
                        title: _title.text.trim(),
                        note: _note.text.trim(),
                        scale: scale,
                        category: _category,
                        period: _period,
                        ects: editLevel == EducationLevel.university
                            ? _ects.toDouble()
                            : 0,
                        isAbiSubject:
                            editLevel == EducationLevel.sek2 && _isAbiSubject,
                        semesterLabel: _semester?.trim() ?? '',
                        educationLevel: editLevel,
                        attachmentPaths: committed,
                        schoolYearStart: editYear.startYear,
                        eventId: _eventId,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context, grade);
                    },
                    child: Text(l10n.save),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Back-compat alias used by older routes.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) => const GradesScreen();
}

/// Back-compat home card.
class PlannerHomeCard extends ConsumerWidget {
  const PlannerHomeCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LibrarySchoolRow(
      onTimetable: onOpen,
      onGrades: onOpen,
      onCalendar: onOpen,
    );
  }
}
