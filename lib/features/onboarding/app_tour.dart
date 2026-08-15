import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../library/providers/library_providers.dart';

final pendingAppTourProvider = StateProvider<bool>((ref) => false);

class AppTourStep {
  const AppTourStep({
    required this.title,
    required this.body,
    this.key,
  });

  final String title;
  final String body;
  final GlobalKey? key;
}

class AppTourOverlay extends StatelessWidget {
  const AppTourOverlay({
    super.key,
    required this.steps,
    required this.index,
    required this.onNext,
    required this.onSkip,
  });

  final List<AppTourStep> steps;
  final int index;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = steps[index];
    final box = step.key?.currentContext?.findRenderObject() as RenderBox?;
    Rect? highlight;
    if (box != null && box.hasSize) {
      final offset = box.localToGlobal(Offset.zero);
      highlight = offset & box.size;
    }
    final last = index >= steps.length - 1;

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          if (highlight != null)
            Positioned.fromRect(
              rect: highlight.inflate(8),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Material(
                  color: AppTheme.paper,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${index + 1} / ${steps.length}',
                          style: AppTheme.body(
                            fontSize: 12,
                            color: AppTheme.inkMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.title,
                          style: AppTheme.headline(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.body,
                          style: AppTheme.body(
                            color: AppTheme.inkMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            TextButton(
                              onPressed: onSkip,
                              child: Text(l10n.tutorialSkip),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: onNext,
                              child: Text(
                                last ? l10n.tutorialDone : l10n.tutorialNext,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> markTutorialSeen(WidgetRef ref) async {
  ref.read(pendingAppTourProvider.notifier).state = false;
  await ref.read(sharedPreferencesProvider).setBool('tutorialCompleted', true);
}
