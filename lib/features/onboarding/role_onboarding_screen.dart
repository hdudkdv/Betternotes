import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
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
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 760,
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: SegmentedButton<String>(
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
                    const Spacer(),
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 64,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.roleWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.headline(
                        fontSize: 32,
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
                    const SizedBox(height: 30),
                    if (constraints.maxWidth < 620) ...[
                      _RoleCard(
                        icon: Icons.school_outlined,
                        title: l10n.roleStudent,
                        body: l10n.roleStudentHint,
                        action: l10n.roleChooseStudent,
                        busy: _busy,
                        onTap: () => _select(AppUserRole.student),
                      ),
                      const SizedBox(height: 14),
                      _RoleCard(
                        icon: Icons.co_present_outlined,
                        title: l10n.roleTeacher,
                        body: l10n.roleTeacherHint,
                        action: l10n.roleChooseTeacher,
                        accent: true,
                        busy: _busy,
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
                              onTap: () => _select(AppUserRole.teacher),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 18),
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
                    const Spacer(),
                  ],
                ),
              ),
            );

            // Only scroll when the viewport is actually too short.
            final needsScroll = constraints.maxHeight < 640;
            if (!needsScroll) {
              return Center(child: content);
            }
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: content,
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
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  final bool busy;
  final bool accent;

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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: AppTheme.accent),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTheme.headline(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppTheme.body(color: AppTheme.inkMuted, height: 1.45),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: busy ? null : onTap,
                child: Text(action),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
