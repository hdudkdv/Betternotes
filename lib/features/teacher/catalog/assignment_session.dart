import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/content_models.dart';
import '../../../data/repositories/notebook_repository.dart';
import '../../lan_sync/lan_sync_controller.dart';
import '../../lan_sync/lan_sync_protocol.dart';
import '../../library/providers/library_providers.dart';
import '../../search/recognition/recognition_service.dart';
import '../../timetable/timetable_model.dart';
import '../teacher_models.dart';
import 'assignment_archive.dart';
import 'assignment_grader.dart';
import 'assignment_models.dart';
import 'catalog_models.dart';
import 'catalog_store.dart';

class AssignmentHostState extends Equatable {
  const AssignmentHostState({
    this.run,
    this.item,
    this.progress = const {},
    this.leaves = const [],
    this.summary,
    this.submissions = const [],
  });

  final AssignmentRun? run;
  final CatalogItem? item;
  final Map<String, AssignmentProgressSnapshot> progress;
  final List<AssignmentLeaveEvent> leaves;
  final AssignmentSummary? summary;
  final List<AssignmentSubmission> submissions;

  int get submittedCount =>
      progress.values.where((p) => p.submitted).length;

  double get liveAveragePercent {
    if (progress.isEmpty) return 0;
    final sum = progress.values.fold<int>(0, (s, p) => s + p.percent);
    return sum / progress.length;
  }

  AssignmentHostState copyWith({
    AssignmentRun? run,
    CatalogItem? item,
    Map<String, AssignmentProgressSnapshot>? progress,
    List<AssignmentLeaveEvent>? leaves,
    AssignmentSummary? summary,
    List<AssignmentSubmission>? submissions,
    bool clear = false,
  }) {
    if (clear) {
      return const AssignmentHostState();
    }
    return AssignmentHostState(
      run: run ?? this.run,
      item: item ?? this.item,
      progress: progress ?? this.progress,
      leaves: leaves ?? this.leaves,
      summary: summary ?? this.summary,
      submissions: submissions ?? this.submissions,
    );
  }

  @override
  List<Object?> get props => [run, item, progress, leaves, summary, submissions];
}

class AssignmentHostNotifier extends StateNotifier<AssignmentHostState> {
  AssignmentHostNotifier(this._ref) : super(const AssignmentHostState());

  final Ref _ref;
  static const _uuid = Uuid();
  static const _grader = RuleBasedAssignmentGrader();

  AssignmentArchive get _archive => AssignmentArchive(
    _ref.read(notebookRepositoryProvider),
    _ref.read(sharedPreferencesProvider),
  );

  Future<AssignmentRun?> start({
    required CatalogItem item,
    required int minutes,
    required bool testMode,
  }) async {
    final lan = _ref.read(lanSyncProvider);
    if (!lan.classroomMode || lan.role != LanSyncRole.host || !lan.isActive) {
      return null;
    }
    final now = DateTime.now();
    final run = AssignmentRun(
      id: _uuid.v4(),
      catalogItemId: item.id,
      title: item.title,
      subject: item.subject,
      schoolClass: item.schoolClass,
      startedAt: now,
      endsAt: now.add(Duration(minutes: minutes)),
      timeLimitSec: minutes * 60,
      testMode: testMode,
    );
    state = AssignmentHostState(run: run, item: item);
    await _archive.writeRun(run);
    final teacher = _ref.read(teacherProvider.notifier);
    await teacher.attachToCurrentLesson(
      timetable: _ref.read(timetableProvider),
      subject: _ref.read(teacherProvider).session?.subject,
      room: _ref.read(teacherProvider).session?.room,
      notebookId: _ref.read(teacherProvider).session?.notebookId,
      attachment: LessonAttachment(
        id: _uuid.v4(),
        kind: LessonAttachmentKind.assignment,
        title: item.title,
        createdAt: now,
        runId: run.id,
      ),
    );
    await lan.startAssignment({
      'runId': run.id,
      'title': item.title,
      'subject': item.subject,
      'schoolClass': item.schoolClass,
      'endsAt': run.endsAt.toIso8601String(),
      'timeLimitSec': run.timeLimitSec,
      'testMode': testMode,
      'allowImport': false,
      'tasks': [for (final task in item.tasks) task.toStudentJson()],
    });
    return run;
  }

