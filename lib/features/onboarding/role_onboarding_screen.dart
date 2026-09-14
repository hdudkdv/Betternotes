import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/haptics.dart';
import '../library/providers/library_providers.dart';

class RoleOnboardingScreen extends ConsumerStatefulWidget {
  const RoleOnboardingScreen({super.key});

  @override
  ConsumerState<RoleOnboardingScreen> createState() =>
      _RoleOnboardingScreenState();
}

class _RoleOnboardingScreenState extends ConsumerState<RoleOnboardingScreen> {
  bool _busy = false;

  Future<void> _select(AppUserRole role) async {
    if (_busy) return;
    AppHaptics.confirm();
    setState(() => _busy = true);
    try {
      await ref.read(settingsProvider.notifier).setUserRole(role);
      if (!mounted) return;
      context.go('/setup');
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final wide = constraints.maxWidth >= 620;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                  maxWidth: 760,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          segments: [
                            ButtonSegment(
                              value: 'system',
                              label: Text(l10n.systemLanguage),
                            ),
                            ButtonSegment(
                              value: 'de',
                              label: Text(l10n.german),
                            ),
                            ButtonSegment(
                              value: 'en',
                              label: Text(l10n.english),
                            ),
                          ],
                          selected: {settings.localeCode},
                          onSelectionChanged: _busy
                              ? null
                              : (selection) => ref
                                    .read(settingsProvider.notifier)
                                    .setLocaleCode(selection.first),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 20 : 36),
                    Icon(
                      Icons.auto_stories_rounded,
                      size: compact ? 44 : 64,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    Text(
                      l10n.roleWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.headline(
                        fontSize: compact ? 26 : 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.roleWelcomeBody,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        fontSize: 16,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    SizedBox(height: compact ? 20 : 30),
                    if (!wide) ...[
                      _RoleCard(
                        icon: Icons.school_outlined,
                        title: l10n.roleStudent,
                        body: l10n.roleStudentHint,
                        action: l10n.roleChooseStudent,
                        busy: _busy,
                        compact: compact,
                        onTap: () => _select(AppUserRole.student),
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        icon: Icons.co_present_outlined,
                        title: l10n.roleTeacher,
                        body: l10n.roleTeacherHint,
                        action: l10n.roleChooseTeacher,
                        accent: true,
                        busy: _busy,
                        compact: compact,
                        onTap: () => _select(AppUserRole.teacher),
                      ),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _RoleCard(
                              icon: Icons.school_outlined,
                              title: l10n.roleStudent,
                              body: l10n.roleStudentHint,
                              action: l10n.roleChooseStudent,
                              busy: _busy,
                              compact: compact,
                              onTap: () => _select(AppUserRole.student),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _RoleCard(
                              icon: Icons.co_present_outlined,
                              title: l10n.roleTeacher,
                              body: l10n.roleTeacherHint,
                              action: l10n.roleChooseTeacher,
                              accent: true,
                              busy: _busy,
                              compact: compact,
                              onTap: () => _select(AppUserRole.teacher),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.roleCanChangeLater,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    if (_busy) ...[
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
    required this.busy,
    this.accent = false,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  final bool busy;
  final bool accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? AppTheme.accentSoft : AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: accent ? AppTheme.accent : AppTheme.paperDeep,
          width: accent ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 18 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 36 : 46, color: AppTheme.accent),
              SizedBox(height: compact ? 10 : 16),
              Text(
                title,
                style: AppTheme.headline(
                  fontSize: compact ? 20 : 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  color: AppTheme.inkMuted,
                  height: 1.4,
                  fontSize: compact ? 14 : null,
                ),
              ),
              SizedBox(height: compact ? 14 : 22),
              FilledButton(onPressed: busy ? null : onTap, child: Text(action)),
            ],
          ),
        ),
      ),
    );
  }
}
