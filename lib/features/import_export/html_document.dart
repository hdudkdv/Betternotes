import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class HtmlBlock {
  const HtmlBlock({required this.text, this.heading = 0});

  final String text;

  /// 0 = paragraph, 1–3 = heading level.
  final int heading;
}

/// Turns HTML into structured blocks, then into a printable PDF.
class HtmlDocument {
  static List<HtmlBlock> parse(String html) {
    var source = html
        .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
          ' ',
        );

    final blocks = <HtmlBlock>[];

    void add(String raw, {int heading = 0}) {
      final text = _decode(_stripTags(raw)).replaceAll(RegExp(r'[ \t]+'), ' ').trim();
      if (text.isEmpty) return;
      blocks.add(HtmlBlock(text: text, heading: heading));
    }

    source = source.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    final tag = RegExp(
      r'<(h[1-3]|p|li|div|tr)(?:\s[^>]*)?>([\s\S]*?)</\1>',
      caseSensitive: false,
    );
    var cursor = 0;
    for (final match in tag.allMatches(source)) {
      final before = source.substring(cursor, match.start);
      add(before);
      final name = match.group(1)!.toLowerCase();
      final heading = switch (name) {
        'h1' => 1,
        'h2' => 2,
        'h3' => 3,
        _ => 0,
      };
      add(match.group(2) ?? '', heading: heading);
      cursor = match.end;
    }
    add(source.substring(cursor));

    if (blocks.isEmpty) {
      add(source);
    }
    return blocks;
  }

  static String titleOf(String html, {String fallback = ''}) {
    final match = RegExp(
      r'<title[^>]*>([\s\S]*?)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    final title = _decode(_stripTags(match?.group(1) ?? '')).trim();
    if (title.isNotEmpty) return title;
    final headings = parse(html).where((b) => b.heading > 0);
    return headings.isEmpty ? fallback : headings.first.text;
  }

  static Future<Uint8List> toPdfBytes(String html, {String? title}) async {
    final heading = title ?? titleOf(html);
    final blocks = parse(html);
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 52, 48, 56),
        build: (context) {
          return [
            if (heading.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Text(
                  heading,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            for (final block in blocks)
              if (block.heading > 0)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
                  child: pw.Text(
                    block.text,
                    style: pw.TextStyle(
                      fontSize: block.heading == 1
                          ? 16
                          : block.heading == 2
                          ? 14
                          : 12.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                )
              else
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Paragraph(
                    text: block.text,
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
                  ),
                ),
          ];
        },
      ),
    );
    return Uint8List.fromList(await doc.save());
  }

  static String _stripTags(String html) =>
      html.replaceAll(RegExp(r'<[^>]+>'), ' ');

  static String _decode(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'&#\d+;'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
