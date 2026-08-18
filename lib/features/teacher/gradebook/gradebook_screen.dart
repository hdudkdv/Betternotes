import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../planner/school_year.dart';
import '../../timetable/timetable_model.dart';
import 'gradebook_models.dart';
import 'gradebook_store.dart';
import 'notenspiegel_stats.dart';
import '../picker/random_picker_panel.dart';

class GradebookScreen extends ConsumerStatefulWidget {
  const GradebookScreen({super.key, this.initialClass});

  final String? initialClass;

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen> {
  String? _classId;
  String? _topicId;
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = SchoolYear.current().startYear;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncClasses());
  }

  Future<void> _syncClasses() async {
    final tables = ref.read(timetableCatalogProvider);
    final names = {
      for (final table in tables)
        if (table.hasClass) table.classLabel,
      if ((widget.initialClass ?? '').trim().isNotEmpty)
        widget.initialClass!.trim(),
    };
    if (names.isNotEmpty) {
      await ref.read(gradebookProvider.notifier).ensureClasses(names);
    }
    if (!mounted) return;
    final updated = ref.read(gradebookProvider);
    final wanted = (widget.initialClass ?? '').trim();
    setState(() {
      _classId =
          updated.classByName(wanted)?.id ??
          (_classId != null && updated.classById(_classId!) != null
              ? _classId
              : (updated.classes.isNotEmpty ? updated.classes.first.id : null));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final book = ref.watch(gradebookProvider);

    final roster = _classId == null ? null : book.classById(_classId!);
    final topics = [
      for (final topic in book.topics)
        if (topic.classId == _classId && topic.schoolYearStart == _year) topic,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (_topicId != null && topics.every((t) => t.id != _topicId)) {
      _topicId = null;
    }

    final histogram = roster == null
        ? const GradeHistogram(counts: [0, 0, 0, 0, 0, 0, 0], total: 0)
        : classHistogram(
            book: book,
            classId: roster.id,
            schoolYearStart: _year,
            topicId: _topicId,
          );
    final trend = roster == null
        ? const <AssessmentTrendPoint>[]
        : classTrend(
            book: book,
            classId: roster.id,
            schoolYearStart: _year,
            topicId: _topicId,
          );
    final topicsPerf = roster == null
        ? const <TopicPerformance>[]
        : topicPerformances(
            book: book,
            classId: roster.id,
            schoolYearStart: _year,
          );
    final years = availableSchoolYears(book, classId: roster?.id);
    final locale = Localizations.localeOf(context).toString();
    final avgFormat = NumberFormat('0.0', locale);
    final dateFormat = DateFormat.MMMd(locale);

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(l10n.teacherGradeReport, style: AppTheme.headline()),
        actions: [
          IconButton(
            tooltip: l10n.timetable,
            onPressed: () => context.push('/timetable'),
            icon: const Icon(Icons.calendar_view_week_outlined),
          ),
        ],
      ),
      floatingActionButton: roster == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addAssessment(roster, topics),
              icon: const Icon(Icons.add_chart_outlined),
              label: Text(l10n.teacherGradeNewAssessment),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            l10n.teacherGradeReportOverviewHint,
            style: AppTheme.body(color: AppTheme.inkMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
          _FilterBar(
            book: book,
            classId: _classId,
            year: _year,
            years: years,
            onClass: (id) => setState(() {
              _classId = id;
              _topicId = null;
            }),
            onYear: (year) => setState(() {
              _year = year;
              _topicId = null;
            }),
            onAddClass: _addClass,
          ),
          if (roster == null) ...[
            const SizedBox(height: 28),
            Text(
              l10n.teacherGradeNoClass,
              style: AppTheme.body(color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _addClass,
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.timetableNewClass),
            ),
          ] else ...[
            const SizedBox(height: 12),
            _TopicChips(
              topics: topics,
              selectedId: _topicId,
              onSelect: (id) => setState(() => _topicId = id),
              onAdd: () => _addTopic(roster),
            ),
            const SizedBox(height: 16),
            RandomPickerPanel(initialClassName: roster.name),
            const SizedBox(height: 16),
            _NotenspiegelCard(
              histogram: histogram,
              averageLabel: histogram.average == null
                  ? l10n.teacherNoGrades
                  : l10n.teacherGradeAverageValue(
                      avgFormat.format(histogram.average),
                    ),
              countLabel: l10n.teacherGradeCount(histogram.total),
            ),
            const SizedBox(height: 16),
            _TrendCard(
              points: trend,
              dateFormat: dateFormat,
              avgFormat: avgFormat,
              topics: {for (final t in topics) t.id: t.name},
              onOpen: (point) => _editAssessment(roster, point.assessment),
            ),
            const SizedBox(height: 16),
            _TopicsCard(
              items: topicsPerf,
              avgFormat: avgFormat,
              onSelect: (id) => setState(() => _topicId = id),
            ),
            const SizedBox(height: 16),
            _RosterCard(
              roster: roster,
              book: book,
              year: _year,
              topicId: _topicId,
              avgFormat: avgFormat,
              onAdd: () => _addStudent(roster),
              onGroups: () => showClassGroupsSheet(context, ref, roster),
              onRemove: (id) => ref
                  .read(gradebookProvider.notifier)
                  .removeStudent(roster.id, id),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addClass() async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _promptText(
      title: l10n.timetableNewClass,
      hint: l10n.timetableClassHint,
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(timetableProvider.notifier).addClassPlan(name);
    final roster = await ref.read(gradebookProvider.notifier).ensureClass(name);
    if (!mounted) return;
    setState(() {
      _classId = roster.id;
      _topicId = null;
    });
  }

  Future<void> _addStudent(TeacherClassRoster roster) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _promptText(
      title: l10n.teacherGradeAddStudent,
      hint: l10n.teacherGradeStudentHint,
    );
    if (name == null) return;
    await ref.read(gradebookProvider.notifier).addStudent(roster.id, name);
  }

  Future<void> _addTopic(TeacherClassRoster roster) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _promptText(
      title: l10n.teacherGradeNewTopic,
      hint: l10n.teacherGradeTopicHint,
    );
    if (name == null) return;
    final topic = await ref
        .read(gradebookProvider.notifier)
        .addTopic(classId: roster.id, name: name, schoolYearStart: _year);
    if (!mounted) return;
    setState(() => _topicId = topic.id);
  }

  Future<void> _addAssessment(
    TeacherClassRoster roster,
    List<ClassTopic> topics,
  ) async {
    var available = topics;
    if (available.isEmpty) {
      await _addTopic(roster);
      if (!mounted) return;
      available = [
        for (final topic in ref.read(gradebookProvider).topics)
          if (topic.classId == roster.id && topic.schoolYearStart == _year)
            topic,
      ];
      if (available.isEmpty) return;
    }
    if (!mounted) return;
    final result = await showModalBottomSheet<_NewAssessment>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NewAssessmentSheet(
        topics: available,
        initialTopicId: _topicId ?? available.first.id,
      ),
    );
    if (result == null || !mounted) return;
    final assessment = await ref
        .read(gradebookProvider.notifier)
        .addAssessment(
          classId: roster.id,
          topicId: result.topicId,
          title: result.title,
          date: result.date,
        );
    if (!mounted) return;
    setState(() => _topicId = result.topicId);
    await _editAssessment(roster, assessment);
  }

  Future<void> _editAssessment(
    TeacherClassRoster roster,
    ClassAssessment assessment,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _GradeEntrySheet(
        roster: roster,
        assessment: assessment,
      ),
    );
    if (saved == true && mounted) {
      final book = ref.read(gradebookProvider);
      final hist = classHistogram(
        book: book,
        classId: roster.id,
        schoolYearStart: assessment.schoolYearStart,
        assessmentId: assessment.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _NotenspiegelDialog(
          title: assessment.title,
          histogram: hist,
        ),
      );
    }
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
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
    final value = controller.text.trim();
    controller.dispose();
    if (ok == true && value.isNotEmpty) return value;
    return null;
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.book,
    required this.classId,
    required this.year,
    required this.years,
    required this.onClass,
    required this.onYear,
    required this.onAddClass,
  });

  final TeacherGradebook book;
  final String? classId;
  final int year;
  final List<int> years;
  final ValueChanged<String> onClass;
  final ValueChanged<int> onYear;
  final VoidCallback onAddClass;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (book.classes.isNotEmpty)
          DropdownButton<String>(
            value: classId != null && book.classById(classId!) != null
                ? classId
                : book.classes.first.id,
            borderRadius: BorderRadius.circular(12),
            items: [
              for (final item in book.classes)
                DropdownMenuItem(value: item.id, child: Text(item.name)),
            ],
            onChanged: (value) {
              if (value != null) onClass(value);
            },
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.timetableNewClass),
          onPressed: onAddClass,
        ),
        DropdownButton<int>(
          value: years.contains(year) ? year : SchoolYear.current().startYear,
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final start in years)
              DropdownMenuItem(
                value: start,
                child: Text(SchoolYear(start).label),
              ),
          ],
          onChanged: (value) {
            if (value != null) onYear(value);
          },
        ),
      ],
    );
  }
}

