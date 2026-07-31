import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../import_export/import_export_providers.dart';
import '../library/providers/library_providers.dart';

class RoleOnboardingScreen extends ConsumerWidget {
  const RoleOnboardingScreen({super.key});

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    AppUserRole role,
  ) async {
    await ref.read(settingsProvider.notifier).setUserRole(role);
    if (!context.mounted) return;
    final pending = ref.read(shareIntakeProvider).peekPending;
    context.go(pending != null && pending.isNotEmpty ? '/import' : '/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        _RoleCard(
                          icon: Icons.school_outlined,
                          title: l10n.roleStudent,
                          body: l10n.roleStudentHint,
                          action: l10n.roleChooseStudent,
                          onTap: () =>
                              _select(context, ref, AppUserRole.student),
                        ),
                        _RoleCard(
                          icon: Icons.co_present_outlined,
                          title: l10n.roleTeacher,
                          body: l10n.roleTeacherHint,
                          action: l10n.roleChooseTeacher,
                          accent: true,
                          onTap: () =>
                              _select(context, ref, AppUserRole.teacher),
                        ),
                      ];
                      if (constraints.maxWidth < 620) {
                        return Column(
                          children: [
                            cards.first,
                            const SizedBox(height: 14),
                            cards.last,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards.first),
                          const SizedBox(width: 16),
                          Expanded(child: cards.last),
                        ],
                      );
                    },
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
                ],
              ),
            ),
          ),
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
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: accent ? AppTheme.accentSoft : AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: accent ? AppTheme.accent : AppTheme.paperDeep,
          width: accent ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
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
                onPressed: onTap,
                child: Text(action),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
