import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../library/providers/library_providers.dart';
import '../../planner/school_year.dart';
import 'gradebook_models.dart';

class GradebookNotifier extends StateNotifier<TeacherGradebook> {
  GradebookNotifier(this._prefs) : super(const TeacherGradebook()) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'teacherGradebookV1';
  static const _uuid = Uuid();

  void _load() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = TeacherGradebook.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<TeacherClassRoster> ensureClass(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return TeacherClassRoster(id: _uuid.v4(), name: trimmed);
    }
    final existing = state.classByName(trimmed);
    if (existing != null) return existing;
    final created = TeacherClassRoster(id: _uuid.v4(), name: trimmed);
    state = state.copyWith(classes: [...state.classes, created]);
    await _save();
    return created;
  }

  Future<void> ensureClasses(Iterable<String> names) async {
    var next = state.classes;
    var changed = false;
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final exists = next.any(
        (item) => item.name.trim().toLowerCase() == name.toLowerCase(),
      );
      if (exists) continue;
      next = [...next, TeacherClassRoster(id: _uuid.v4(), name: name)];
      changed = true;
    }
    if (!changed) return;
    state = state.copyWith(classes: next);
    await _save();
  }

  Future<void> renameClass(String classId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      classes: [
        for (final item in state.classes)
          if (item.id == classId) item.copyWith(name: trimmed) else item,
      ],
    );
    await _save();
  }

  Future<void> addStudent(String classId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      classes: [
        for (final item in state.classes)
          if (item.id == classId)
            item.copyWith(
              students: [
                ...item.students,
                RosterStudent(id: _uuid.v4(), name: trimmed),
              ],
            )
          else
            item,
      ],
    );
    await _save();
  }

  Future<void> renameStudent(
    String classId,
    String studentId,
    String name,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      classes: [
        for (final item in state.classes)
          if (item.id == classId)
            item.copyWith(
              students: [
                for (final student in item.students)
                  if (student.id == studentId)
                    student.copyWith(name: trimmed)
                  else
                    student,
              ],
            )
          else
            item,
      ],
    );
    await _save();
  }

  Future<void> removeStudent(String classId, String studentId) async {
    state = state.copyWith(
      classes: [
        for (final item in state.classes)
          if (item.id == classId)
            item.copyWith(
              students: [
                for (final student in item.students)
                  if (student.id != studentId) student,
              ],
              groups: [
                for (final group in item.groups)
                  group.copyWith(
                    studentIds: [
                      for (final id in group.studentIds)
                        if (id != studentId) id,
                    ],
                  ),
              ],
            )
          else
            item,
      ],
      grades: [
        for (final grade in state.grades)
          if (grade.studentId != studentId) grade,
      ],
    );
    await _save();
  }

  Future<ClassGroup?> addGroup(String classId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final created = ClassGroup(id: _uuid.v4(), name: trimmed);
    state = state.copyWith(
      classes: [
        for (final item in state.classes)
          if (item.id == classId)
            item.copyWith(groups: [...item.groups, created])
          else
            item,
      ],
    );
    await _save();
    return created;
  }

  Future<void> renameGroup(String classId, String groupId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      classes: [
        for (final item in state.classes)
          if (item.id == classId)
            item.copyWith(
              groups: [
                for (final group in item.groups)
                  if (group.id == groupId)
                    group.copyWith(name: trimmed)
                  else
                    group,
              ],
            )
          else
            item,
      ],
    );
    await _save();
  }

  Future<void> deleteGroup(String classId, String groupId) async {
    state = state.copyWith(
      classes: [
        for (final item in state.classes)
          if (item.id == classId)
            item.copyWith(
              groups: [
                for (final group in item.groups)
                  if (group.id != groupId) group,
              ],
            )
          else
            item,
      ],
    );
    await _save();
  }

  Future<void> setGroupMembers({
    required String classId,
    required String groupId,
    required List<String> studentIds,
  }) async {
    state = state.copyWith(
      classes: [
        for (final item in state.classes)
          if (item.id == classId)
            item.copyWith(
              groups: [
                for (final group in item.groups)
                  if (group.id == groupId)
                    group.copyWith(studentIds: List<String>.from(studentIds))
                  else
                    group,
              ],
            )
          else
            item,
      ],
    );
    await _save();
  }

  Future<ClassTopic> addTopic({
    required String classId,
    required String name,
    required int schoolYearStart,
  }) async {
    final trimmed = name.trim();
    final existing = state.topics.where(
      (topic) =>
          topic.classId == classId &&
          topic.schoolYearStart == schoolYearStart &&
          topic.name.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first;
    final created = ClassTopic(
      id: _uuid.v4(),
      classId: classId,
      name: trimmed,
      schoolYearStart: schoolYearStart,
    );
    state = state.copyWith(topics: [...state.topics, created]);
    await _save();
    return created;
  }

  Future<ClassAssessment> addAssessment({
    required String classId,
    required String topicId,
    required String title,
    required DateTime date,
  }) async {
    final created = ClassAssessment(
      id: _uuid.v4(),
      classId: classId,
      topicId: topicId,
      title: title.trim(),
      date: date,
      schoolYearStart: SchoolYear.fromDate(date).startYear,
    );
    state = state.copyWith(assessments: [...state.assessments, created]);
    await _save();
    return created;
  }

  Future<void> deleteAssessment(String assessmentId) async {
    state = state.copyWith(
      assessments: [
        for (final item in state.assessments)
          if (item.id != assessmentId) item,
      ],
      grades: [
        for (final grade in state.grades)
          if (grade.assessmentId != assessmentId) grade,
      ],
    );
    await _save();
  }

  Future<void> setGrades({
    required String assessmentId,
    required Map<String, int?> values,
  }) async {
    final kept = [
      for (final grade in state.grades)
        if (grade.assessmentId != assessmentId) grade,
    ];
    final added = [
      for (final entry in values.entries)
        if (entry.value != null)
          ClassGrade(
            assessmentId: assessmentId,
            studentId: entry.key,
            value: entry.value!.clamp(1, 6),
          ),
    ];
    state = state.copyWith(grades: [...kept, ...added]);
    await _save();
  }

  Map<String, int?> gradesForAssessment(String assessmentId) {
    return {
      for (final grade in state.grades)
        if (grade.assessmentId == assessmentId) grade.studentId: grade.value,
    };
  }

  Future<SavedPicker> addPicker({
    required String name,
    required String classId,
    required SavedPickerKind kind,
    String? groupId,
    bool connectedOnly = false,
  }) async {
    final created = SavedPicker(
      id: _uuid.v4(),
      name: name.trim(),
      classId: classId,
      kind: kind,
      groupId: groupId,
      connectedOnly: connectedOnly,
    );
    state = state.copyWith(
      pickers: [...state.pickers, created],
      activePickerId: created.id,
    );
    await _save();
    return created;
  }

  Future<void> selectPicker(String id) async {
    if (state.pickerById(id) == null) return;
    state = state.copyWith(activePickerId: id);
    await _save();
  }

  Future<void> updatePicker(SavedPicker picker) async {
    state = state.copyWith(
      pickers: [
        for (final item in state.pickers)
          if (item.id == picker.id) picker else item,
      ],
    );
    await _save();
  }

  Future<void> deletePicker(String id) async {
    final next = [for (final item in state.pickers) if (item.id != id) item];
    final activeGone = state.activePickerId == id || state.activePickerId == null;
    state = state.copyWith(
      pickers: next,
      activePickerId: activeGone
          ? (next.isEmpty ? null : next.first.id)
          : state.activePickerId,
      clearActivePicker: next.isEmpty,
    );
    await _save();
  }

  Future<void> recordPickerDraw({
    required String pickerId,
    required String drawnId,
    required String lastName,
    String? lastDetail,
  }) async {
    final picker = state.pickerById(pickerId);
    if (picker == null) return;
    final drawn = [
      for (final id in picker.drawnIds)
        if (id != drawnId) id,
      if (picker.isDatacheck) drawnId,
    ];
    await updatePicker(
      picker.copyWith(
        drawnIds: drawn,
        lastName: lastName,
        lastDetail: lastDetail ?? '',
      ),
    );
  }

  Future<void> resetPickerRound(String pickerId) async {
    final picker = state.pickerById(pickerId);
    if (picker == null) return;
    await updatePicker(picker.copyWith(drawnIds: const [], clearLast: true));
  }
}

final gradebookProvider =
    StateNotifierProvider<GradebookNotifier, TeacherGradebook>((ref) {
      return GradebookNotifier(ref.watch(sharedPreferencesProvider));
    });
