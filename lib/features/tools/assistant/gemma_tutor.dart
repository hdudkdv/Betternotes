import '../calculator/calculator_engine.dart';
import '../calculator/expression_diff.dart';
import '../calculator/plot_series.dart';
import 'gemma_topics.dart';

class GemmaReply {
  const GemmaReply({
    required this.text,
    this.chips = const [],
    this.solved = false,
  });

  final String text;
  final List<String> chips;
  final bool solved;
}

/// Socratic on-device coach. Knows the secret result only to check the
/// student — it never writes that number into a reply.
class GemmaTutor {
  GemmaTutor({required this.german});

  final bool german;
  final CalculatorEngine _engine = CalculatorEngine()..degrees = true;

  String? _problem;
  _Kind _kind = _Kind.none;
  int _step = 0;
  final List<_Step> _steps = [];
  final List<double> _hidden = [];
  bool _solved = false;

  GemmaReply welcome() {
    return GemmaReply(
      text: german
          ? 'Ich bin Gemma. Ich führe dich wie eine Lehrerin: in Mathe rechne ich nicht vor, in Geschichte und bei Bildern erkläre ich Zusammenhänge und Symbole — den Klausursatz schreibst du.\n\nAufgabe, Nachfrage oder ein Bild hierher.'
          : 'I am Gemma. I guide you like a teacher: in maths I will not compute for you; in history and with images I explain connections and symbols — you write the exam sentence.\n\nSend a problem, a follow-up, or a picture.',
      chips: german
          ? const ['2x+3=11', 'Karikatur', 'Versailles']
          : const ['2x+3=11', 'Caricature', 'Versailles'],
    );
  }

  GemmaReply respond(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return GemmaReply(text: _t('empty'));

    if (_isMathKind && _wantsExplain(text) && !_isHumanities(text)) {
      return GemmaReply(
        text:
            '${GemmaTopics.mathConcept(_kind.name, german: german)}\n\n${_currentHint()}',
        chips: _stepChips(),
      );
    }

    if (_looksLikeNewProblem(text) ||
        (_problem == null && _looksLikeMath(text))) {
      return _startLesson(text);
    }

    if (_isHumanities(text) ||
        _isImageTalk(text) ||
        (!_looksLikeMath(text) && GemmaTopics.match(text) != null)) {
      return _startLesson(text);
    }

    if (_problem == null) {
      return GemmaReply(text: _t('needProblem'), chips: _startChips());
    }

    if (_isHumanitiesKind) {
      return _continueHumanities(text);
    }

    if (_asksForAnswer(text)) {
      return GemmaReply(text: _t('refuseAnswer'), chips: _stepChips());
    }

    if (_isStuck(text)) {
      return GemmaReply(text: _currentHint(nudge: true), chips: _stepChips());
    }

    final guess = _extractNumber(text);
    if (guess != null) {
      return _checkGuess(guess, text);
    }

    if (_kind == _Kind.derivative && _looksLikeExpr(text)) {
      return _checkDerivativeGuess(text);
    }

    if (_wantsExplain(text)) {
      return GemmaReply(
        text:
            '${GemmaTopics.mathConcept(_kind.name, german: german)}\n\n${_currentHint()}',
        chips: _stepChips(),
      );
    }

    return GemmaReply(text: _currentHint(nudge: true), chips: _stepChips());
  }

  /// Photo or page image: read labels, then walk a caricature/source analysis.
  GemmaReply respondImage({String? ocrText, String? label}) {
    final note = [
      if (label != null && label.trim().isNotEmpty) label.trim(),
      if (ocrText != null && ocrText.trim().isNotEmpty)
        german
            ? 'Text auf dem Bild: ${ocrText.trim()}'
            : 'Text on the image: ${ocrText.trim()}',
    ].join('\n');
    return _startLesson(
      note.isEmpty
          ? (german ? 'Karikatur / Bildquelle' : 'Caricature / image source')
          : note,
      fromImage: true,
    );
  }

