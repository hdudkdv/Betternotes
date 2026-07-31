import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/content_models.dart';
import '../../data/repositories/notebook_repository.dart';
import '../planner/grade_period.dart';
import '../planner/planner_model.dart';

class CsvService {
  const CsvService();

  String flashcardsToCsv(List<Flashcard> cards, {String? deckTitle}) {
    final buf = StringBuffer();
    buf.writeln('deck,front,back');
    for (final c in cards) {
      buf.writeln(
        '${_esc(deckTitle ?? c.deckId)},${_esc(c.front)},${_esc(c.back)}',
      );
    }
    return buf.toString();
  }

  List<({String? deck, String front, String back})> parseFlashcardCsv(
    String raw,
  ) {
    final rows = _parse(raw);
    if (rows.isEmpty) return const [];
    final header = rows.first.map((e) => e.toLowerCase()).toList();
    final hasHeader =
        header.contains('front') ||
        header.contains('deck') ||
        header.contains('back');
    final start = hasHeader ? 1 : 0;
    final frontIdx = hasHeader ? header.indexOf('front') : 0;
    final backIdx = hasHeader
        ? (header.indexOf('back') >= 0 ? header.indexOf('back') : 1)
        : 1;
    final deckIdx = hasHeader ? header.indexOf('deck') : -1;
    final out = <({String? deck, String front, String back})>[];
    for (var i = start; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final front = frontIdx >= 0 && frontIdx < row.length ? row[frontIdx] : '';
      final back = backIdx >= 0 && backIdx < row.length ? row[backIdx] : '';
      if (front.trim().isEmpty && back.trim().isEmpty) continue;
      final deck = deckIdx >= 0 && deckIdx < row.length ? row[deckIdx] : null;
      out.add((deck: deck, front: front, back: back));
    }
    return out;
  }

  String gradesToCsv(List<GradeEntry> grades) {
    final buf = StringBuffer();
    buf.writeln('subject,date,value,scale,category,period,weight,note,title');
    for (final g in grades) {
      buf.writeln(
        [
          _esc(g.subject),
          _esc(g.date.toIso8601String().split('T').first),
          g.value?.toString() ?? '',
          _esc(g.scale.name),
          _esc(g.category.name),
          _esc(g.period.name),
          g.weight.toString(),
          _esc(g.note),
          _esc(g.title),
        ].join(','),
      );
    }
    return buf.toString();
  }

  List<GradeEntry> parseGradesCsv(String raw) {
    final rows = _parse(raw);
    if (rows.isEmpty) return const [];
    final header = rows.first.map((e) => e.toLowerCase()).toList();
    final hasHeader = header.contains('subject') || header.contains('value');
    final start = hasHeader ? 1 : 0;
    int idx(String key, int fallback) {
      if (!hasHeader) return fallback;
      final i = header.indexOf(key);
      return i >= 0 ? i : fallback;
    }

    final out = <GradeEntry>[];
    for (var i = start; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final subject = _at(row, idx('subject', 0));
      final dateRaw = _at(row, idx('date', 1));
      final valueRaw = _at(row, idx('value', 2));
      final scaleName = _at(row, idx('scale', 3));
      final categoryName = _at(row, idx('category', 4));
      final periodName = _at(row, idx('period', 5));
      final weight = double.tryParse(_at(row, idx('weight', 6))) ?? 1;
      final note = _at(row, idx('note', 7));
      final title = _at(row, idx('title', 8));
      final date = DateTime.tryParse(dateRaw) ?? DateTime.now();
      out.add(
        GradeEntry.create(
          subject: subject,
          date: date,
          value: valueRaw.isEmpty ? null : double.tryParse(valueRaw),
          scale: GradeScale.values.firstWhere(
            (s) => s.name == scaleName,
            orElse: () => GradeScale.german,
          ),
          category: GradeCategory.values.firstWhere(
            (c) => c.name == categoryName,
            orElse: () => GradeCategory.major,
          ),
          period: GradePeriod.values.firstWhere(
            (p) => p.name == periodName,
            orElse: () => GradePeriod.h1,
          ),
          note: note,
          title: title,
          weight: weight,
        ),
      );
    }
    return out;
  }

  Future<void> shareCsv(String csv, String filename) async {
    if (kIsWeb) {
      throw UnsupportedError('CSV share on web not supported');
    }
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(csv, encoding: utf8);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv', name: filename)],
      ),
    );
  }

  Future<String?> pickCsvText() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.first.bytes;
    if (bytes != null) return utf8.decode(bytes);
    final path = result.files.first.path;
    if (path == null || kIsWeb) return null;
    return File(path).readAsString();
  }

  Future<int> importFlashcardsToDeck({
    required NotebookRepository repo,
    required String deckId,
    required String csv,
  }) async {
    final rows = parseFlashcardCsv(csv);
    var count = 0;
    for (final row in rows) {
      await repo.saveFlashcard(
        Flashcard.create(deckId: deckId, front: row.front, back: row.back),
      );
      count++;
    }
    return count;
  }

  String _esc(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _at(List<String> row, int i) =>
      i >= 0 && i < row.length ? row[i].trim() : '';

  List<List<String>> _parse(String raw) {
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    for (var i = 0; i < raw.length; i++) {
      final ch = raw[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < raw.length && raw[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        row.add(field.toString());
        field = StringBuffer();
      } else if (ch == '\n') {
        row.add(field.toString());
        field = StringBuffer();
        if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
        row = [];
      } else if (ch == '\r') {
        // skip
      } else {
        field.write(ch);
      }
    }
    row.add(field.toString());
    if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
    return rows;
  }
}
