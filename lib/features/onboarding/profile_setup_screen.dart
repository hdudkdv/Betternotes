import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../import_export/import_export_providers.dart';
import '../library/providers/library_providers.dart';
import '../planner/education_settings.dart';
import 'app_tour.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  bool _busy = false;
  TeacherTrack? _track;
  EducationLevel? _level;
  GermanState? _state;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _track = settings.teacherTrack;
    _level = settings.educationLevel;
    _state = settings.germanState;
  }

  Future<void> _finish() async {
    if (_busy) return;
    final settings = ref.read(settingsProvider);
    final isTeacher = settings.isTeacher;
    if (isTeacher && _track == null) return;
    if (!isTeacher && _level == null) return;
    if (_state == null) return;

    setState(() => _busy = true);
    final notifier = ref.read(settingsProvider.notifier);
    try {
      if (isTeacher) {
        await notifier.setTeacherTrack(_track);
        await notifier.setEducationLevel(
          _track == TeacherTrack.studying
              ? EducationLevel.university
              : EducationLevel.sek2,
        );
      } else {
        await notifier.setTeacherTrack(null);
        await notifier.setEducationLevel(_level!);
      }
      await notifier.setGermanState(_state!);
      await notifier.completeProfileSetup();
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final startTour = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.tutorialOfferTitle),
          content: Text(l10n.tutorialOfferBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.tutorialSkip),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.tutorialStart),
            ),
          ],
        ),
      );
      if (startTour == true) {
        ref.read(pendingAppTourProvider.notifier).state = true;
      }
      if (!mounted) return;
      final pending = ref.read(shareIntakeProvider).peekPending;
      context.go(pending != null && pending.isNotEmpty ? '/import' : '/');
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final isTeacher = settings.isTeacher;
    final canContinue =
        _state != null && (isTeacher ? _track != null : _level != null);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              children: [
                Text(
                  isTeacher ? l10n.setupTeacherTitle : l10n.setupStudentTitle,
                  style: AppTheme.headline(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isTeacher ? l10n.setupTeacherBody : l10n.setupStudentBody,
                  style: AppTheme.body(color: AppTheme.inkMuted, height: 1.45),
                ),
                const SizedBox(height: 28),
                if (isTeacher) ...[
                  Text(
                    l10n.setupTeacherTrack,
                    style: AppTheme.body(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _ChoiceCard(
                    selected: _track == TeacherTrack.studying,
                    title: l10n.teacherTrackStudying,
                    body: l10n.teacherTrackStudyingHint,
                    onTap: () =>
                        setState(() => _track = TeacherTrack.studying),
                  ),
                  const SizedBox(height: 10),
                  _ChoiceCard(
                    selected: _track == TeacherTrack.qualified,
                    title: l10n.teacherTrackQualified,
                    body: l10n.teacherTrackQualifiedHint,
                    onTap: () =>
                        setState(() => _track = TeacherTrack.qualified),
                  ),
                ] else ...[
                  Text(
                    l10n.educationLevel,
                    style: AppTheme.body(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  for (final level in EducationLevel.values) ...[
                    _ChoiceCard(
                      selected: _level == level,
                      title: level.label(l10n),
                      body: level.scaleHint(l10n),
                      onTap: () => setState(() => _level = level),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 18),
                Text(
                  l10n.federalState,
                  style: AppTheme.body(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.federalStateHint,
                  style: AppTheme.body(
                    color: AppTheme.inkMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<GermanState>(
                  initialValue: _state,
                  items: [
                    for (final state in GermanState.values)
                      DropdownMenuItem(
                        value: state,
                        child: Text(state.label(l10n)),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _state = value),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: canContinue && !_busy ? _finish : null,
                  child: Text(l10n.continueAction),
                ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.accentSoft : AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppTheme.accent : AppTheme.paperDeep,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.body(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: AppTheme.body(color: AppTheme.inkMuted, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
