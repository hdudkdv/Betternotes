import 'package:betternotes/features/teacher/catalog/catalog_models.dart';
import 'package:betternotes/features/teacher/catalog/catalog_pdf_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits Aufgabe headings and keeps the prompt text', () {
    const text = '''
Name: Klasse 8a
Aufgabe 1
Was ist 2 + 2?
Aufgabe 2
Nenne die Hauptstadt von Frankreich.
''';
    final drafts = CatalogPdfParser.split(text);
    expect(drafts, hasLength(2));
    expect(drafts[0].title, '1');
    expect(drafts[0].text, contains('2 + 2'));
    expect(drafts[0].text, isNot(contains('Aufgabe 2')));
    expect(drafts[1].title, '2');
    expect(drafts[1].text, contains('Hauptstadt'));
  });

  test('splits numbered items when Aufgabe headings are missing', () {
    const text = '''
1. Erkläre den Satz des Pythagoras.
2. Berechne die Fläche.
''';
    final drafts = CatalogPdfParser.split(text);
    expect(drafts, hasLength(2));
    expect(drafts[0].title, '1');
    expect(drafts[0].text, contains('Pythagoras'));
    expect(drafts[1].title, '2');
    expect(drafts[1].text, contains('Fläche'));
  });

  test('keeps a single worksheet as one draft', () {
    const text = 'Beschreibe den Wasserkreislauf.';
    final drafts = CatalogPdfParser.split(text);
    expect(drafts, hasLength(1));
    expect(drafts.single.text, contains('Wasserkreislauf'));
    expect(drafts.single.answerKind, AnswerKind.text);
  });

  test('detects multiple-choice options', () {
    const text = '''
Aufgabe 1
Welche Stadt ist die Hauptstadt?
a) Berlin
b) Paris
c) Rom
''';
    final drafts = CatalogPdfParser.split(text);
    expect(drafts, hasLength(1));
    expect(drafts.single.answerKind, AnswerKind.multipleChoice);
    expect(drafts.single.options, ['Berlin', 'Paris', 'Rom']);
    expect(drafts.single.text, contains('Hauptstadt'));
    expect(drafts.single.text, isNot(contains('Berlin')));
  });

  test('assigns source pages across a scanned worksheet', () {
    final drafts = CatalogPdfParser.splitPages([
      'Aufgabe 1\nRechne 3 + 4.',
      'Aufgabe 2\nRechne 8 - 2.',
    ]);
    expect(drafts, hasLength(2));
    expect(drafts[0].sourcePageIndexes, [0]);
    expect(drafts[1].sourcePageIndexes, [1]);
    expect(drafts[0].text, contains('3 + 4'));
    expect(drafts[1].text, isNot(contains('<<<PAGE')));
  });

  test('empty OCR pages become image-only drafts', () {
    final drafts = CatalogPdfParser.splitPages(['', '']);
    expect(drafts, hasLength(2));
    expect(drafts[0].sourcePageIndexes, [0]);
    expect(drafts[1].sourcePageIndexes, [1]);
  });

  test('catalog item survives json roundtrip', () {
    final original = CatalogItem.create(
      title: 'Brüche',
      subject: 'Mathe',
      schoolClass: '7a',
      germanState: 'nw',
    ).copyWith(needsReview: true);
    final restored = CatalogItem.fromJson(original.toJson());
    expect(restored, original);
  });
}