class _TopicChips extends StatelessWidget {
  const _TopicChips({
    required this.topics,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  final List<ClassTopic> topics;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          selected: selectedId == null,
          label: Text(l10n.teacherGradeAllTopics),
          onSelected: (_) => onSelect(null),
        ),
        for (final topic in topics)
          FilterChip(
            selected: selectedId == topic.id,
            label: Text(topic.name),
            onSelected: (_) => onSelect(topic.id),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.teacherGradeNewTopic),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _NotenspiegelCard extends StatelessWidget {
  const _NotenspiegelCard({
    required this.histogram,
    required this.averageLabel,
    required this.countLabel,
  });

  final GradeHistogram histogram;
  final String averageLabel;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teacherGradeReport,
              style: AppTheme.headline(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '$averageLabel · $countLabel',
              style: AppTheme.body(color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: NotenspiegelBars(histogram: histogram),
            ),
          ],
        ),
      ),
    );
  }
}

class NotenspiegelBars extends StatelessWidget {
  const NotenspiegelBars({super.key, required this.histogram});

  final GradeHistogram histogram;

  @override
  Widget build(BuildContext context) {
    final maxCount = [
      for (var g = 1; g <= 6; g++) histogram.countFor(g),
    ].fold<int>(1, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var grade = 1; grade <= 6; grade++) ...[
          if (grade > 1) const SizedBox(width: 8),
          Expanded(
            child: _GradeBar(
              grade: grade,
              count: histogram.countFor(grade),
              maxCount: maxCount,
            ),
          ),
        ],
      ],
    );
  }
}