  GemmaReply _startLesson(String raw, {bool fromImage = false}) {
    _problem = raw.trim();
    _step = 0;
    _solved = false;
    _steps.clear();
    _hidden.clear();
    _kind = _Kind.other;

    final cleaned = _stripLeadIn(_problem!);
    if (fromImage || _isImageTalk(_problem!)) {
      _buildImage(_problem!);
    } else if (_isHumanities(_problem!) ||
        (!_looksLikeMath(cleaned) && GemmaTopics.match(_problem!) != null)) {
      _buildHistory(_problem!);
    } else if (_isDerivativePrompt(_problem!) || _isDerivativePrompt(cleaned)) {
      _buildDerivative(cleaned);
    } else if (_isPercent(cleaned) || _isPercent(_problem!)) {
      _buildPercent(cleaned);
    } else if (cleaned.contains('=')) {
      _buildEquation(cleaned);
    } else if (_isTrig(cleaned)) {
      _buildTrig(cleaned);
    } else if (_looksLikeExpr(cleaned)) {
      _buildExpression(cleaned);
    } else {
      _buildOther();
    }

    return GemmaReply(text: _opening() + _currentHint(), chips: _stepChips());
  }

  void _buildEquation(String src) {
    final solved = _engine.evaluateOrSolve(src);
    if (solved.ok && src.toLowerCase().contains('x')) {
      _hide(solved.value);
    }

    final linear = _parseLinear(src);
    if (linear != null) {
      _kind = _Kind.linear;
      _hide(linear.mid);
      _hide(linear.x);
      _steps.addAll([
        _Step(
          hintDe:
              '${_linearIntro(src)} Nimm die Zahl ohne x und wende auf beiden Seiten die Umkehroperation an. Tippe nur diese Rechnung in den Taschenrechner und schick mir das Zwischenergebnis.',
          hintEn:
              '${_linearIntroEn(src)} Take the number without x and apply the inverse on both sides. Type only that calculation on the calculator and send me the intermediate result.',
          expected: [linear.mid],
        ),
        _Step(
          hintDe:
              'Jetzt x allein stellen: Welche Umkehroperation gehört zum Vorfaktor von x? Wieder selbst rechnen, dann die Zahl schicken.',
          hintEn:
              'Now isolate x: what is the inverse of the coefficient of x? Calculate it yourself, then send the number.',
          expected: [linear.x],
          isFinal: true,
        ),
      ]);
      return;
    }

    _kind = _Kind.equation;
    _steps.addAll([
      _Step(
        hintDe:
            'Schreib links und rechts getrennt auf. Was hängt von x ab, was nicht?',
        hintEn:
            'Write the left and right sides separately. What depends on x, and what does not?',
      ),
      _Step(
        hintDe:
            'Forme so um, dass x auf einer Seite allein näherkommt. Jeden Zwischenschritt am Taschenrechner, nicht im Kopf abkürzen.',
        hintEn:
            'Rearrange so x moves toward being alone. Do each intermediate step on the calculator — do not skip ahead.',
      ),
      _Step(
        hintDe:
            'Wenn x allein steht: setze zur Probe ein. Rechne beide Seiten und schick mir, ob sie gleich sind — nicht das x.',
        hintEn:
            'When x stands alone, substitute back. Compute both sides and tell me whether they match — not the value of x.',
        isFinal: true,
      ),
    ]);
  }

  void _buildExpression(String src) {
    _kind = _Kind.expression;
    final full = _engine.evaluate(src);
    if (full.ok) _hide(full.value);

    final mid = _firstPointOp(src);
    if (mid != null) {
      _hide(mid);
      _steps.addAll([
        _Step(
          hintDe:
              'Punkt vor Strich. Welche Multiplikation oder Division kommt zuerst? Tippe nur diese Teilrechnung in den Taschenrechner.',
          hintEn:
              'Multiplication and division first. Which of those comes first? Type only that sub-calculation on the calculator.',
          expected: [mid],
        ),
        _Step(
          hintDe:
              'Nimm das Zwischenergebnis und führe die restliche Addition oder Subtraktion selbst aus.',
          hintEn:
              'Take that intermediate result and do the remaining addition or subtraction yourself.',
          expected: full.ok ? [full.value] : const [],
          isFinal: true,
        ),
      ]);
      return;
    }

    _steps.addAll([
      _Step(
        hintDe:
            'Tippe die Rechnung selbst in den Taschenrechner. Schick mir danach nur, was angezeigt wird — ich prüfe, ohne vorzurechnen.',
        hintEn:
            'Type the expression on the calculator yourself. Then send only what it shows — I will check, I will not compute it for you.',
        expected: full.ok ? [full.value] : const [],
        isFinal: true,
      ),
    ]);
  }

