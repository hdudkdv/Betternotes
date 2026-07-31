import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../editor_chrome.dart';

/// Compact Pomodoro controls for the study-mode floating bar.
class StudyPomodoroChip extends StatefulWidget {
  const StudyPomodoroChip({super.key});

  @override
  State<StudyPomodoroChip> createState() => _StudyPomodoroChipState();
}

class _StudyPomodoroChipState extends State<StudyPomodoroChip> {
  static const _focusMinutes = 25;
  static const _breakMinutes = 5;

  Timer? _timer;
  int _remainingSeconds = _focusMinutes * 60;
  bool _running = false;
  bool _onBreak = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_remainingSeconds <= 1) {
      _timer?.cancel();
      HapticFeedback.mediumImpact();
      setState(() {
        _running = false;
        _onBreak = !_onBreak;
        _remainingSeconds =
            (_onBreak ? _breakMinutes : _focusMinutes) * 60;
      });
      return;
    }
    setState(() => _remainingSeconds--);
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() => _running = true);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _onBreak = false;
      _remainingSeconds = _focusMinutes * 60;
    });
  }

  String get _label {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _onBreak ? l10n.pomodoroBreak : l10n.pomodoroFocus,
          style: TextStyle(
            color: EditorChrome.onDarkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _label,
          style: TextStyle(
            color: EditorChrome.onDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: _running ? l10n.pomodoroPause : l10n.pomodoroStart,
          onPressed: _toggle,
          icon: Icon(
            _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 18,
            color: EditorChrome.onDark,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: l10n.pomodoroReset,
          onPressed: _reset,
          icon: Icon(
            Icons.refresh_rounded,
            size: 16,
            color: EditorChrome.onDarkMuted,
          ),
        ),
      ],
    );
  }
}
