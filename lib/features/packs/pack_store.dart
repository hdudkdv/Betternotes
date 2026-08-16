import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PackStore {
  PackStore(this._prefs);

  final SharedPreferences _prefs;

  Map<String, dynamic> _read(String notebookId, String pack) {
    final raw = _prefs.getString('pack_${pack}_$notebookId');
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(
    String notebookId,
    String pack,
    Map<String, dynamic> data,
  ) {
    return _prefs.setString('pack_${pack}_$notebookId', jsonEncode(data));
  }

  List<String> snippets(String notebookId) {
    final list = _read(notebookId, 'dev')['snippets'] as List? ?? const [];
    return [for (final item in list) '$item'];
  }

  Future<void> saveSnippets(String notebookId, List<String> snippets) {
    return _write(notebookId, 'dev', {'snippets': snippets});
  }

  Map<String, List<String>> kanban(String notebookId) {
    final data = _read(notebookId, 'agile');
    List<String> col(String key) => [
      for (final item in (data[key] as List? ?? const [])) '$item',
    ];
    return {
      'todo': col('todo'),
      'doing': col('doing'),
      'done': col('done'),
    };
  }

  Future<void> saveKanban(
    String notebookId,
    Map<String, List<String>> board,
  ) {
    return _write(notebookId, 'agile', board);
  }

  Map<String, bool> habits(String notebookId) {
    final data = _read(notebookId, 'habits');
    return {
      for (final entry in data.entries)
        if (entry.value is bool) entry.key: entry.value as bool,
    };
  }

  Future<void> saveHabits(String notebookId, Map<String, bool> habits) {
    return _write(notebookId, 'habits', habits);
  }

  double timeSeconds(String notebookId) {
    return (_read(notebookId, 'time')['seconds'] as num?)?.toDouble() ?? 0;
  }

  Future<void> saveTimeSeconds(String notebookId, double seconds) {
    return _write(notebookId, 'time', {'seconds': seconds});
  }

  List<Map<String, String>> clients(String notebookId) {
    final list = _read(notebookId, 'crm')['clients'] as List? ?? const [];
    return [
      for (final item in list)
        if (item is Map)
          {for (final e in item.entries) e.key.toString(): '${e.value}'},
    ];
  }

  Future<void> saveClients(
    String notebookId,
    List<Map<String, String>> clients,
  ) {
    return _write(notebookId, 'crm', {'clients': clients});
  }
}
