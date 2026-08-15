import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/notebook_repository.dart';
import '../../../shared/utils/file_store.dart';
import 'assignment_models.dart';

/// Local teacher archive: `assignments/{runId}/` plus a prefs index.
/// Never written into `teacherWorkspaceV1`.
class AssignmentArchive {
  AssignmentArchive(this._repository, this._prefs);

  static const _indexKey = 'assignment_runs_index_v1';
  final NotebookRepository _repository;
  final SharedPreferences _prefs;
  final FileStore _files = createFileStore();

  Future<void> writeRun(AssignmentRun run) async {
    await _writeJson(_runPath(run.id), run.toJson());
    await _touchIndex(run);
  }

  Future<void> writeSummary(AssignmentSummary summary) async {
    await _writeJson(_summaryPath(summary.runId), summary.toJson());
  }

  Future<void> writeSubmission(AssignmentSubmission submission) async {
    await _writeJson(
      _submissionPath(submission.runId, submission.deviceId),
      submission.toJson(),
    );
  }

  Future<AssignmentRun?> readRun(String runId) async {
    final json = await _readJson(_runPath(runId));
    if (json == null) return null;
    return AssignmentRun.fromJson(json);
  }

  Future<AssignmentSummary?> readSummary(String runId) async {
    final json = await _readJson(_summaryPath(runId));
    if (json == null) return null;
    return AssignmentSummary.fromJson(json);
  }

  Future<List<AssignmentSubmission>> readSubmissions(String runId) async {
    final ids = _index()
        .where((item) => item['id'] == runId)
        .expand((item) => item['submissionIds'] as List? ?? const [])
        .map((id) => id.toString())
        .toList();
    if (ids.isEmpty) {
      // Fallback: try known prefs keys.
      final prefix = 'assignment_sub_${runId}_';
      final found = <AssignmentSubmission>[];
      for (final key in _prefs.getKeys()) {
        if (!key.startsWith(prefix)) continue;
        final raw = _prefs.getString(key);
        if (raw == null) continue;
        try {
          found.add(
            AssignmentSubmission.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            ),
          );
        } catch (_) {}
      }
      return found;
    }
    final out = <AssignmentSubmission>[];
    for (final deviceId in ids) {
      final json = await _readJson(_submissionPath(runId, deviceId));
      if (json != null) out.add(AssignmentSubmission.fromJson(json));
    }
    return out;
  }

  Future<List<AssignmentRun>> listRuns() async {
    final runs = <AssignmentRun>[];
    for (final item in _index()) {
      final id = item['id']?.toString();
      if (id == null) continue;
      final run = await readRun(id);
      if (run != null) runs.add(run);
    }
    runs.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return runs;
  }

  Future<void> _touchIndex(AssignmentRun run) async {
    final next = [
      for (final item in _index())
        if (item['id'] != run.id) item,
      {
        'id': run.id,
        'title': run.title,
        'startedAt': run.startedAt.toIso8601String(),
        'submissionIds': [
          for (final sub in await readSubmissions(run.id)) sub.deviceId,
        ],
      },
    ];
    await _prefs.setString(_indexKey, jsonEncode(next));
  }

  Future<void> indexSubmission(AssignmentSubmission submission) async {
    final next = [
      for (final item in _index())
        if (item['id'] == submission.runId)
          {
            ...item,
            'submissionIds': {
              ...[for (final id in item['submissionIds'] as List? ?? const []) id.toString()],
              submission.deviceId,
            }.toList(),
          }
        else
          item,
    ];
    await _prefs.setString(_indexKey, jsonEncode(next));
  }

  List<Map<String, dynamic>> _index() {
    try {
      final raw = _prefs.getString(_indexKey);
      if (raw == null || raw.isEmpty) return const [];
      return [
        for (final item in jsonDecode(raw) as List)
          Map<String, dynamic>.from(item as Map),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<String> _runPath(String runId) async =>
      p.join(await _root(), runId, 'run.json');

  Future<String> _summaryPath(String runId) async =>
      p.join(await _root(), runId, 'summary.json');

  Future<String> _submissionPath(String runId, String deviceId) async =>
      p.join(await _root(), runId, 'submissions', '$deviceId.json');

  Future<String> _root() async {
    final dir = await _repository.resolveFilesDir();
    return p.join(dir, 'assignments');
  }

  String _prefsKey(String path) => 'assignment_file:$path';

  Future<void> _writeJson(Future<String> pathFuture, Map<String, dynamic> json) async {
    final path = await pathFuture;
    final encoded = jsonEncode(json);
    await _prefs.setString(_prefsKey(path), encoded);
    if (kIsWeb) return;
    try {
      await _files.writeBytes(path, Uint8List.fromList(utf8.encode(encoded)));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _readJson(Future<String> pathFuture) async {
    final path = await pathFuture;
    final cached = _prefs.getString(_prefsKey(path));
    if (cached != null && cached.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(cached) as Map);
    }
    if (kIsWeb) return null;
    try {
      final bytes = await _files.readBytes(path);
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
    } catch (_) {
      return null;
    }
  }
}
