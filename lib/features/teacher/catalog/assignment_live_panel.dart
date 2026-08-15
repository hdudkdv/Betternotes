import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../lan_sync/lan_sync_controller.dart';
import '../../lan_sync/lan_sync_protocol.dart';
import 'assignment_print.dart';
import 'assignment_session.dart';
import 'catalog_models.dart';
import 'catalog_store.dart';

class AssignmentLivePanel extends ConsumerWidget {
  const AssignmentLivePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final host = ref.watch(assignmentHostProvider);
    final catalog = ref.watch(catalogProvider);
    final ready = [
      for (final item in catalog)
        if (item.confirmed && !item.needsReview) item,
    ];
    final run = host.run;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teacherAssignments,
              style: AppTheme.headline(fontSize: 19),
            ),
            const SizedBox(height: 8),
            if (run == null) ...[
              Text(
                l10n.assignmentStartHint,
                style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: ready.isEmpty
                    ? null
                    : () => _start(context, ref, ready),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.assignmentStart),
              ),
            ] else ...[
              Text(run.title, style: AppTheme.headline(fontSize: 16)),
              Text(
                l10n.assignmentClassAverage(host.liveAveragePercent.round()),
              ),
              Text(
                l10n.assignmentSubmittedCount(
                  host.submittedCount,
                  host.progress.length,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () => ref
                        .read(assignmentHostProvider.notifier)
                        .extend(const Duration(minutes: 5)),
                    child: Text(l10n.assignmentExtend5),
                  ),
                  FilledButton.tonal(
                    onPressed: () => ref
                        .read(assignmentHostProvider.notifier)
                        .extend(const Duration(minutes: 10)),
                    child: Text(l10n.assignmentExtend10),
                  ),
                  FilledButton(
                    onPressed: () =>
                        ref.read(assignmentHostProvider.notifier).collect(),
                    child: Text(l10n.assignmentCollect),
                  ),
                  OutlinedButton(
                    onPressed: () => ref
                        .read(assignmentHostProvider.notifier)
                        .allowImport(),
                    child: Text(l10n.assignmentAllowImport),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push('/teacher/assignment/${run.id}'),
                    child: Text(l10n.assignmentResults),
                  ),
                ],
              ),
              if (host.leaves.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(l10n.assignmentLeaveSignals),
                for (final leave in host.leaves.take(8))
                  Text(
                    '${leave.deviceName} · ${leave.kind} · ${leave.at.hour.toString().padLeft(2, '0')}:${leave.at.minute.toString().padLeft(2, '0')}',
                    style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    List<CatalogItem> ready,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    var selected = ready.first;
    var minutes = selected.suggestedDurationMinutes;
    var testMode = selected.kind != CatalogKind.task;
    final minutesCtrl = TextEditingController(text: '$minutes');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(l10n.assignmentStart),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<CatalogItem>(
                initialValue: selected,
                items: [
                  for (final item in ready)
                    DropdownMenuItem(
                      value: item,
                      child: Text(item.title.trim().isEmpty
                          ? l10n.teacherUntitledAssignment
                          : item.title),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialog(() {
                    selected = value;
                    minutesCtrl.text = '${value.suggestedDurationMinutes}';
                  });
                },
              ),
              TextField(
                controller: minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.teacherDurationMinutes,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: testMode,
                onChanged: (value) => setDialog(() => testMode = value),
                title: Text(l10n.assignmentTestMode),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.assignmentStart),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final lan = ref.read(lanSyncProvider);
    if (!lan.classroomMode || lan.role != LanSyncRole.host || !lan.isActive) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherStartClassBeforeDistribute)),
        );
      }
      return;
    }
    await ref.read(assignmentHostProvider.notifier).start(
      item: selected,
      minutes: int.tryParse(minutesCtrl.text) ?? 45,
      testMode: testMode,
    );
  }
}

Future<void> printCatalogItem(CatalogItem item) {
  return const AssignmentPrint().printWithoutSolutions(item);
}
