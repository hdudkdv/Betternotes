import 'package:betternotes/features/search/fuzzy_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds OCR typos via Levenshtein', () {
    expect(FuzzyMatch.matches('Projekl', 'Projekt Start'), isTrue);
    expect(FuzzyMatch.matches('projekt', 'Mein Projekt'), isTrue);
    expect(FuzzyMatch.matches('xyzzy', 'Mein Projekt'), isFalse);
  });

  test('trigram score is high for similar long strings', () {
    expect(
      FuzzyMatch.trigramScore('photosynthese', 'photosynthese'),
      closeTo(1, 0.01),
    );
    expect(FuzzyMatch.levenshtein('katze', 'katze'), 0);
    expect(FuzzyMatch.levenshtein('katze', 'katze!'), 1);
  });
}
