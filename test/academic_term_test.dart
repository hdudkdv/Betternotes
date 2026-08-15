import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/planner/academic_term.dart';
import 'package:betternotes/features/planner/education_settings.dart';
import 'package:betternotes/features/planner/school_year_rollover.dart';
import 'package:betternotes/data/models/notebook.dart';

void main() {
  test('maps school half-years and university semesters', () {
    final hj1 = AcademicTerm.fromDate(
      EducationLevel.sek1,
      DateTime(2026, 1, 15),
    );
    expect(hj1.kind, TermKind.winterHalbjahr);
    expect(hj1.anchorYear, 2025);

    final hj2 = AcademicTerm.fromDate(
      EducationLevel.sek2,
      DateTime(2026, 3, 1),
    );
    expect(hj2.kind, TermKind.summerHalbjahr);

    final ws = AcademicTerm.fromDate(
      EducationLevel.university,
      DateTime(2026, 1, 10),
    );
    expect(ws.kind, TermKind.winterSemester);
    expect(ws.anchorYear, 2025);

    final ss = AcademicTerm.fromDate(
      EducationLevel.university,
      DateTime(2026, 4, 15),
    );
    expect(ss.kind, TermKind.summerSemester);
    expect(ss.anchorYear, 2026);
  });

  test('offers a semester notebook when the previous term is over', () {
    final old = Notebook(
      id: 'n1',
      title: 'BWL',
      coverColor: 0xFF000000,
      createdAt: DateTime(2025, 10, 2),
      updatedAt: DateTime(2026, 2, 1),
      lastOpenedAt: DateTime(2026, 2, 1),
    );
    final found = SchoolYearRollover.candidates(
      folderNotebooks: [old],
      level: EducationLevel.university,
      state: GermanState.nw,
      dismissedKeys: {},
      now: DateTime(2026, 4, 20),
    );
    expect(found, hasLength(1));
    expect(found.first.source.id, 'n1');
    expect(found.first.term?.kind, TermKind.summerSemester);
  });
}
