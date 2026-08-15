import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../library/providers/library_providers.dart';
import 'assignment_models.dart';
import 'assignment_session.dart';
import 'catalog_image.dart';
import 'catalog_models.dart';

class AssignmentPage extends ConsumerStatefulWidget {
  const AssignmentPage({super.key, required this.runId});

  final String runId;

  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends ConsumerState<AssignmentPage>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _progressTimer = Timer.periodic(const Duration(seconds: 18), (_) {
      unawaited(ref.read(studentAssignmentProvider.notifier).sendProgress());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _progressTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final assignment = ref.read(studentAssignmentProvider);
    if (!assignment.active || !assignment.testMode) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(ref.read(studentAssignmentProvider.notifier).leave('pause'));
    }
  }

  String _clock(DateTime? endsAt) {
    if (endsAt == null) return '--:--';
    final left = endsAt.difference(DateTime.now());
    if (left.isNegative) return '0:00';
    final m = left.inMinutes;
    final s = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(studentAssignmentProvider.select((s) => s.collected), (
      previous,
      collected,
    ) {
      if (collected == true &&
          previous != true &&
          !ref.read(studentAssignmentProvider).submitted) {
        unawaited(ref.read(studentAssignmentProvider.notifier).submit(early: false));
      }
    });
    final state = ref.watch(studentAssignmentProvider);
    if (!state.active) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.assignmentTitle)),
        body: Center(child: Text(l10n.assignmentWaiting)),
      );
    }
    return PopScope(
      canPop: !state.testMode || state.submitted,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.testMode && !state.submitted) {
          unawaited(ref.read(studentAssignmentProvider.notifier).leave('home'));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.title.isEmpty ? l10n.assignmentTitle : state.title),
          leading: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                _clock(state.endsAt),
                style: AppTheme.headline(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          leadingWidth: 88,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (state.correctionText.isNotEmpty)
              Card(
                color: AppTheme.accentSoft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(state.correctionText),
                ),
              ),
            if (state.locked)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  state.submitted
                      ? l10n.assignmentSubmitted
                      : l10n.assignmentLocked,
                  style: AppTheme.body(color: AppTheme.inkMuted),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < state.tasks.length; i++)
                  FilterChip(
                    selected: state.doneTaskIds.contains(state.tasks[i].id),
                    label: Text(l10n.teacherTaskNumber(i + 1)),
                    onSelected: state.canWrite
                        ? (_) {
                            ref
                                .read(studentAssignmentProvider.notifier)
                                .toggleDone(state.tasks[i].id);
                            unawaited(
                              ref
                                  .read(studentAssignmentProvider.notifier)
                                  .sendProgress(),
                            );
                          }
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < state.tasks.length; i++)
              _StudentTaskCard(
                index: i,
                task: state.tasks[i],
                answer:
                    state.answers[state.tasks[i].id] ??
                    StudentTaskAnswer(taskId: state.tasks[i].id),
                locked: !state.canWrite,
                onChanged: (answer) => ref
                    .read(studentAssignmentProvider.notifier)
                    .setAnswer(answer),
              ),
            const SizedBox(height: 16),
            if (!state.submitted)
              FilledButton.icon(
                onPressed: () async {
                  await ref
                      .read(studentAssignmentProvider.notifier)
                      .submit(early: !state.expired && !state.collected);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(l10n.assignmentSubmit),
              ),
            if (state.allowImport) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _import(context),
                icon: const Icon(Icons.auto_stories_outlined),
                label: Text(l10n.assignmentImportNotebook),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final notebooks = await ref.read(notebookRepositoryProvider).getNotebooks();
    if (!context.mounted) return;
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final notebook in notebooks)
            ListTile(
              title: Text(notebook.title),
              onTap: () => Navigator.pop(context, notebook.id),
            ),
        ],
      ),
    );
    if (id == null) return;
    await ref.read(studentAssignmentProvider.notifier).importIntoNotebook(id);
    if (context.mounted) context.go('/notebook/$id');
  }
}

class _StudentTaskCard extends StatelessWidget {
  const _StudentTaskCard({
    required this.index,
    required this.task,
    required this.answer,
    required this.locked,
    required this.onChanged,
  });

  final int index;
  final CatalogTask task;
  final StudentTaskAnswer answer;
  final bool locked;
  final ValueChanged<StudentTaskAnswer> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: AppTheme.paperDeep,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${task.title}',
              style: AppTheme.headline(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final part in task.parts) ...[
              if (part.kind == TaskPartKind.text && part.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(part.text),
                ),
              if (part.kind == TaskPartKind.link && part.url.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(part.url, style: AppTheme.body(color: AppTheme.accent)),
                ),
              if (part.kind == TaskPartKind.image &&
                  part.imagePath != null &&
                  part.imagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CatalogImage(path: part.imagePath!),
                ),
            ],
            if (task.answerKind == AnswerKind.text ||
                task.answerKind == AnswerKind.calculation)
              TextFormField(
                initialValue: task.answerKind == AnswerKind.calculation
                    ? answer.calcResult
                    : answer.text,
                enabled: !locked,
                minLines: task.answerKind == AnswerKind.text ? 3 : 1,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: task.answerKind == AnswerKind.calculation
                      ? l10n.teacherCalcResult
                      : l10n.assignmentYourAnswer,
                ),
                onChanged: (value) => onChanged(
                  task.answerKind == AnswerKind.calculation
                      ? answer.copyWith(calcResult: value)
                      : answer.copyWith(text: value),
                ),
              ),
            if (task.answerKind == AnswerKind.multipleChoice)
              for (final option in task.options)
                CheckboxListTile(
                  value: answer.selectedOptionIds.contains(option.id),
                  title: Text(option.text),
                  onChanged: locked
                      ? null
                      : (value) {
                          final next = [...answer.selectedOptionIds];
                          if (value == true) {
                            if (!next.contains(option.id)) next.add(option.id);
                          } else {
                            next.remove(option.id);
                          }
                          onChanged(answer.copyWith(selectedOptionIds: next));
                        },
                ),
            if (task.answerKind == AnswerKind.matching)
              for (final left in task.leftItems)
                DropdownButtonFormField<String>(
                  initialValue: () {
                    for (final pair in answer.matchPairs) {
                      if (pair.$1 == left.id &&
                          task.rightItems.any((r) => r.id == pair.$2)) {
                        return pair.$2;
                      }
                    }
                    return null;
                  }(),
                  decoration: InputDecoration(labelText: left.text),
                  items: [
                    for (final right in task.rightItems)
                      DropdownMenuItem(
                        value: right.id,
                        child: Text(right.text),
                      ),
                  ],
                  onChanged: locked
                      ? null
                      : (value) {
                          if (value == null) return;
                          onChanged(
                            answer.copyWith(
                              matchPairs: [
                                for (final pair in answer.matchPairs)
                                  if (pair.$1 != left.id) pair,
                                (left.id, value),
                              ],
                            ),
                          );
                        },
                ),
          ],
        ),
      ),
    );
  }
}
