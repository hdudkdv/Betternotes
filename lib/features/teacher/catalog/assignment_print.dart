import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'catalog_models.dart';

class AssignmentPrint {
  const AssignmentPrint();

  Future<void> printWithoutSolutions(CatalogItem item) async {
    final bytes = await buildPdf(item);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${item.title}.pdf',
    );
  }

  Future<void> shareWithoutSolutions(CatalogItem item) async {
    final bytes = await buildPdf(item);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${item.title}.pdf',
    );
  }

  Future<Uint8List> buildPdf(CatalogItem item) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(item.title, style: pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 6),
          pw.Text(
            [item.subject, item.schoolClass].where((s) => s.isNotEmpty).join(' · '),
          ),
          pw.SizedBox(height: 16),
          for (var i = 0; i < item.tasks.length; i++) ...[
            pw.Text(
              '${i + 1}. ${item.tasks[i].title}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            for (final part in item.tasks[i].parts)
              if (part.kind == TaskPartKind.text && part.text.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(part.text),
                )
              else if (part.kind == TaskPartKind.link && part.url.isNotEmpty)
                pw.Text(part.url),
            if (item.tasks[i].answerKind == AnswerKind.multipleChoice)
              for (final option in item.tasks[i].options)
                pw.Text('  ( ) ${option.text}'),
            if (item.tasks[i].answerKind == AnswerKind.matching) ...[
              pw.Text(
                item.tasks[i].leftItems.map((e) => e.text).join('  |  '),
              ),
              pw.Text(
                item.tasks[i].rightItems.map((e) => e.text).join('  |  '),
              ),
            ],
            pw.SizedBox(height: 14),
          ],
        ],
      ),
    );
    return Uint8List.fromList(await doc.save());
  }
}
