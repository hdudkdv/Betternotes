/// Local fuzzy matching (Levenshtein + trigrams) for the search index.
///
/// Finds notes even when OCR / ink recognition is slightly wrong
/// (e.g. query `Projekl` still hits indexed `Projekt`).
abstract final class FuzzyMatch {
  static bool matches(
    String query,
    String haystack, {
    double minRatio = 0.74,
  }) {
    final q = query.trim().toLowerCase();
    final text = haystack.trim().toLowerCase();
    if (q.isEmpty || text.isEmpty) return false;
    if (text.contains(q)) return true;

    for (final token in _tokens(text)) {
      if (token.contains(q) || q.contains(token) && token.length >= 4) {
        return true;
      }
      if (ratio(q, token) >= minRatio) return true;
      if (q.length >= 4 && token.length >= 4 && levenshtein(q, token) <= 2) {
        return true;
      }
    }

    if (q.length >= 5 && text.length >= 5) {
      return trigramScore(q, text) >= 0.45;
    }
    return false;
  }

  static double ratio(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final dist = levenshtein(a, b);
    return 1 - (dist / (a.length > b.length ? a.length : b.length));
  }

  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        final del = prev[j + 1] + 1;
        final ins = curr[j] + 1;
        final sub = prev[j] + cost;
        curr[j + 1] = del < ins
            ? (del < sub ? del : sub)
            : (ins < sub ? ins : sub);
      }
      for (var j = 0; j <= b.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }

  static double trigramScore(String a, String b) {
    final ta = _trigrams(a);
    final tb = _trigrams(b);
    if (ta.isEmpty || tb.isEmpty) return 0;
    var inter = 0;
    for (final t in ta) {
      if (tb.contains(t)) inter++;
    }
    return inter / (ta.length + tb.length - inter);
  }

  static Set<String> _trigrams(String input) {
    final padded = '  $input ';
    final out = <String>{};
    for (var i = 0; i < padded.length - 2; i++) {
      out.add(padded.substring(i, i + 3));
    }
    return out;
  }

  static Iterable<String> _tokens(String text) {
    return text
        .split(RegExp(r'[^a-z0-9äöüß]+', unicode: true))
        .where((t) => t.length >= 2);
  }
}