  void _buildTrig(String src) {
    _kind = _Kind.trig;
    final result = _engine.evaluate(src);
    if (result.ok) _hide(result.value);
    _steps.addAll([
      _Step(
        hintDe:
            'Zuerst am Taschenrechner prüfen: Grad oder Bogenmaß? In der Schule ist meist Grad.',
        hintEn:
            'First check the calculator: degrees or radians? School work is usually degrees.',
      ),
      _Step(
        hintDe:
            'Tippe die Winkelfunktion selbst ein. Schick mir die Anzeige — ich sage dir nur, ob sie passt.',
        hintEn:
            'Type the trig function yourself. Send me the display — I will only say whether it fits.',
        expected: result.ok ? [result.value] : const [],
        isFinal: true,
      ),
    ]);
  }

  void _buildPercent(String src) {
    _kind = _Kind.percent;
    final parsed = _parsePercent(src);
    if (parsed != null) _hide(parsed);
    _steps.addAll([
      _Step(
        hintDe:
            'Prozent heißt Hundertstel. Was ist der Anteil, was ist der Grundwert?',
        hintEn:
            'Percent means hundredths. What is the part, and what is the base value?',
      ),
      _Step(
        hintDe:
            'Rechne Anteil ÷ 100, dann mal Grundwert — beides am Taschenrechner. Schick mir das Ergebnis.',
        hintEn:
            'Compute part ÷ 100, then times the base — both on the calculator. Send me the result.',
        expected: parsed != null ? [parsed] : const [],
        isFinal: true,
      ),
    ]);
  }

  void _buildDerivative(String src) {
    _kind = _Kind.derivative;
    final expr = _derivativeTarget(src);
    final diff = ExpressionDiff.differentiate(expr);
    _steps.addAll([
      _Step(
        hintDe:
            'Welche Ableitungsregel brauchst du? Schau im Tafelwerk nach (Potenz-, Ketten-, Produktregel) — ich nenne das Ergebnis nicht.',
        hintEn:
            'Which differentiation rule do you need? Check the formula book (power, chain, product) — I will not state the result.',
      ),
      _Step(
        hintDe:
            'Wende die Regel selbst an und schreib mir deine Ableitung, z. B. in der Form 2x oder cos(x).',
        hintEn:
            'Apply the rule yourself and send me your derivative, e.g. in the form 2x or cos(x).',
        expectedExpr: diff,
        isFinal: true,
      ),
    ]);
  }

  void _buildOther() {
    _kind = _Kind.other;
    _steps.addAll([
      _Step(
        hintDe:
            'Was ist gegeben, was ist gesucht? Ein Satz reicht. Bei Geschichte oder einem Bild: nenn das Thema oder häng die Karikatur an.',
        hintEn:
            'What is given, and what are you looking for? One sentence is enough. For history or a picture: name the topic or attach the caricature.',
      ),
      _Step(
        hintDe:
            'Wenn es Mathe ist: welche Formel aus dem Tafelwerk? Wenn es Geschichte ist: Ursache und Wirkung trennen.',
        hintEn:
            'If this is maths: which formula from the book? If this is history: separate cause and effect.',
        isFinal: true,
      ),
    ]);
  }

