import 'planner_model.dart';

enum GradeTendency { plus, none, minus }

/// Sek I: 1–6 with optional + / − (stored as ±0.25).
class Sek1Grade {
  const Sek1Grade(this.base, this.tendency) : assert(base >= 1 && base <= 6);

  final int base;
  final GradeTendency tendency;

  double get value {
    final raw = switch (tendency) {
      GradeTendency.plus => base - 0.25,
      GradeTendency.none => base.toDouble(),
      GradeTendency.minus => base + 0.25,
    };
    return raw.clamp(0.75, 6.0);
  }

  String get label => switch (tendency) {
    GradeTendency.plus => '$base+',
    GradeTendency.none => '$base',
    GradeTendency.minus => '$base-',
  };

  static Sek1Grade fromValue(double value) {
    var best = const Sek1Grade(2, GradeTendency.none);
    var bestDist = double.infinity;
    for (var b = 1; b <= 6; b++) {
      for (final t in GradeTendency.values) {
        final g = Sek1Grade(b, t);
        final d = (g.value - value).abs();
        if (d < bestDist) {
          bestDist = d;
          best = g;
        }
      }
    }
    return best;
  }
}

String formatGradeValue(GradeEntry g) {
  final value = g.value;
  if (value == null) return '–';
  switch (g.scale) {
    case GradeScale.german:
      return Sek1Grade.fromValue(value).label;
    case GradeScale.points:
      return value.round().clamp(0, 15).toString();
    case GradeScale.uni:
      return value.toStringAsFixed(1);
    case GradeScale.percent:
      return '${value.toStringAsFixed(0)} %';
  }
}