class _GradeBar extends StatelessWidget {
  const _GradeBar({
    required this.grade,
    required this.count,
    required this.maxCount,
  });

  final int grade;
  final int count;
  final int maxCount;

  Color get _color {
    if (grade <= 2) return const Color(0xFF0F6E56);
    if (grade <= 4) return const Color(0xFFB45309);
    return const Color(0xFF9F1239);
  }

  @override
  Widget build(BuildContext context) {
    final t = maxCount <= 0 ? 0.0 : count / maxCount;
    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: count == 0 ? 0.04 : t.clamp(0.08, 1),
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: count == 0 ? 0.18 : 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$grade',
          style: AppTheme.body(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        Text(
          '$count',
          style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.points,
    required this.dateFormat,
    required this.avgFormat,
    required this.topics,
    required this.onOpen,
  });

  final List<AssessmentTrendPoint> points;
  final DateFormat dateFormat;
  final NumberFormat avgFormat;
  final Map<String, String> topics;
  final ValueChanged<AssessmentTrendPoint> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teacherGradeTrend,
              style: AppTheme.headline(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.teacherGradeTrendHint,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
            ),
            if (points.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.teacherNoAssessments,
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
            ] else ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: _TrendSparkline(
                  values: [for (final p in points) p.average],
                ),
              ),
              const SizedBox(height: 8),
              for (final point in points)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(point.assessment.title),
                  subtitle: Text(
                    [
                      dateFormat.format(point.assessment.date),
                      if (topics[point.assessment.topicId] != null)
                        topics[point.assessment.topicId]!,
                    ].join(' · '),
                  ),
                  trailing: Text(
                    avgFormat.format(point.average),
                    style: AppTheme.headline(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => onOpen(point),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendSparkline extends StatelessWidget {
  const _TrendSparkline({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        color: AppTheme.accent,
        track: AppTheme.outline.withValues(alpha: 0.4),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.track,
  });

  final List<double> values;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = 1;
    for (var g = 1; g <= 6; g++) {
      final y = size.height * ((g - 1) / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), trackPaint);
    }
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * (i / (values.length - 1));
      final y = size.height * ((values[i] - 1) / 5).clamp(0.0, 1.0);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values;
}

class _TopicsCard extends StatelessWidget {
  const _TopicsCard({
    required this.items,
    required this.avgFormat,
    required this.onSelect,
  });

  final List<TopicPerformance> items;
  final NumberFormat avgFormat;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teacherGradeTopicAverages,
              style: AppTheme.headline(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.teacherGradeTopicAveragesHint,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
            ),
            if (items.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.teacherNoAssessments,
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
            ] else
              for (final item in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.topic.name),
                  subtitle: Text(
                    l10n.teacherGradeCount(item.histogram.total),
                  ),
                  trailing: Text(
                    item.histogram.average == null
                        ? '–'
                        : avgFormat.format(item.histogram.average),
                    style: AppTheme.headline(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => onSelect(item.topic.id),
                ),
          ],
        ),
      ),
    );
  }
}

class _RosterCard extends StatelessWidget {
  const _RosterCard({
    required this.roster,
    required this.book,
    required this.year,
    required this.topicId,
    required this.avgFormat,
    required this.onAdd,
    required this.onGroups,
    required this.onRemove,
  });