  void _buildHistory(String raw) {
    _kind = _Kind.history;
    final topics = GemmaTopics.matchAll(raw);
    final intro = topics.isEmpty
        ? (german
            ? 'Geschichte: Ich erkläre den Zusammenhang, du wendest ihn auf die Aufgabe an.\n\nNenn Ereignis, Personen oder die Leitfrage genauer — z. B. Versailles, Weimar, Mauer, Industrialisierung.'
            : 'History: I explain the connection, you apply it to the task.\n\nName the event, people, or question more precisely — e.g. Versailles, Weimar, the Wall, industrialisation.')
        : '${GemmaTopics.format(topics, german: german)}\n\n${german ? 'Das ist der Zusammenhang. Was genau fragt deine Aufgabe — Ursachen, Folgen oder eine Bewertung?' : 'That is the connection. What exactly does your task ask — causes, consequences, or a judgement?'}';
    _steps.addAll([
      _Step(hintDe: intro, hintEn: intro),
      _Step(
        hintDe:
            'Ordne selbst: Was ist Ursache, was Folge, wer handelt? Einen Satz aus der Aufgabe reicht, dann erkläre ich den nächsten Zusammenhang.',
        hintEn:
            'Sort it yourself: what is cause, what is effect, who acts? One sentence from the task is enough, then I will explain the next link.',
        isFinal: true,
      ),
    ]);
  }

  void _buildImage(String raw) {
    _kind = _Kind.image;
    final topics = [
      ...GemmaTopics.matchAll(raw),
      ...GemmaTopics.matchSymbols(raw),
    ];
    final extra = topics.isEmpty
        ? ''
        : '\n\n${GemmaTopics.format(topics, german: german)}';
    _steps.addAll([
      _Step(
        hintDe:
            'Bild oder Karikatur. Zuerst nur beschreiben: Personen, Gegenstände, Text, Vorder- und Hintergrund. Noch nicht deuten.$extra',
        hintEn:
            'Image or caricature. First only describe: people, objects, captions, foreground and background. Do not interpret yet.$extra',
      ),
      _Step(
        hintDe:
            'Jetzt analysieren: Was ist übertrieben? Welche Symbole? Wer ist groß, klein, oben, unten? Nenn, was du siehst — bekannte Symbole erkläre ich.',
        hintEn:
            'Now analyse: what is exaggerated? Which symbols? Who is large, small, high, low? Name what you see — I will explain known symbols.',
      ),
      _Step(
        hintDe:
            'Deutung: In welcher Lage entstand das Bild, wen greift der Zeichner an? Den Schlusssatz formulierst du. Frag nach, wenn ein Zusammenhang unklar ist.',
        hintEn:
            'Interpret: in which situation was this drawn, whom does the artist attack? You write the closing sentence. Ask if a connection is unclear.',
        isFinal: true,
      ),
    ]);
  }

  GemmaReply _continueHumanities(String text) {
    if (_asksForAnswer(text) && !_wantsExplain(text)) {
      return GemmaReply(
        text: german
            ? 'Die fertige Deutung oder den Klausursatz schreibe ich nicht. Ich erkläre den Zusammenhang — du setzt ihn in die Aufgabe.'
            : 'I will not write the finished interpretation. I explain the connection — you put it into the task.',
        chips: _stepChips(),
      );
    }

    final hits = [
      ...GemmaTopics.matchAll(text),
      ...GemmaTopics.matchSymbols(text),
    ];
    if (hits.isNotEmpty) {
      if (_step < _steps.length - 1) _step += 1;
      return GemmaReply(
        text:
            '${GemmaTopics.format(hits, german: german)}\n\n${_currentHint()}',
        chips: _stepChips(),
      );
    }

    if (_isStuck(text) || _wantsExplain(text)) {
      return GemmaReply(text: _currentHint(nudge: true), chips: _stepChips());
    }

    if (_step < _steps.length - 1) _step += 1;
    return GemmaReply(
      text: german
          ? 'Gut, das kannst du so in die Beschreibung nehmen.\n\n${_currentHint()}'
          : 'Good, you can use that in the description.\n\n${_currentHint()}',
      chips: _stepChips(),
    );
  }

