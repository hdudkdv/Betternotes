import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'grade_calculator.dart';
import 'grade_value_codec.dart';

class _PickCell extends StatelessWidget {
  const _PickCell({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.accent : AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 0,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.ink
                  : AppTheme.ink.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.body(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 15 : 16,
              color: selected ? AppTheme.onAccent : AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tendency (+ / neutral / −) above the 1–6 row.
class Sek1GradePicker extends StatelessWidget {
  const Sek1GradePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double? value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = value == null ? null : Sek1Grade.fromValue(value!);
    final tendency = current?.tendency ?? GradeTendency.none;
    final base = current?.base;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.gradeTendency,
          style: AppTheme.body(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PickCell(
                label: '+',
                selected: tendency == GradeTendency.plus,
                onTap: () {
                  final b = base ?? 2;
                  onChanged(Sek1Grade(b, GradeTendency.plus).value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PickCell(
                label: l10n.gradeTendencyNone,
                selected: tendency == GradeTendency.none,
                onTap: () {
                  final b = base ?? 2;
                  onChanged(Sek1Grade(b, GradeTendency.none).value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PickCell(
                label: '−',
                selected: tendency == GradeTendency.minus,
                onTap: () {
                  final b = base ?? 2;
                  onChanged(Sek1Grade(b, GradeTendency.minus).value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.gradeValue,
          style: AppTheme.body(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var n = 1; n <= 6; n++) ...[
              if (n > 1) const SizedBox(width: 6),
              Expanded(
                child: _PickCell(
                  label: '$n',
                  selected: base == n,
                  onTap: () => onChanged(Sek1Grade(n, tendency).value),
                ),
              ),
            ],
          ],
        ),
        if (current != null) ...[
          const SizedBox(height: 10),
          Text(
            l10n.selectedGrade(current.label),
            textAlign: TextAlign.center,
            style: AppTheme.body(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.accent,
            ),
          ),
        ],
      ],
    );
  }
}

/// Points 0–15 in a compact grid.
class Sek2PointsPicker extends StatelessWidget {
  const Sek2PointsPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.gradeValuePoints15,
          style: AppTheme.body(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var p = 0; p <= 15; p++)
              SizedBox(
                width: 48,
                child: _PickCell(
                  label: '$p',
                  selected: value == p,
                  compact: true,
                  onTap: () => onChanged(p),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// University grade steps as selectable chips.
class UniGradePicker extends StatelessWidget {
  const UniGradePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double? value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.gradeValueUni,
          style: AppTheme.body(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in uniGradeSteps)
              SizedBox(
                width: 56,
                child: _PickCell(
                  label: s > 4.0
                      ? '${s.toStringAsFixed(1)}!'
                      : s.toStringAsFixed(1),
                  selected: value != null && (value! - s).abs() < 0.05,
                  compact: true,
                  onTap: () => onChanged(s),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
