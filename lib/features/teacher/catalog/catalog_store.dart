import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../library/providers/library_providers.dart';
import 'catalog_import_service.dart';
import 'catalog_models.dart';

class CatalogNotifier extends StateNotifier<List<CatalogItem>> {
  CatalogNotifier(this._prefs) : super(const []) {
    _load();
  }

  static const _key = 'teacher_catalog_v1';
  final SharedPreferences _prefs;

  void _load() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      state = [
        for (final item in list)
          CatalogItem.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {}
  }

  Future<void> _save() async {
    await _prefs.setString(
      _key,
      jsonEncode([for (final item in state) item.toJson()]),
    );
  }

  Future<void> upsert(CatalogItem item) async {
    final next = [
      for (final existing in state)
        if (existing.id != item.id) existing,
    ];
    next.add(item.copyWith(updatedAt: DateTime.now()));
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = next;
    await _save();
  }

  Future<void> delete(String id) async {
    state = [for (final item in state) if (item.id != id) item];
    await _save();
  }

  Future<void> confirm(String id) async {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            needsReview: false,
            confirmed: true,
            updatedAt: DateTime.now(),
          )
        else
          item,
    ];
    await _save();
  }

  CatalogItem? byId(String id) {
    for (final item in state) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool get hasUnlockedPublicPool =>
      state.any((item) => item.visibility == CatalogVisibility.public);

  List<CatalogItem> search({
    String query = '',
    String? subject,
    String? schoolClass,
    String? germanState,
    CatalogKind? kind,
  }) {
    final needle = query.trim().toLowerCase();
    return [
      for (final item in state)
        if (_matches(item, needle, subject, schoolClass, germanState, kind))
          item,
    ];
  }

  bool _matches(
    CatalogItem item,
    String needle,
    String? subject,
    String? schoolClass,
    String? germanState,
    CatalogKind? kind,
  ) {
    if (kind != null && item.kind != kind) return false;
    if (subject != null &&
        subject.isNotEmpty &&
        item.subject.toLowerCase() != subject.toLowerCase()) {
      return false;
    }
    if (schoolClass != null &&
        schoolClass.isNotEmpty &&
        item.schoolClass.toLowerCase() != schoolClass.toLowerCase()) {
      return false;
    }
    if (germanState != null &&
        germanState.isNotEmpty &&
        item.germanState != germanState) {
      return false;
    }
    if (needle.isEmpty) return true;
    final hay = [
      item.title,
      item.subject,
      item.schoolClass,
      ...item.tags,
    ].join(' ').toLowerCase();
    return hay.contains(needle);
  }
}

final catalogProvider =
    StateNotifierProvider<CatalogNotifier, List<CatalogItem>>((ref) {
      return CatalogNotifier(ref.watch(sharedPreferencesProvider));
    });

final catalogImportServiceProvider = Provider<CatalogImportService>((ref) {
  return CatalogImportService(ref.watch(notebookRepositoryProvider));
});