  Future<void> extend(Duration extra) async {
    final run = state.run;
    if (run == null) return;
    final base = DateTime.now().isAfter(run.endsAt) ? DateTime.now() : run.endsAt;
    final next = run.copyWith(endsAt: base.add(extra));
    state = state.copyWith(run: next);
    await _archive.writeRun(next);
    await _ref.read(lanSyncProvider).extendAssignment(
      runId: next.id,
      endsAt: next.endsAt,
    );
  }

  Future<void> collect() async {
    final run = state.run;
    if (run == null) return;
    final next = run.copyWith(collected: true);
    state = state.copyWith(run: next);
    await _archive.writeRun(next);
    await _ref.read(lanSyncProvider).collectAssignment(next.id);
  }

  Future<void> allowImport() async {
    final run = state.run;
    if (run == null) return;
    final next = run.copyWith(allowImport: true);
    state = state.copyWith(run: next);
    await _archive.writeRun(next);
    await _ref.read(lanSyncProvider).allowAssignmentImport(next.id);
  }

  Future<void> returnCorrection({
    required String deviceId,
    required String text,
  }) async {
    final run = state.run;
    if (run == null) return;
    final submissions = [
      for (final sub in state.submissions)
        if (sub.deviceId == deviceId) sub.copyWith(correctionText: text) else sub,
    ];
    state = state.copyWith(submissions: submissions);
    final match = submissions.where((s) => s.deviceId == deviceId).firstOrNull;
    if (match != null) await _archive.writeSubmission(match);
    await _ref.read(lanSyncProvider).returnAssignmentCorrection(
      runId: run.id,
      targetDeviceId: deviceId,
      correctionText: text,
    );
  }

  Future<void> onLanEvent(LanAssignmentEvent event) async {
    final run = state.run;
    if (run == null) return;
    switch (event.type) {
      case 'assignment_progress':
        if (event.payload['runId'] != run.id) return;
        final deviceId = event.payload['deviceId']?.toString() ?? '';
        final snap = AssignmentProgressSnapshot(
          deviceId: deviceId,
          deviceName: event.payload['deviceName']?.toString() ?? '',
          percent: (event.payload['percent'] as num?)?.toInt() ?? 0,
          doneTaskIds: [
            for (final id in event.payload['doneTaskIds'] as List? ?? const [])
              id.toString(),
          ],
          submitted: state.progress[deviceId]?.submitted ?? false,
        );
        state = state.copyWith(
          progress: {...state.progress, deviceId: snap},
        );
        await _ref.read(teacherProvider.notifier).applyNetworkSignal(
          deviceId: deviceId,
          deviceName: snap.deviceName,
          kind: 'progress',
          value: snap.percent,
        );
      case 'assignment_submit':
        await _acceptSubmission(event.payload);
      case 'assignment_leave':
        if (event.payload['runId'] != run.id) return;
        state = state.copyWith(
          leaves: [
            ...state.leaves,
            AssignmentLeaveEvent(
              deviceId: event.payload['deviceId']?.toString() ?? '',
              deviceName: event.payload['deviceName']?.toString() ?? '',
              at: DateTime.now(),
              kind: event.payload['kind']?.toString() ?? 'pause',
            ),
          ],
        );
        await _ref.read(teacherProvider.notifier).applyNetworkSignal(
          deviceId: event.payload['deviceId']?.toString() ?? '',
          deviceName: event.payload['deviceName']?.toString() ?? '',
          kind: 'left',
        );
    }
  }

  Future<void> _acceptSubmission(Map<String, dynamic> payload) async {
    final run = state.run;
    final item = state.item;
    if (run == null || item == null) return;
    if (payload['runId'] != run.id) return;
    var submission = AssignmentSubmission.fromJson(payload);
    final grades = await _grader.grade(item: item, submission: submission);
    submission = submission.copyWith(grades: grades);
    await _archive.writeSubmission(submission);
    await _archive.indexSubmission(submission);
    final submissions = [
      for (final existing in state.submissions)
        if (existing.deviceId != submission.deviceId) existing,
      submission,
    ];
    final progress = Map<String, AssignmentProgressSnapshot>.from(state.progress);
    progress[submission.deviceId] = AssignmentProgressSnapshot(
      deviceId: submission.deviceId,
      deviceName: submission.deviceName,
      percent: 100,
      doneTaskIds: submission.doneTaskIds,
      submitted: true,
    );
    final participants = _ref.read(teacherProvider).session?.participants.length ??
        progress.length;
    final summary = buildAssignmentSummary(
      run: run,
      item: item,
      submissions: submissions,
      participantCount: participants,
    );
    await _archive.writeSummary(summary);
    state = state.copyWith(
      submissions: submissions,
      progress: progress,
      summary: summary,
    );
  }

