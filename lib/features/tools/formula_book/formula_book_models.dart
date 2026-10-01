import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class FormulaRow extends Equatable {
  const FormulaRow({
    required this.id,
    required this.term,
    required this.value,
    this.symbol = '',
    this.meaning = '',
    this.pronunciation = '',
  });

  final String id;
  final String term;
  final String value;
  final String symbol;
  final String meaning;
  final String pronunciation;

  FormulaRow copyWith({
    String? term,
    String? value,
    String? symbol,
    String? meaning,
    String? pronunciation,
  }) {
    return FormulaRow(
      id: id,
      term: term ?? this.term,
      value: value ?? this.value,
      symbol: symbol ?? this.symbol,
      meaning: meaning ?? this.meaning,
      pronunciation: pronunciation ?? this.pronunciation,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'term': term,
    'value': value,
    if (symbol.isNotEmpty) 'symbol': symbol,
    if (meaning.isNotEmpty) 'meaning': meaning,
    if (pronunciation.isNotEmpty) 'pronunciation': pronunciation,
  };

  factory FormulaRow.fromJson(Map<String, dynamic> json) {
    return FormulaRow(
      id: json['id'] as String? ?? const Uuid().v4(),
      term: json['term'] as String? ?? '',
      value: json['value'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      pronunciation: json['pronunciation'] as String? ?? '',
    );
  }

  factory FormulaRow.create({
    String term = '',
    String value = '',
    String symbol = '',
    String meaning = '',
    String pronunciation = '',
  }) {
    return FormulaRow(
      id: const Uuid().v4(),
      term: term,
      value: value,
      symbol: symbol,
      meaning: meaning,
      pronunciation: pronunciation,
    );
  }

  @override
  List<Object?> get props => [id, term, value, symbol, meaning, pronunciation];
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

    FormulaChapter symbols(
      String id,
      String title,
      List<(String, String, String, String, String)> rows,
    ) {
      return FormulaChapter(
        id: id,
        title: title,
        rows: [
          for (final r in rows)
            FormulaRow.create(
              symbol: r.$1,
              term: r.$2,
              meaning: r.$3,
              pronunciation: r.$4,
              value: r.$5,
            ),
        ],
      );
    }

    return FormulaBook(
      chapters: [
        symbols('symbole', 'Symbole', [
          ('π', 'Pi', 'Kreiszahl', 'Pi', '3,14159…'),
          ('∑', 'Summe', 'Summenzeichen', 'Summe', 'a₁ + a₂ + … + aₙ'),
          ('√', 'Wurzel', 'Quadratwurzel', 'Wurzel', '√x'),
          ('∞', 'Unendlich', 'unendlich groß', 'Unendlich', '∞'),
          ('±', 'Plusminus', 'plus oder minus', 'plusminus', 'a ± b'),
          ('Δ', 'Delta', 'Differenz / Änderung', 'Delta', 'Δx = x₂ − x₁'),
          ('≈', 'Ungefähr', 'ungefähr gleich', 'ungefähr', 'a ≈ b'),
          ('≠', 'Ungleich', 'nicht gleich', 'ungleich', 'a ≠ b'),
          ('≤', 'Kleiner gleich', 'kleiner oder gleich', 'kleiner-gleich', 'a ≤ b'),
          ('≥', 'Größer gleich', 'größer oder gleich', 'größer-gleich', 'a ≥ b'),
          ('α', 'Alpha', 'Winkel / Faktor', 'Alpha', 'α'),
          ('β', 'Beta', 'Winkel / Faktor', 'Beta', 'β'),
          ('γ', 'Gamma', 'Winkel / Faktor', 'Gamma', 'γ'),
          ('θ', 'Theta', 'Winkel', 'Theta', 'θ'),
          ('λ', 'Lambda', 'Wellenlänge / Eigenwert', 'Lambda', 'λ'),
          ('μ', 'Mü', 'Mikro / Mittelwert', 'Mü', 'μ'),
          ('σ', 'Sigma', 'Standardabweichung', 'Sigma', 'σ'),
          ('φ', 'Phi', 'Goldener Schnitt / Phase', 'Phi', 'φ ≈ 1,618'),
          ('ω', 'Omega', 'Kreisfrequenz', 'Omega', 'ω = 2πf'),
          ('Ω', 'Ohm', 'Widerstandseinheit', 'Omega', 'R in Ω'),
          ('∈', 'Element von', 'gehört zur Menge', 'Element', 'x ∈ M'),
          ('∪', 'Vereinigung', 'Vereinigungsmenge', 'Vereinigung', 'A ∪ B'),
          ('∩', 'Schnitt', 'Schnittmenge', 'Schnitt', 'A ∩ B'),
          ('|x|', 'Betrag', 'Abstand vom Nullpunkt', 'Betrag', 'abs(x)'),
          ('n!', 'Fakultät', 'Produkt 1·2·…·n', 'Fakultät', 'n!'),
          ('∫', 'Integral', 'Fläche unter der Kurve', 'Integral', '∫ f(x) dx'),
          ('°', 'Grad', 'Winkelgrad', 'Grad', '90°'),
          ('ρ', 'Rho', 'Dichte', 'Rho', 'ρ = m / V'),
          ('F', 'Kraft', 'Force, Einheit Newton', 'Eff', 'F = m · a'),
          ('v', 'Geschwindigkeit', 'Velocity', 'Vau', 'v = s / t'),
        ]),
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
          ('f(x) = √(1−x²)', 'sqrt(1-x^2)'),
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