  final TeacherClassRoster roster;
  final TeacherGradebook book;
  final int year;
  final String? topicId;
  final NumberFormat avgFormat;
  final VoidCallback onAdd;
  final VoidCallback onGroups;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.teacherGradeRoster,
                    style: AppTheme.headline(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onGroups,
                  icon: const Icon(Icons.groups_outlined),
                  label: Text(l10n.teacherPickerGroups),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(l10n.teacherGradeAddStudent),
                ),
              ],
            ),
            if (roster.students.isEmpty)
              Text(
                l10n.teacherGradeRosterEmpty,
                style: AppTheme.body(color: AppTheme.inkMuted),
              )
            else
              for (final student in roster.students)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(student.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        () {
                          final avg = studentAverage(
                            book: book,
                            studentId: student.id,
                            classId: roster.id,
                            schoolYearStart: year,
                            topicId: topicId,
                          );
                          return avg == null ? '–' : avgFormat.format(avg);
                        }(),
                        style: AppTheme.headline(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.delete,
                        onPressed: () => onRemove(student.id),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _NewAssessment {
  const _NewAssessment({
    required this.title,
    required this.topicId,
    required this.date,
  });

  final String title;
  final String topicId;
  final DateTime date;
}

class _NewAssessmentSheet extends StatefulWidget {
  const _NewAssessmentSheet({
    required this.topics,
    required this.initialTopicId,
  });

  final List<ClassTopic> topics;
  final String initialTopicId;

  @override
  State<_NewAssessmentSheet> createState() => _NewAssessmentSheetState();
}

class _NewAssessmentSheetState extends State<_NewAssessmentSheet> {
  late final TextEditingController _title;
  late String _topicId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _topicId = widget.initialTopicId;
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.teacherGradeNewAssessment,
            style: AppTheme.headline(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.teacherGradeAssessmentTitle,
              hintText: l10n.teacherGradeAssessmentHint,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _topicId,
            decoration: InputDecoration(labelText: l10n.teacherGradeTopic),
            items: [
              for (final topic in widget.topics)
                DropdownMenuItem(value: topic.id, child: Text(topic.name)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _topicId = value);
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.teacherGradeDate),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.event_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(_date.year - 2),
                lastDate: DateTime(_date.year + 1),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          FilledButton(
            onPressed: () {
              final title = _title.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(
                context,
                _NewAssessment(title: title, topicId: _topicId, date: _date),
              );
            },
            child: Text(l10n.teacherGradeEnterGrades),
          ),
        ],
      ),
    );
  }
}

class _GradeEntrySheet extends ConsumerStatefulWidget {
  const _GradeEntrySheet({
    required this.roster,
    required this.assessment,
  });

  final TeacherClassRoster roster;
  final ClassAssessment assessment;

  @override
  ConsumerState<_GradeEntrySheet> createState() => _GradeEntrySheetState();
}

class _GradeEntrySheetState extends ConsumerState<_GradeEntrySheet> {
  late Map<String, int?> _values;

  @override
  void initState() {
    super.initState();
    _values = Map<String, int?>.from(
      ref.read(gradebookProvider.notifier).gradesForAssessment(
        widget.assessment.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final students = widget.roster.students;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        children: [
          Text(
            widget.assessment.title,
            style: AppTheme.headline(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.teacherGradeEntryHint,
            style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: students.isEmpty
                ? Center(child: Text(l10n.teacherGradeRosterEmpty))
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final selected = _values[student.id];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: AppTheme.body(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                for (var grade = 1; grade <= 6; grade++)
                                  ChoiceChip(
                                    label: Text('$grade'),
                                    selected: selected == grade,
                                    onSelected: (on) {
                                      setState(() {
                                        _values[student.id] = on ? grade : null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await ref
                      .read(gradebookProvider.notifier)
                      .deleteAssessment(widget.assessment.id);
                  if (context.mounted) Navigator.pop(context, false);
                },
                child: Text(l10n.delete),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref.read(gradebookProvider.notifier).setGrades(
                    assessmentId: widget.assessment.id,
                    values: _values,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                },
                child: Text(l10n.teacherGradeShowMirror),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _NotenspiegelDialog extends StatelessWidget {
  const _NotenspiegelDialog({
    required this.title,
    required this.histogram,
  });

  final String title;
  final GradeHistogram histogram;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final avg = histogram.average == null
        ? '–'
        : NumberFormat('0.0', locale).format(histogram.average);
    return AlertDialog(
      title: Text(l10n.teacherGradeReport),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.body(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${l10n.teacherClassAverage}: $avg · ${l10n.teacherGradeCount(histogram.total)}',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: NotenspiegelBars(histogram: histogram),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