  Future<void> loadRun(String runId) async {
    final archive = _archive;
    final run = await archive.readRun(runId);
    if (run == null) return;
    final item = _ref.read(catalogProvider.notifier).byId(run.catalogItemId);
    final submissions = await archive.readSubmissions(runId);
    final summary = await archive.readSummary(runId);
    state = AssignmentHostState(
      run: run,
      item: item,
      submissions: submissions,
      summary: summary,
      progress: {
        for (final sub in submissions)
          sub.deviceId: AssignmentProgressSnapshot(
            deviceId: sub.deviceId,
            deviceName: sub.deviceName,
            percent: 100,
            doneTaskIds: sub.doneTaskIds,
            submitted: true,
          ),
      },
    );
  }
}

class StudentAssignmentState extends Equatable {
  const StudentAssignmentState({
    this.runId,
    this.title = '',
    this.tasks = const [],
    this.answers = const {},
    this.doneTaskIds = const {},
    this.endsAt,
    this.testMode = false,
    this.allowImport = false,
    this.submitted = false,
    this.collected = false,
    this.correctionText = '',
  });

  final String? runId;
  final String title;
  final List<CatalogTask> tasks;
  final Map<String, StudentTaskAnswer> answers;
  final Set<String> doneTaskIds;
  final DateTime? endsAt;
  final bool testMode;
  final bool allowImport;
  final bool submitted;
  final bool collected;
  final String correctionText;

  bool get active => runId != null && runId!.isNotEmpty;

  bool get expired => endsAt != null && DateTime.now().isAfter(endsAt!);

  bool get locked => submitted || collected || (expired && !submitted);

  bool get canWrite => active && !locked;

  int get percent {
    if (tasks.isEmpty) return 0;
    return ((doneTaskIds.length / tasks.length) * 100).round();
  }

  StudentAssignmentState copyWith({
    String? runId,
    String? title,
    List<CatalogTask>? tasks,
    Map<String, StudentTaskAnswer>? answers,
    Set<String>? doneTaskIds,
    DateTime? endsAt,
    bool? testMode,
    bool? allowImport,
    bool? submitted,
    bool? collected,
    String? correctionText,
    bool clear = false,
  }) {
    if (clear) return const StudentAssignmentState();
    return StudentAssignmentState(
      runId: runId ?? this.runId,
      title: title ?? this.title,
      tasks: tasks ?? this.tasks,
      answers: answers ?? this.answers,
      doneTaskIds: doneTaskIds ?? this.doneTaskIds,
      endsAt: endsAt ?? this.endsAt,
      testMode: testMode ?? this.testMode,
      allowImport: allowImport ?? this.allowImport,
      submitted: submitted ?? this.submitted,
      collected: collected ?? this.collected,
      correctionText: correctionText ?? this.correctionText,
    );
  }

  @override
  List<Object?> get props => [
    runId,
    title,
    tasks,
    answers,
    doneTaskIds,
    endsAt,
    testMode,
    allowImport,
    submitted,
    collected,
    correctionText,
  ];
}

class StudentAssignmentNotifier extends StateNotifier<StudentAssignmentState> {
  StudentAssignmentNotifier(this._ref) : super(const StudentAssignmentState());

  final Ref _ref;

  void onLanEvent(LanAssignmentEvent event) {
    switch (event.type) {
      case 'assignment_start':
        final tasks = [
          for (final item in event.payload['tasks'] as List? ?? const [])
            CatalogTask.fromStudentJson(Map<String, dynamic>.from(item as Map)),
        ];
        state = StudentAssignmentState(
          runId: event.payload['runId']?.toString(),
          title: event.payload['title']?.toString() ?? '',
          tasks: tasks,
          endsAt: DateTime.tryParse(event.payload['endsAt']?.toString() ?? ''),
          testMode: event.payload['testMode'] as bool? ?? false,
          allowImport: event.payload['allowImport'] as bool? ?? false,
        );
      case 'assignment_extend':
        if (event.payload['runId'] != state.runId) return;
        if (state.submitted) return;
        state = state.copyWith(
          endsAt: DateTime.tryParse(event.payload['endsAt']?.toString() ?? ''),
          collected: false,
        );
      case 'assignment_collect':
        if (event.payload['runId'] != state.runId) return;
        state = state.copyWith(collected: true);
      case 'assignment_allow_import':
        if (event.payload['runId'] != state.runId) return;
        state = state.copyWith(allowImport: true);
      case 'assignment_return':
        if (event.payload['runId'] != state.runId) return;
        state = state.copyWith(
          correctionText: event.payload['correctionText']?.toString() ?? '',
        );
    }
  }

