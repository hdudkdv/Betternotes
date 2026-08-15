import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import 'assignment_session.dart';

class AssignmentResultsPage extends ConsumerStatefulWidget {
  const AssignmentResultsPage({super.key, required this.runId});

  final String runId;

  @override
  ConsumerState<AssignmentResultsPage> createState() =>
      _AssignmentResultsPageState();
}

class _AssignmentResultsPageState extends ConsumerState<AssignmentResultsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentHostProvider.notifier).loadRun(widget.runId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final host = ref.watch(assignmentHostProvider);
    final summary = host.summary;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.assignmentResults)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (summary != null) ...[
            Text(
              l10n.assignmentClassAverage(summary.averagePercent.round()),
              style: AppTheme.headline(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              l10n.assignmentSubmittedCount(
                summary.submittedCount,
                summary.participantCount,
              ),
              style: AppTheme.body(color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.assignmentTopProblems,
              style: AppTheme.headline(fontSize: 18),
            ),
            if (summary.topProblems.isEmpty)
              Text(l10n.assignmentNoProblems)
            else
              for (final problem in summary.topProblems)
                ListTile(
                  title: Text(problem.title),
                  subtitle: Text(problem.label),
                  trailing: Text('${problem.count}'),
                ),
            if (summary.groups.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.assignmentGroups,
                style: AppTheme.headline(fontSize: 18),
              ),
              for (final group in summary.groups)
                ListTile(
                  dense: true,
                  title: Text(group.title),
                  subtitle: Text(group.label),
                  trailing: Text('${group.count}'),
                ),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            l10n.assignmentSubmissions,
            style: AppTheme.headline(fontSize: 18),
          ),
          for (final sub in host.submissions)
            ExpansionTile(
              title: Text(sub.deviceName),
              subtitle: Text(
                '${sub.submittedAt.toLocal()} · ${sub.early ? l10n.assignmentEarly : l10n.assignmentOnCollect}',
              ),
              children: [
                if (sub.ocrText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(sub.ocrText),
                  ),
                for (final grade in sub.grades)
                  ListTile(
                    dense: true,
                    title: Text(grade.taskId),
                    subtitle: Text(grade.issues.join(', ')),
                    trailing: Text(
                      '${grade.pointsAwarded.round()}/${grade.maxPoints}',
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    initialValue: sub.correctionText,
                    decoration: InputDecoration(
                      labelText: l10n.assignmentCorrection,
                    ),
                    onFieldSubmitted: (value) => ref
                        .read(assignmentHostProvider.notifier)
                        .returnCorrection(
                          deviceId: sub.deviceId,
                          text: value,
                        ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
