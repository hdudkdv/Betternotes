/// German school / academic year keyed by the calendar year it starts in.
/// Example: 2025 → „2025/26“ (Aug 2025 – Jul 2026).
class SchoolYear implements Comparable<SchoolYear> {
  const SchoolYear(this.startYear);

  /// First calendar year of the school year (e.g. 2025 for 2025/26).
  final int startYear;

  String get label {
    final end = (startYear + 1) % 100;
    return '$startYear/${end.toString().padLeft(2, '0')}';
  }

  String get labelLong => '$startYear/${startYear + 1}';

  SchoolYear get previous => SchoolYear(startYear - 1);
  SchoolYear get next => SchoolYear(startYear + 1);

  /// School year containing [date] — starts 1 August.
  static SchoolYear fromDate(DateTime date) {
    final start = date.month >= 8 ? date.year : date.year - 1;
    return SchoolYear(start);
  }

  static SchoolYear current() => fromDate(DateTime.now());

  @override
  int compareTo(SchoolYear other) => startYear.compareTo(other.startYear);

  @override
  bool operator ==(Object other) =>
      other is SchoolYear && other.startYear == startYear;

  @override
  int get hashCode => startYear.hashCode;
}
