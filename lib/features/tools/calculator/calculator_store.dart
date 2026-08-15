import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CalcHistoryEntry {
  const CalcHistoryEntry({
    required this.expression,
    required this.result,
    required this.at,
  });

  final String expression;
  final String result;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'expression': expression,
    'result': result,
    'at': at.toIso8601String(),
  };

  factory CalcHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CalcHistoryEntry(
      expression: json['expression'] as String? ?? '',
      result: json['result'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class CalculatorStore {
  CalculatorStore(this._prefs);

  final SharedPreferences _prefs;

  String _key(String notebookId) => 'calc_history_$notebookId';

  List<CalcHistoryEntry> historyFor(String notebookId) {
    final raw = _prefs.getString(_key(notebookId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          CalcHistoryEntry.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(String notebookId, CalcHistoryEntry entry) async {
    final next = [entry, ...historyFor(notebookId)].take(40).toList();
    await _prefs.setString(
      _key(notebookId),
      jsonEncode([for (final e in next) e.toJson()]),
    );
  }
}