  bool get _isMathKind =>
      _kind == _Kind.linear ||
      _kind == _Kind.equation ||
      _kind == _Kind.expression ||
      _kind == _Kind.trig ||
      _kind == _Kind.percent ||
      _kind == _Kind.derivative;

  bool get _isHumanitiesKind =>
      _kind == _Kind.history || _kind == _Kind.image;

  GemmaReply _checkGuess(double guess, String raw) {
    final step = _currentStep();
    if (step == null) {
      return GemmaReply(text: _t('needProblem'));
    }

    if (step.expected.isNotEmpty && _matchesAny(guess, step.expected)) {
      return _advance(correctFinal: step.isFinal);
    }

    final later = _laterExpected();
    if (later != null && _near(guess, later)) {
      return GemmaReply(
        text: _t('jumpedAhead'),
        chips: _stepChips(),
      );
    }

    if (step.expected.isEmpty) {
      return _advance(correctFinal: step.isFinal);
    }

    return GemmaReply(text: _t('notYet'), chips: _stepChips());
  }

  GemmaReply _checkDerivativeGuess(String raw) {
    for (final step in _steps) {
      final expected = step.expectedExpr;
      if (expected != null && _sameExpr(raw, expected)) {
        return _advance(correctFinal: true);
      }
    }
    return GemmaReply(text: _t('notYet'), chips: _stepChips());
  }

  GemmaReply _advance({required bool correctFinal}) {
    if (correctFinal) {
      _solved = true;
      return GemmaReply(text: _t('solved'), solved: true);
    }
    if (_step < _steps.length - 1) _step += 1;
    return GemmaReply(
      text: '${_t('goodStep')}\n\n${_currentHint()}',
      chips: _stepChips(),
    );
  }

  _Step? _currentStep() =>
      _steps.isEmpty ? null : _steps[_step.clamp(0, _steps.length - 1)];

  String _currentHint({bool nudge = false}) {
    final step = _currentStep();
    if (step == null) return _t('needProblem');
    final body = german ? step.hintDe : step.hintEn;
    if (!nudge) return body;
    return '${_t('stayWithStep')}\n\n$body';
  }

  String _opening() {
    final head = switch (_kind) {
      _Kind.linear || _Kind.equation =>
        german
            ? 'Das ist eine Gleichung. Ziel: x allein — ohne dass ich das Ergebnis nenne.\n\n'
            : 'This is an equation. Goal: isolate x — I will not name the result.\n\n',
      _Kind.expression =>
        german
            ? 'Eine Rechnung. Rechenregeln zuerst, Taschenrechner von dir.\n\n'
            : 'A calculation. Rules first, calculator is yours.\n\n',
      _Kind.trig =>
        german
            ? 'Eine Winkelfunktion. Einstellung prüfen, dann selbst tippen.\n\n'
            : 'A trig function. Check the mode, then type it yourself.\n\n',
      _Kind.percent =>
        german
            ? 'Eine Prozentaufgabe. Den Weg kennst du aus dem Tafelwerk.\n\n'
            : 'A percent problem. The method is in the formula book.\n\n',
      _Kind.derivative =>
        german
            ? 'Eine Ableitung. Die Regel holst du dir aus dem Tafelwerk.\n\n'
            : 'A derivative. Fetch the rule from the formula book.\n\n',
      _Kind.history =>
        german
            ? 'Geschichte — Zusammenhänge erkläre ich, die Antwortzeile schreibst du.\n\n'
            : 'History — I explain connections, you write the answer line.\n\n',
      _Kind.image =>
        german
            ? 'Bildquelle — Methode und Symbole erkläre ich, die Deutung bleibt bei dir.\n\n'
            : 'Image source — I explain method and symbols, the interpretation stays with you.\n\n',
      _Kind.other || _Kind.none =>
        german
            ? 'Wir gehen die Aufgabe Schritt für Schritt durch.\n\n'
            : 'We will walk through this step by step.\n\n',
    };
    return head;
  }

