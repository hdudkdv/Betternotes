import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../lan_sync/lan_sync_controller.dart';

class ClassroomPickOverlay extends StatefulWidget {
  const ClassroomPickOverlay({
    super.key,
    required this.pick,
    required this.you,
    this.onDismiss,
  });

  final ClassroomPick pick;
  final bool you;
  final VoidCallback? onDismiss;

  @override
  State<ClassroomPickOverlay> createState() => _ClassroomPickOverlayState();
}

class _ClassroomPickOverlayState extends State<ClassroomPickOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _armTimer();
  }

  @override
  void didUpdateWidget(covariant ClassroomPickOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pick.name != widget.pick.name ||
        oldWidget.pick.kind != widget.pick.kind ||
        oldWidget.pick.sticky != widget.pick.sticky) {
      _armTimer();
    }
  }

  void _armTimer() {
    _timer?.cancel();
    if (widget.pick.sticky) return;
    _timer = Timer(Duration(milliseconds: widget.pick.holdMs), () {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pick = widget.pick;
    final you = widget.you;
    final headline = pick.isGroup
        ? (you ? l10n.teacherPickerYourGroup : l10n.teacherPickerGroupUp(pick.name))
        : (you ? l10n.teacherPickerYouAreUp : l10n.teacherPickerSomeoneUp(pick.name));
    return Material(
      color: Colors.black.withValues(alpha: you ? 0.45 : 0.28),
      child: InkWell(
        onTap: widget.onDismiss,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: you ? AppTheme.accent : AppTheme.card,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pick.isGroup
                          ? Icons.groups_rounded
                          : Icons.record_voice_over_rounded,
                      size: 42,
                      color: you ? AppTheme.onAccent : AppTheme.accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: AppTheme.headline(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: you ? AppTheme.onAccent : AppTheme.ink,
                      ),
                    ),
                    if (pick.isStudent && !you) ...[
                      const SizedBox(height: 6),
                      Text(
                        pick.name,
                        textAlign: TextAlign.center,
                        style: AppTheme.headline(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                    if (pick.isGroup && pick.members.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        pick.members.join(' · '),
                        textAlign: TextAlign.center,
                        style: AppTheme.body(
                          color: you
                              ? AppTheme.onAccent.withValues(alpha: 0.85)
                              : AppTheme.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
