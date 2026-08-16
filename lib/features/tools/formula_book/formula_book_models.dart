import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class FormulaRow extends Equatable {
  const FormulaRow({
    required this.id,
    required this.term,
    required this.value,
  });

  final String id;
  final String term;
  final String value;

  FormulaRow copyWith({String? term, String? value}) {
    return FormulaRow(
      id: id,
      term: term ?? this.term,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'term': term, 'value': value};

  factory FormulaRow.fromJson(Map<String, dynamic> json) {
    return FormulaRow(
      id: json['id'] as String? ?? const Uuid().v4(),
      term: json['term'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  factory FormulaRow.create({String term = '', String value = ''}) {
    return FormulaRow(id: const Uuid().v4(), term: term, value: value);
  }

  @override
  List<Object?> get props => [id, term, value];
}

class FormulaChapter extends Equatable {
  const FormulaChapter({
    required this.id,
    required this.title,
    required this.rows,
  });

  final String id;
  final String title;
  final List<FormulaRow> rows;

  FormulaChapter copyWith({String? title, List<FormulaRow>? rows}) {
    return FormulaChapter(
      id: id,
      title: title ?? this.title,
      rows: rows ?? this.rows,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'rows': [for (final r in rows) r.toJson()],
  };

  factory FormulaChapter.fromJson(Map<String, dynamic> json) {
    return FormulaChapter(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['id'] as String,
      rows: [
        for (final item in (json['rows'] as List? ?? const []))
          FormulaRow.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  @override
  List<Object?> get props => [id, title, rows];
}

class FormulaBook extends Equatable {
  const FormulaBook({required this.chapters});

  final List<FormulaChapter> chapters;

  FormulaChapter? byId(String id) {
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }

  FormulaBook replaceChapter(FormulaChapter chapter) {
    return FormulaBook(
      chapters: [
        for (final c in chapters)
          if (c.id == chapter.id) chapter else c,
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'chapters': [for (final c in chapters) c.toJson()],
  };

  factory FormulaBook.fromJson(Map<String, dynamic> json) {
    return FormulaBook(
      chapters: [
        for (final item in (json['chapters'] as List? ?? const []))
          FormulaChapter.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  static FormulaBook seeded() {
    FormulaChapter ch(String id, String title, List<(String, String)> rows) {
      return FormulaChapter(
        id: id,
        title: title,
        rows: [
          for (final r in rows) FormulaRow.create(term: r.$1, value: r.$2),
        ],
      );
    }

    return FormulaBook(
      chapters: [
        ch('funktionen', 'Funktionen', [
          ('f(x) = x', 'x'),
          ('f(x) = 2x + 1', '2x+1'),
          ('f(x) = x²', 'x^2'),
          ('f(x) = x³', 'x^3'),
          ('f(x) = sin(x)', 'sin(x)'),
          ('f(x) = cos(x)', 'cos(x)'),
          ('f(x) = tan(x)', 'tan(x)'),
          ('f(x) = e^x', 'exp(x)'),
          ('f(x) = ln(x)', 'ln(x)'),
          ('f(x) = 1/x', '1/x'),
          ('f(x) = √x', 'sqrt(x)'),
          ('f(x) = |x|', 'abs(x)'),
          ('f(x) = sin(x) + cos(x)', 'sin(x)+cos(x)'),
        ]),
        ch('mathematik', 'Mathematik', [
          ('Fläche Quadrat', 'a · a'),
          ('Fläche Rechteck', 'a · b'),
          ('Fläche Dreieck', '(a · h) / 2'),
          ('Fläche Kreis', 'π · r²'),
          ('Umfang Kreis', '2 · π · r'),
          ('Satz des Pythagoras', 'a² + b² = c²'),
          ('Binom (a+b)²', 'a² + 2ab + b²'),
        ]),
        ch('physik', 'Physik', [
          ('Geschwindigkeit', 'v = s / t'),
          ('Kraft', 'F = m · a'),
          ('Arbeit', 'W = F · s'),
        ]),
        ch('chemie', 'Chemie', [
          ('Dichte', 'ρ = m / V'),
          ('Stoffmenge', 'n = m / M'),
        ]),
        ch('biologie', 'Biologie', [
          ('Fotosynthese', '6 CO₂ + 6 H₂O → C₆H₁₂O₆ + 6 O₂'),
        ]),
        ch('geschichte', 'Geschichte', const []),
        ch('deutsch', 'Deutsch', const []),
        ch('englisch', 'Englisch', const []),
        ch('geographie', 'Geographie', const []),
        ch('politik', 'Politik', const []),
        ch('wirtschaft', 'Wirtschaft', const []),
        ch('informatik', 'Informatik', const []),
        ch('kunst', 'Kunst', const []),
        ch('musik', 'Musik', const []),
        ch('sport', 'Sport', const []),
      ],
    );
  }

  /// Extra chapters from the Marketplace Tafelwerk pack.
  static FormulaBook plusSeeded() {
    FormulaChapter ch(String id, String title, List<(String, String)> rows) {
      return FormulaChapter(
        id: id,
        title: title,
        rows: [
          for (final r in rows) FormulaRow.create(term: r.$1, value: r.$2),
        ],
      );
    }

    return FormulaBook(
      chapters: [
        ch('analysis', 'Analysis', [
          ('Potenzregel', "x^n → n·x^(n-1)"),
          ('Ableitung sin', 'sin(x) → cos(x)'),
          ('Ableitung cos', 'cos(x) → -sin(x)'),
          ('Ableitung e^x', 'exp(x) → exp(x)'),
          ('Ableitung ln', 'ln(x) → 1/x'),
          ('Kettenregel', "f(g(x)) → f'(g(x))·g'(x)"),
        ]),
        ch('geometrie_plus', 'Geometrie Plus', [
          ('Kugel Volumen', '(4/3)·π·r³'),
          ('Kugel Oberfläche', '4·π·r²'),
          ('Zylinder Volumen', 'π·r²·h'),
          ('Kegel Volumen', '(1/3)·π·r²·h'),
          ('Prisma Volumen', 'G·h'),
        ]),
        ch('statistik', 'Statistik', [
          ('Mittelwert', 'mean(x1, x2, …)'),
          ('Median', 'median(x1, x2, …)'),
          ('Standardabweichung', 'stdev(x1, x2, …)'),
          ('Anzahl', 'count(x1, x2, …)'),
        ]),
      ],
    );
  }

  @override
  List<Object?> get props => [chapters];
}
