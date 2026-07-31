import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/notebook.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../planner/school_year_rollover.dart';

/// Notebook-sized CTA to create the next school year's notebook.
class SchoolYearRolloverCover extends StatelessWidget {
  const SchoolYearRolloverCover({
    super.key,
    required this.candidate,
    required this.onCreate,
    required this.onDismiss,
  });

  final SchoolYearRolloverCandidate candidate;
  final VoidCallback onCreate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = Color(candidate.source.coverColor);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCreate,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: color.withValues(alpha: 0.55),
                        width: 2,
                      ),
                      color: color.withValues(alpha: 0.08),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.schoolClassValue(candidate.nextClass),
                            style: AppTheme.body(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.auto_stories_outlined, color: color, size: 28),
                        const SizedBox(height: 10),
                        Text(
                          l10n.newSchoolYearNotebook,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.headline(
                            color: AppTheme.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          candidate.source.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                            color: AppTheme.inkMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      tooltip: l10n.dismiss,
                      visualDensity: VisualDensity.compact,
                      onPressed: onDismiss,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppTheme.inkMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.tapToContinue,
              style: AppTheme.body(
                color: AppTheme.inkMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select chapters to import into the new school-year notebook.
Future<List<String>?> promptSchoolYearChapterImport(
  BuildContext context, {
  required Notebook source,
  required int nextClass,
  required List<String> chapterTitles,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final selected = <String>{...chapterTitles};
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(l10n.importChaptersTitle),
            content: SizedBox(
              width: 420,
              child: chapterTitles.isEmpty
                  ? Text(
                      l10n.importChaptersEmpty,
                      style: AppTheme.body(color: AppTheme.inkMuted),
                    )
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.importChaptersBody(
                              source.title,
                              nextClass,
                            ),
                            style: AppTheme.body(
                              color: AppTheme.inkMuted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => setLocal(
                                  () => selected
                                    ..clear()
                                    ..addAll(chapterTitles),
                                ),
                                child: Text(l10n.selectAll),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setLocal(() => selected.clear()),
                                child: Text(l10n.selectNone),
                              ),
                            ],
                          ),
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (final title in chapterTitles)
                                  CheckboxListTile(
                                    dense: true,
                                    value: selected.contains(title),
                                    title: Text(title),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (v) {
                                      setLocal(() {
                                        if (v == true) {
                                          selected.add(title);
                                        } else {
                                          selected.remove(title);
                                        }
                                      });
                                    },
                                  ),
                              ],
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
                onPressed: () => Navigator.pop(
                  context,
                  selected.toList(growable: false),
                ),
                child: Text(l10n.create),
              ),
            ],
          );
        },
      );
    },
  );
}