  List<String> _stepChips() {
    if (_solved) return const [];
    if (_kind == _Kind.image) {
      return german
          ? const ['Weiter', 'Was bedeutet das Symbol?', 'Ich hänge']
          : const ['Next', 'What does this symbol mean?', "I'm stuck"];
    }
    if (_kind == _Kind.history) {
      return german
          ? const ['Weiter', 'Warum hängt das zusammen?', 'Ich hänge']
          : const ['Next', 'Why are these linked?', "I'm stuck"];
    }
    return german
        ? const ['Weiter', 'Warum?', 'Ich hänge']
        : const ['Next', 'Why?', "I'm stuck"];
  }

  List<String> _startChips() => german
      ? const ['2x+3=11', 'Karikatur', 'Versailles']
      : const ['2x+3=11', 'Caricature', 'Versailles'];

  bool _looksLikeNewProblem(String text) {
    if (_problem == null) return _looksLikeMath(text);
    if (text == _problem) return false;
    if (_asksForAnswer(text) || _isStuck(text) || _wantsExplain(text)) {
      return false;
    }
    if (_extractNumber(text) != null && text.length < 12) return false;
    if (_kind == _Kind.derivative && _looksLikeExpr(text) && text.length < 24) {
      return false;
    }
    if (_isHumanitiesKind && (_isHumanities(text) || _isImageTalk(text))) {
      return false;
    }
    return _looksLikeMath(text) &&
        (text.contains('=') ||
            _isDerivativePrompt(text) ||
            _isTrig(text) ||
            _isPercent(text) ||
            (text.length > 8 && _looksLikeExpr(text)));
  }

  bool _looksLikeMath(String text) {
    final s = text.toLowerCase();
    if (_isDerivativePrompt(s) || _isPercent(s) || _isTrig(s)) return true;
    if (s.contains('=')) return true;
    return _looksLikeExpr(s);
  }

  bool _looksLikeExpr(String text) {
    final s = CalculatorEngine.prepareSource(text).toLowerCase();
    if (RegExp(r'\d+x|x\^|x\d').hasMatch(s)) return true;
    return RegExp(r'[\dxy]').hasMatch(s) &&
        RegExp(r'[+\-*/^()]|sin|cos|tan|sqrt|ln|log|exp').hasMatch(s);
  }

  bool _isDerivativePrompt(String text) {
    final s = text.toLowerCase();
    return s.contains('ableit') ||
        s.contains('differen') ||
        s.contains("f'") ||
        s.contains('d/dx') ||
        s.contains('derivative');
  }

  bool _isTrig(String text) {
    final s = text.toLowerCase();
    return RegExp(r'\b(a?sin|a?cos|a?tan|sinh|cosh|tanh)\s*\(').hasMatch(s);
  }

  bool _isPercent(String text) {
    final s = text.toLowerCase();
    return s.contains('%') || s.contains('prozent') || s.contains('percent');
  }

  bool _asksForAnswer(String text) {
    if (_wantsExplain(text) || _isHumanities(text) || _isImageTalk(text)) {
      return false;
    }
    final s = text.toLowerCase();
    return RegExp(
      r'\b(lösung|loesung|ergebnis|antwort|sag mir die lösung|gibt? mir|was kommt raus|wie viel ist|tell me the answer|give me the answer|the answer|solve it)\b',
    ).hasMatch(s);
  }

  bool _wantsExplain(String text) {
    final s = text.toLowerCase();
    return RegExp(
      r'erklär|erklaer|warum|wieso|weshalb|zusammenhang|bedeutet|was heißt|was heisst|versteh|explain|why\b|meaning|connection',
    ).hasMatch(s);
  }

  bool _isHumanities(String text) {
    final s = text.toLowerCase();
    if (GemmaTopics.match(s) != null) return true;
    return RegExp(
      r'geschichte|histor|weimar|revolution|krieg|politik|quelle|plakat|epoche|jahrhundert',
    ).hasMatch(s);
  }

  bool _isImageTalk(String text) {
    final s = text.toLowerCase();
    return RegExp(
      r'karikatur|caricature|cartoon|spottbild|bildquelle|bildanalyse|dieses bild|auf dem bild',
    ).hasMatch(s);
  }

