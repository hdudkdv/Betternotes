import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../timetable/timetable_model.dart';
import 'teacher_models.dart';

class LessonCalendarPage extends ConsumerStatefulWidget {
  const LessonCalendarPage({super.key});

  @override
  ConsumerState<LessonCalendarPage> createState() => _LessonCalendarPageState();
}

class _LessonCalendarPageState extends ConsumerState<LessonCalendarPage> {
  late DateTime _month;
  late DateTime _selectedDay;
  bool _ensuring = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDay());
  }

  Future<void> _ensureDay() async {
    if (_ensuring) return;
    _ensuring = true;
    try {
      await ref.read(teacherProvider.notifier).ensureLessonsForDay(
        _selectedDay,
        ref.read(timetableProvider),
      );
    } finally {
      _ensuring = false;
    }
  }

  Future<void> _selectDay(DateTime day) async {
    setState(() {
      _selectedDay = DateTime(day.year, day.month, day.day);
      _month = DateTime(day.year, day.month);
    });
    await _ensureDay();
  }

  Future<void> _editLesson(LessonJournalEntry lesson) async {
    final l10n = AppLocalizations.of(context)!;
    final title = TextEditingController(text: lesson.title);
    final description = TextEditingController(text: lesson.notes);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${lesson.periodLabel.isEmpty ? l10n.teacherPeriod(lesson.periodIndex + 1) : lesson.periodLabel}'
                ' · ${lesson.subject}',
                style: AppTheme.headline(fontSize: 20),
              ),
              if (lesson.room.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${l10n.room}: ${lesson.room}',
                  style: AppTheme.body(color: AppTheme.inkMuted),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: title,
                decoration: InputDecoration(labelText: l10n.title),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: l10n.description,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              if (lesson.attachments.isNotEmpty) ...[
                Text(
                  l10n.teacherLessonAttachments,
                  style: AppTheme.headline(fontSize: 16),
                ),
                const SizedBox(height: 8),
                for (final attachment in lesson.attachments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      attachment.kind == LessonAttachmentKind.whiteboard
                          ? Icons.draw_outlined
                          : Icons.attach_file_outlined,
                    ),
                    title: Text(attachment.title),
                    subtitle: Text(
                      DateFormat.Hm().format(attachment.createdAt),
                    ),
                    onTap: attachment.notebookId == null
                        ? null
                        : () {
                            Navigator.pop(context, false);
                            context.push(
                              '/notebook/${attachment.notebookId}'
                              '${attachment.pageId == null ? '' : '?pageId=${attachment.pageId}'}',
                            );
                          },
                  ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  if (lesson.status == LessonStatus.planned)
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context, false);
                        await ref
                            .read(teacherProvider.notifier)
                            .markLessonCancelledAndShift(lesson.id);
                      },
                      child: Text(l10n.teacherCancelAndShift),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;
    await ref.read(teacherProvider.notifier).updateLesson(
      lesson.copyWith(
        title: title.text.trim(),
        notes: description.text.trim(),
        status: LessonStatus.held,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lessons = ref.watch(teacherProvider).lessons;
    final dayLessons = [
      for (final lesson in lessons)
        if (lesson.scheduledAt.year == _selectedDay.year &&
            lesson.scheduledAt.month == _selectedDay.month &&
            lesson.scheduledAt.day == _selectedDay.day)
          lesson,
    ]..sort((a, b) {
      final byPeriod = a.periodIndex.compareTo(b.periodIndex);
      if (byPeriod != 0) return byPeriod;
      return (a.splitHalf ?? '').compareTo(b.splitHalf ?? '');
    });
    final daysWithEntries = <DateTime>{
      for (final lesson in lessons)
        DateTime(
          lesson.scheduledAt.year,
          lesson.scheduledAt.month,
          lesson.scheduledAt.day,
        ),
    };
    final weekend = Timetable.dayIndexFromWeekday(_selectedDay.weekday) == null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.teacherLessonCalendar,
          style: AppTheme.headline(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.teacherLessonCalendarHint,
          style: AppTheme.body(color: AppTheme.inkMuted),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month - 1);
                      }),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM().format(_month),
                        textAlign: TextAlign.center,
                        style: AppTheme.headline(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month + 1);
                      }),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MonthGrid(
                  month: _month,
                  selected: _selectedDay,
                  markedDays: daysWithEntries,
                  onSelect: _selectDay,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          DateFormat.yMMMEd().format(_selectedDay),
          style: AppTheme.headline(fontSize: 20),
        ),
        const SizedBox(height: 8),
        if (weekend)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              l10n.teacherNoSchoolDay,
              textAlign: TextAlign.center,
              style: AppTheme.body(color: AppTheme.inkMuted),
            ),
          )
        else if (dayLessons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              l10n.teacherNoLessonsForDay,
              textAlign: TextAlign.center,
              style: AppTheme.body(color: AppTheme.inkMuted),
            ),
          )
        else
          for (final lesson in dayLessons)
            Card(
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentSoft,
                  child: Text('${lesson.periodIndex + 1}'),
                ),
                title: Text(
                  lesson.title.isEmpty
                      ? lesson.subject
                      : '${lesson.subject}: ${lesson.title}',
                ),
                subtitle: Text(
                  [
                    if (lesson.periodLabel.isNotEmpty) lesson.periodLabel,
                    if (lesson.room.isNotEmpty) lesson.room,
                    if (lesson.notes.isNotEmpty) lesson.notes,
                    if (lesson.attachments.isNotEmpty)
                      l10n.teacherAttachmentCount(lesson.attachments.length),
                  ].join(' · '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: lesson.notes.isNotEmpty,
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editLesson(lesson),
              ),
            ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.markedDays,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Set<DateTime> markedDays;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = (first.weekday - DateTime.monday) % 7;
    final labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return Column(
      children: [
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: AppTheme.body(
                      fontSize: 12,
                      color: AppTheme.inkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < 6; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final dayNumber = row * 7 + col - startOffset + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox(height: 40);
                      }
                      final day = DateTime(month.year, month.month, dayNumber);
                      final isSelected = day == selected;
                      final marked = markedDays.contains(day);
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onSelect(day),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accent
                                  : marked
                                  ? AppTheme.accentSoft
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$dayNumber',
                              style: AppTheme.body(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppTheme.ink,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