  void setAnswer(StudentTaskAnswer answer) {
    if (!state.canWrite) return;
    state = state.copyWith(answers: {...state.answers, answer.taskId: answer});
  }

  void toggleDone(String taskId) {
    if (!state.canWrite) return;
    final next = {...state.doneTaskIds};
    if (!next.add(taskId)) next.remove(taskId);
    final answers = Map<String, StudentTaskAnswer>.from(state.answers);
    final current = answers[taskId] ?? StudentTaskAnswer(taskId: taskId);
    answers[taskId] = current.copyWith(done: next.contains(taskId));
    state = state.copyWith(doneTaskIds: next, answers: answers);
  }

  Future<void> sendProgress() async {
    final runId = state.runId;
    if (runId == null || state.submitted) return;
    await _ref.read(lanSyncProvider).sendAssignmentProgress(
      runId: runId,
      percent: state.percent,
      doneTaskIds: state.doneTaskIds.toList(),
    );
  }

  Future<void> submit({bool early = true}) async {
    final runId = state.runId;
    if (runId == null || state.submitted) return;
    final lan = _ref.read(lanSyncProvider);
    final ocr = StringBuffer();
    for (final task in state.tasks) {
      for (final part in task.parts) {
        if (part.kind == TaskPartKind.image && part.imagePath != null) {
          try {
            final text = await RecognitionService.instance.recognizeImagePath(
              part.imagePath!,
            );
            if (text.trim().isNotEmpty) ocr.writeln(text);
          } catch (_) {}
        }
      }
      final answer = state.answers[task.id];
      if (answer != null && answer.text.trim().isNotEmpty) {
        ocr.writeln(answer.text);
      }
    }
    final submission = AssignmentSubmission(
      deviceId: lan.deviceId,
      deviceName: lan.deviceName,
      runId: runId,
      submittedAt: DateTime.now(),
      answers: [
        for (final task in state.tasks)
          state.answers[task.id] ?? StudentTaskAnswer(taskId: task.id),
      ],
      doneTaskIds: state.doneTaskIds.toList(),
      ocrText: ocr.toString().trim(),
      early: early,
    );
    await lan.sendAssignmentSubmit(submission.toJson());
    state = state.copyWith(submitted: true);
  }

  Future<void> leave(String kind) async {
    final runId = state.runId;
    if (runId == null || !state.testMode || state.submitted) return;
    await _ref.read(lanSyncProvider).sendAssignmentLeave(runId, kind);
  }

  Future<void> importIntoNotebook(String notebookId) async {
    if (!state.allowImport) return;
    final repo = _ref.read(notebookRepositoryProvider);
    final pages = await repo.addPages(
      notebookId: notebookId,
      drafts: const [NotePageDraft()],
    );
    if (pages.isEmpty) return;
    final page = pages.first;
    final text = [
      state.title,
      for (var i = 0; i < state.tasks.length; i++)
        '${i + 1}. ${state.tasks[i].title}\n${[
          for (final part in state.tasks[i].parts)
            if (part.kind == TaskPartKind.text) part.text,
        ].join('\n')}',
    ].join('\n\n');
    final block = TextBlock(
      id: const Uuid().v4(),
      pageId: page.id,
      x: 36,
      y: 36,
      width: 520,
      height: 720,
      layoutMode: TextLayoutMode.free,
      spans: [TextSpanStyle(text: text)],
    );
    await repo.savePage(page.copyWith(textBlocks: [block]));
  }
}

final assignmentArchiveProvider = Provider<AssignmentArchive>((ref) {
  return AssignmentArchive(
    ref.watch(notebookRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final assignmentHostProvider =
    StateNotifierProvider<AssignmentHostNotifier, AssignmentHostState>((ref) {
      return AssignmentHostNotifier(ref);
    });

final studentAssignmentProvider =
    StateNotifierProvider<StudentAssignmentNotifier, StudentAssignmentState>((
      ref,
    ) {
      return StudentAssignmentNotifier(ref);
    });
