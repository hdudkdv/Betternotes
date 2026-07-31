import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../planner/planner_model.dart';

/// Home “Als Nächstes” strip — next 1–3 school calendar events.
class UpcomingSchoolStrip extends ConsumerWidget {
  const UpcomingSchoolStrip({super.key, this.limit = 3});

  final int limit;

  IconData _iconFor(PlannerEventKind kind) => switch (kind) {
    PlannerEventKind.exam => Icons.assignment_outlined,
    PlannerEventKind.homework => Icons.edit_note_rounded,
    PlannerEventKind.appointment => Icons.event_rounded,
    PlannerEventKind.other => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final planner = ref.watch(plannerProvider);
    final events = planner.upcoming(limit: limit);
    if (events.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.upcomingNext,
                  style: AppTheme.headline(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/calendar'),
                child: Text(l10n.calendar),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final event in events)
            Builder(
              builder: (context) {
                GradeEntry? grade;
                for (final item in planner.grades) {
                  if (item.id == event.gradeId || item.eventId == event.id) {
                    grade = item;
                    break;
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Color(event.colorValue).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.push('/calendar'),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          children: [
                            Icon(
                              _iconFor(event.kind),
                              color: Color(event.colorValue),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title.trim().isEmpty
                                        ? event.displaySubject
                                        : event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.body(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  Text(
                                    [
                                      DateFormat.MMMd().add_Hm().format(
                                        event.start,
                                      ),
                                      if (event.subject.trim().isNotEmpty &&
                                          event.title.trim().isNotEmpty)
                                        event.subject.trim(),
                                      if (grade != null) grade.displayValue,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.body(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