  bool _isStuck(String text) {
    final s = text.toLowerCase().trim();
    return s == 'weiter' ||
        s == 'next' ||
        s.contains('hänge') ||
        s.contains('haenge') ||
        s.contains('stuck') ||
        s.contains('weiß nicht') ||
        s.contains('weiss nicht') ||
        s.contains("don't know") ||
        s.contains('hilfe');
  }

  String _stripLeadIn(String raw) {
    return raw
        .replaceFirst(
          RegExp(
            r"^(bitte\s+|kannst du\s+(mir\s+)?|löse\s+|solve\s+|berechne\s+|rechne\s+|was ist\s+|was ergibt\s+|ableitung von\s+|ableiten\s+|f'\s*(von\s+)?|d/dx\s*)",
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  String _derivativeTarget(String raw) {
    var s = _stripLeadIn(raw);
    s = s.replaceFirst(RegExp(r'^von\s+', caseSensitive: false), '');
    s = FunctionPlotPrep.normalizeExpression(s);
    return s.isEmpty ? 'x^2' : s;
  }

  _Linear? _parseLinear(String src) {
    final parts = src.split('=');
    if (parts.length != 2) return null;
    final left = parts[0];
    final right = parts[1];
    if (!src.toLowerCase().contains('x')) return null;

    double? at(String side, double x) {
      final r = _engine.evaluate(side, x: x);
      return r.ok ? r.value : null;
    }

    final l0 = at(left, 0);
    final l1 = at(left, 1);
    final r0 = at(right, 0);
    final r1 = at(right, 1);
    if (l0 == null || l1 == null || r0 == null || r1 == null) return null;

    final a = (l1 - l0) - (r1 - r0);
    final b = l0;
    final c = r0;
    if (a.abs() < 1e-9) return null;
    // Detect non-linear: f(2) should match linear prediction.
    final l2 = at(left, 2);
    final r2 = at(right, 2);
    if (l2 == null || r2 == null) return null;
    final predicted = (l0 + 2 * (l1 - l0)) - (r0 + 2 * (r1 - r0));
    if (((l2 - r2) - predicted).abs() > 1e-6) return null;

    final x = (c - b) / a;
    final mid = c - b;
    return _Linear(x: x, mid: mid);
  }

  double? _firstPointOp(String src) {
    final tokens = _engine.tokenizePublic(src);
    for (var i = 0; i < tokens.length - 2; i++) {
      final op = tokens[i + 1];
      if (op != '*' && op != '/') continue;
      final a = double.tryParse(tokens[i]);
      final b = double.tryParse(tokens[i + 2]);
      if (a == null || b == null) continue;
      if (op == '/' && b.abs() < 1e-12) continue;
      return op == '*' ? a * b : a / b;
    }
    return null;
  }

  double? _parsePercent(String src) {
    final m = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*%\s*(?:von|of)?\s*(\d+(?:[.,]\d+)?)',
      caseSensitive: false,
    ).firstMatch(src);
    if (m == null) return null;
    final p = _toDouble(m.group(1)!);
    final base = _toDouble(m.group(2)!);
    if (p == null || base == null) return null;
    return p / 100 * base;
  }

  double? _extractNumber(String text) {
    final eq = RegExp(
      r'x\s*=\s*(-?\d+(?:[.,]\d+)?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (eq != null) return _toDouble(eq.group(1)!);
    final lowered = text.toLowerCase();
    if (RegExp(r'[a-z]').hasMatch(lowered)) return null;
    final matches = RegExp(r'-?\d+(?:[.,]\d+)?').allMatches(text).toList();
    if (matches.length != 1) return null;
    return _toDouble(matches.first.group(0)!);
  }

  double? _laterExpected() {
    for (var i = _step + 1; i < _steps.length; i++) {
      if (_steps[i].expected.isNotEmpty) return _steps[i].expected.first;
    }
    return null;
  }

  bool _matchesAny(double guess, List<double> expected) =>
      expected.any((e) => _near(guess, e));

  bool _near(double a, double b) => (a - b).abs() <= 1e-6 * (1 + b.abs()) ||
      (a - b).abs() < 0.015;

  bool _sameExpr(String a, String b) {
    String norm(String s) => CalculatorEngine.prepareSource(s)
        .replaceAll(' ', '')
        .replaceAll('*', '')
        .toLowerCase();
    if (norm(a) == norm(b)) return true;
    // Numeric probe at a few x values.
    for (final x in const [0.5, 2.0, 3.0]) {
      final va = _engine.evaluate(a, x: x);
      final vb = _engine.evaluate(b, x: x);
      if (!va.ok || !vb.ok || !_near(va.value, vb.value)) return false;
    }
    return true;
  }

  void _hide(double value) {
    if (value.isFinite) _hidden.add(value);
  }

  double? _toDouble(String raw) => double.tryParse(raw.replaceAll(',', '.'));

  String _linearIntro(String src) =>
      'Die Gleichung ist „$src“. Markiere, was mit x zusammenhängt und was nicht. Noch nicht das Ergebnis ausrechnen.';

  String _linearIntroEn(String src) =>
      'The equation is “$src”. Mark what belongs with x and what does not. Do not compute the result yet.';

  String _t(String key) {
    const de = {
      'empty': 'Schreib die Aufgabe oder den nächsten Schritt.',
      'needProblem':
          'Schick die Aufgabe, eine Nachfrage („warum hängt das zusammen?“) oder ein Bild / eine Karikatur.',
      'refuseAnswer':
          'Die fertige Lösung sage ich nicht. Welchen Schritt kannst du selbst am Taschenrechner machen?',
      'jumpedAhead':
          'Du springst schon zum Endergebnis. Zeig mir zuerst das Zwischenergebnis des aktuellen Schritts.',
      'notYet':
          'Das passt noch nicht. Rechne den aktuellen Schritt noch einmal am Taschenrechner — ohne abzukürzen.',
      'goodStep': 'Der Schritt passt. Weiter.',
      'solved':
          'Dein Ergebnis stimmt. Gut, dass du selbst gerechnet hast.',
      'stayWithStep': 'Bleib bei diesem Schritt:',
    };
    const en = {
      'empty': 'Write the problem or the next step.',
      'needProblem':
          'Send the problem, a follow-up (“why are these linked?”), or a picture / caricature.',
      'refuseAnswer':
          'I will not give the finished answer. Which step can you do on the calculator yourself?',
      'jumpedAhead':
          'You are jumping to the final result. Show me the intermediate value for the current step first.',
      'notYet':
          'That does not fit yet. Do the current step again on the calculator — no shortcuts.',
      'goodStep': 'That step is right. Next.',
      'solved': 'Your result is correct. Good that you calculated it yourself.',
      'stayWithStep': 'Stay with this step:',
    };
    return (german ? de : en)[key] ?? key;
  }

  /// Values the tutor must not print. Used by tests.
  List<double> get hiddenValues => List.unmodifiable(_hidden);

  bool replyLeaks(String reply) {
    for (final value in _hidden) {
      if (_containsNumber(reply, value)) return true;
    }
    return false;
  }

  static bool _containsNumber(String text, double value) {
    String fmt(double v) {
      if (v == v.roundToDouble() && v.abs() < 1e12) return v.round().toString();
      var s = v.toStringAsFixed(6);
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
      return s;
    }

    final token = fmt(value);
    if (token.isEmpty) return false;
    return RegExp(
      '(?<![0-9.,])${RegExp.escape(token)}(?![0-9])',
    ).hasMatch(text);
  }
}

enum _Kind {
  none,
  linear,
  equation,
  expression,
  trig,
  percent,
  derivative,
  history,
  image,
  other,
}

class _Step {
  const _Step({
    required this.hintDe,
    required this.hintEn,
    this.expected = const [],
    this.expectedExpr,
    this.isFinal = false,
  });

  final String hintDe;
  final String hintEn;
  final List<double> expected;
  final String? expectedExpr;
  final bool isFinal;
}

class _Linear {
  const _Linear({required this.x, required this.mid});

  final double x;
  final double mid;
}
