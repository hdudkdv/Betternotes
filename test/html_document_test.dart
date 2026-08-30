import 'package:betternotes/features/import_export/html_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const html = '''
    <html>
      <head><title>Klausur Hinweise</title></head>
      <body>
        <h1>Einleitung</h1>
        <p>Bitte die Aufgabe selbst rechnen.</p>
        <h2>Formeln</h2>
        <li>a² + b² = c²</li>
      </body>
    </html>
  ''';

  test('parses headings and paragraphs', () {
    final blocks = HtmlDocument.parse(html);
    expect(blocks.any((b) => b.heading == 1 && b.text.contains('Einleitung')), isTrue);
    expect(blocks.any((b) => b.text.contains('selbst rechnen')), isTrue);
    expect(blocks.any((b) => b.heading == 2 && b.text.contains('Formeln')), isTrue);
  });

  test('reads the document title', () {
    expect(HtmlDocument.titleOf(html, fallback: 'x'), 'Klausur Hinweise');
  });

  test('builds a PDF from HTML', () async {
    final bytes = await HtmlDocument.toPdfBytes(html);
    expect(bytes.length, greaterThan(200));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
