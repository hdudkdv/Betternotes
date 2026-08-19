import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme.dart';
import '../../../data/local/local_database.dart';
import '../../../data/models/content_models.dart';
import '../../../data/models/notebook.dart';
import '../../../data/repositories/notebook_repository.dart';
import '../../editor/domain/editor_gestures.dart';
import '../../editor/domain/ink_models.dart';
import '../../pdf/pdf_service.dart';
import '../../planner/education_settings.dart';
import '../../search/search_query.dart';

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  return LocalDatabase.repository;
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService(ref.watch(notebookRepositoryProvider));
});

final libraryQueryProvider = StateProvider<String>((ref) => '');

final currentFolderIdProvider = StateProvider<String?>((ref) => null);

/// Bump to force every library list to refetch (create / delete / rename).
final libraryEpochProvider = StateProvider<int>((ref) => 0);

void refreshLibraryLists(WidgetRef ref) {
  ref.read(libraryEpochProvider.notifier).state++;
  ref.invalidate(notebooksProvider);
  ref.invalidate(foldersProvider);
  ref.invalidate(allFoldersProvider);
  ref.invalidate(flashcardDecksProvider);
  ref.invalidate(firstPageProvider);
}

final notebooksProvider = FutureProvider.autoDispose<List<Notebook>>((
  ref,
) async {
  ref.watch(libraryEpochProvider);
  final folderId = ref.watch(currentFolderIdProvider);
  final repo = ref.watch(notebookRepositoryProvider);
  final all = await repo.getNotebooks();
  return all.where((n) => n.folderId == folderId).toList();
});

final allNotebooksProvider = FutureProvider.autoDispose<List<Notebook>>((
  ref,
) async {
  ref.watch(libraryEpochProvider);
  return ref.watch(notebookRepositoryProvider).getNotebooks();
});

final foldersProvider = FutureProvider.autoDispose<List<LibraryFolder>>((
  ref,
) async {
  ref.watch(libraryEpochProvider);
  final folderId = ref.watch(currentFolderIdProvider);
  final repo = ref.watch(notebookRepositoryProvider);
  return repo.getFolders(parentId: folderId);
});

final flashcardDecksProvider = FutureProvider.autoDispose<List<FlashcardDeck>>((
  ref,
) async {
  final folderId = ref.watch(currentFolderIdProvider);
  final repo = ref.watch(notebookRepositoryProvider);
  return repo.getFlashcardDecks(folderId: folderId);
});

final librarySearchProvider = FutureProvider.autoDispose<List<SearchHit>>((
  ref,
) async {
  final query = ref.watch(libraryQueryProvider);
  final parsed = ParsedSearchQuery.parse(query);
  if (parsed.isEmpty) return [];
  if (!parsed.hasFilters && parsed.text.trim().length < 2) return [];
  return ref.watch(notebookRepositoryProvider).globalSearch(query);
});

final allFoldersProvider = FutureProvider.autoDispose<List<LibraryFolder>>((
  ref,
) {
  return ref.watch(notebookRepositoryProvider).getAllFolders();
});

/// First page of a notebook, for library cover previews.
final firstPageProvider = FutureProvider.autoDispose.family<NotePage?, String>((
  ref,
  notebookId,
) async {
  ref.watch(libraryEpochProvider);
  final pages = await ref.watch(notebookRepositoryProvider).getPages(notebookId);
  if (pages.isEmpty) return null;
  final sorted = [...pages]..sort((a, b) => a.index.compareTo(b.index));
  return sorted.first;
});

enum AppUserRole { student, teacher }

/// Teachers still studying vs already qualified.
enum TeacherTrack { studying, qualified }

class AppSettings {
  const AppSettings({
    this.fingerPanZoom = false,
    this.defaultTemplate = PageTemplate.lined,
    this.localeCode = 'system',
    this.pageBrowseMode = PageBrowseMode.swipeHorizontal,
    this.educationLevel = EducationLevel.sek1,
    this.germanState = GermanState.nw,
    this.targetEcts = 180,
    this.abiCourseCount = 40,
    this.abiExamCount = 4,
    this.look = AppLook.studio,
    this.themeMode = ThemeMode.system,
    this.userRole,
    this.teacherTrack,
    this.profileSetupCompleted = false,
    this.pencilDoubleTapAction = EditorGestureAction.toggleEraser,
    this.pencilSqueezeAction = EditorGestureAction.openToolWheel,
    this.twoFingerTapAction = EditorGestureAction.undo,
    this.threeFingerSwipeLeftAction = EditorGestureAction.previousPage,
    this.threeFingerSwipeRightAction = EditorGestureAction.nextPage,
  });

  factory AppSettings.fromPrefs(SharedPreferences prefs) {
    return AppSettings(
      fingerPanZoom: prefs.getBool('fingerPanZoomV2') ?? false,
      defaultTemplate: PageTemplate.values.firstWhere(
        (t) => t.name == (prefs.getString('defaultTemplate') ?? 'lined'),
        orElse: () => PageTemplate.lined,
      ),
      localeCode: prefs.getString('localeCode') ?? 'system',
      pageBrowseMode: PageBrowseMode.values.firstWhere(
        (m) => m.name == (prefs.getString('pageBrowseMode') ?? ''),
        orElse: () => PageBrowseMode.swipeHorizontal,
      ),
      educationLevel: EducationLevel.values.firstWhere(
        (e) => e.name == (prefs.getString('educationLevel') ?? ''),
        orElse: () => EducationLevel.sek1,
      ),
      germanState: GermanState.values.firstWhere(
        (s) => s.name == (prefs.getString('germanState') ?? ''),
        orElse: () => GermanState.nw,
      ),
      targetEcts: prefs.getInt('targetEcts') ?? 180,
      abiCourseCount: prefs.getInt('abiCourseCount') ?? 40,
      abiExamCount: prefs.getInt('abiExamCount') ?? 4,
      look: AppLook.values.firstWhere(
        (l) => l.name == (prefs.getString('appLook') ?? ''),
        orElse: () => AppLook.studio,
      ),
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == (prefs.getString('themeMode') ?? ''),
        orElse: () => ThemeMode.system,
      ),
      userRole: prefs.getString('userRole') == null
          ? null
          : AppUserRole.values.firstWhere(
              (role) => role.name == prefs.getString('userRole'),
              orElse: () => AppUserRole.student,
            ),
      teacherTrack: prefs.getString('teacherTrack') == null
          ? null
          : TeacherTrack.values.firstWhere(
              (track) => track.name == prefs.getString('teacherTrack'),
              orElse: () => TeacherTrack.qualified,
            ),
      profileSetupCompleted:
          prefs.getBool('profileSetupCompleted') ??
          prefs.getString('userRole') != null,
      pencilDoubleTapAction: EditorGestureActionX.parse(
        prefs.getString('gesturePencilDoubleTap'),
        EditorGestureAction.toggleEraser,
      ),
      pencilSqueezeAction: EditorGestureActionX.parse(
        prefs.getString('gesturePencilSqueeze'),
        EditorGestureAction.openToolWheel,
      ),
      twoFingerTapAction: EditorGestureActionX.parse(
        prefs.getString('gestureTwoFingerTap'),
        EditorGestureAction.undo,
      ),
      threeFingerSwipeLeftAction: EditorGestureActionX.parse(
        prefs.getString('gestureThreeFingerSwipeLeft'),
        EditorGestureAction.previousPage,
      ),
      threeFingerSwipeRightAction: EditorGestureActionX.parse(
        prefs.getString('gestureThreeFingerSwipeRight'),
        EditorGestureAction.nextPage,
      ),
    );
  }

  final bool fingerPanZoom;
  final PageTemplate defaultTemplate;

  /// `system`, `de`, or `en`.
  final String localeCode;
  final PageBrowseMode pageBrowseMode;
  final EducationLevel educationLevel;
  final GermanState germanState;

  final EditorGestureAction pencilDoubleTapAction;
  final EditorGestureAction pencilSqueezeAction;
  final EditorGestureAction twoFingerTapAction;
  final EditorGestureAction threeFingerSwipeLeftAction;
  final EditorGestureAction threeFingerSwipeRightAction;

  /// Bachelor-Ziel ECTS (typisch 180).
  final int targetEcts;

  /// Kurse für Block-I-Hochrechnung (meist ~40).
  final int abiCourseCount;

  /// Anzahl Abiturprüfungen (4 oder 5).
  final int abiExamCount;

  /// Visual identity of the whole app.
  final AppLook look;

  /// Whether the look renders light, dark, or follows the system.
  final ThemeMode themeMode;

  /// Null until the first-start role choice has been completed.
  final AppUserRole? userRole;

  /// Only set for teachers after the profile step.
  final TeacherTrack? teacherTrack;

  /// True after role + school/study details are saved.
  final bool profileSetupCompleted;

  bool get hasCompletedRoleOnboarding => userRole != null;
  bool get hasCompletedProfileSetup =>
      userRole != null && profileSetupCompleted;
  bool get isTeacher => userRole == AppUserRole.teacher;

  Locale? get localeOverride {
    switch (localeCode) {
      case 'de':
        return const Locale('de');
      case 'en':
        return const Locale('en');
      default:
        return null;
    }
  }

  AppSettings copyWith({
    bool? fingerPanZoom,
    PageTemplate? defaultTemplate,
    String? localeCode,
    PageBrowseMode? pageBrowseMode,
    EducationLevel? educationLevel,
    GermanState? germanState,
    int? targetEcts,
    int? abiCourseCount,
    int? abiExamCount,
    AppLook? look,
    ThemeMode? themeMode,
    AppUserRole? userRole,
    TeacherTrack? teacherTrack,
    bool? profileSetupCompleted,
    bool clearUserRole = false,
    bool clearTeacherTrack = false,
    EditorGestureAction? pencilDoubleTapAction,
    EditorGestureAction? pencilSqueezeAction,
    EditorGestureAction? twoFingerTapAction,
    EditorGestureAction? threeFingerSwipeLeftAction,
    EditorGestureAction? threeFingerSwipeRightAction,
  }) {
    return AppSettings(
      fingerPanZoom: fingerPanZoom ?? this.fingerPanZoom,
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
      localeCode: localeCode ?? this.localeCode,
      pageBrowseMode: pageBrowseMode ?? this.pageBrowseMode,
      educationLevel: educationLevel ?? this.educationLevel,
      germanState: germanState ?? this.germanState,
      targetEcts: targetEcts ?? this.targetEcts,
      abiCourseCount: abiCourseCount ?? this.abiCourseCount,
      abiExamCount: abiExamCount ?? this.abiExamCount,
      look: look ?? this.look,
      themeMode: themeMode ?? this.themeMode,
      userRole: clearUserRole ? null : (userRole ?? this.userRole),
      teacherTrack: clearTeacherTrack
          ? null
          : (teacherTrack ?? this.teacherTrack),
      profileSetupCompleted:
          profileSetupCompleted ?? this.profileSetupCompleted,
      pencilDoubleTapAction:
          pencilDoubleTapAction ?? this.pencilDoubleTapAction,
      pencilSqueezeAction: pencilSqueezeAction ?? this.pencilSqueezeAction,
      twoFingerTapAction: twoFingerTapAction ?? this.twoFingerTapAction,
      threeFingerSwipeLeftAction:
          threeFingerSwipeLeftAction ?? this.threeFingerSwipeLeftAction,
      threeFingerSwipeRightAction:
          threeFingerSwipeRightAction ?? this.threeFingerSwipeRightAction,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(AppSettings.fromPrefs(_prefs));

  final SharedPreferences _prefs;

  void reloadFromPrefs() {
    state = AppSettings.fromPrefs(_prefs);
  }

  Future<void> setFingerPanZoom(bool value) async {
    state = state.copyWith(fingerPanZoom: value);
    await _prefs.setBool('fingerPanZoomV2', value);
  }

  Future<void> setDefaultTemplate(PageTemplate value) async {
    state = state.copyWith(defaultTemplate: value);
    await _prefs.setString('defaultTemplate', value.name);
  }

  Future<void> setLocaleCode(String value) async {
    state = state.copyWith(localeCode: value);
    await _prefs.setString('localeCode', value);
  }

  Future<void> setPageBrowseMode(PageBrowseMode value) async {
    state = state.copyWith(pageBrowseMode: value);
    await _prefs.setString('pageBrowseMode', value.name);
  }

  Future<void> setEducationLevel(EducationLevel value) async {
    state = state.copyWith(educationLevel: value);
    await _prefs.setString('educationLevel', value.name);
  }

  Future<void> setGermanState(GermanState value) async {
    state = state.copyWith(germanState: value);
    await _prefs.setString('germanState', value.name);
  }

  Future<void> setTargetEcts(int value) async {
    state = state.copyWith(targetEcts: value.clamp(30, 360));
    await _prefs.setInt('targetEcts', state.targetEcts);
  }

  Future<void> setAbiCourseCount(int value) async {
    state = state.copyWith(abiCourseCount: value.clamp(20, 48));
    await _prefs.setInt('abiCourseCount', state.abiCourseCount);
  }

  Future<void> setAbiExamCount(int value) async {
    state = state.copyWith(abiExamCount: value.clamp(4, 5));
    await _prefs.setInt('abiExamCount', state.abiExamCount);
  }

  Future<void> setLook(AppLook value) async {
    state = state.copyWith(look: value);
    await _prefs.setString('appLook', value.name);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    state = state.copyWith(themeMode: value);
    await _prefs.setString('themeMode', value.name);
  }

  Future<void> setUserRole(AppUserRole value) async {
    state = state.copyWith(userRole: value);
    await _prefs.setString('userRole', value.name);
  }

  Future<void> setTeacherTrack(TeacherTrack? value) async {
    if (value == null) {
      state = state.copyWith(clearTeacherTrack: true);
      await _prefs.remove('teacherTrack');
      return;
    }
    state = state.copyWith(teacherTrack: value);
    await _prefs.setString('teacherTrack', value.name);
  }

  Future<void> completeProfileSetup() async {
    state = state.copyWith(profileSetupCompleted: true);
    await _prefs.setBool('profileSetupCompleted', true);
  }

  Future<void> setGestureAction(
    EditorGestureSlot slot,
    EditorGestureAction action,
  ) async {
    switch (slot) {
      case EditorGestureSlot.pencilDoubleTap:
        state = state.copyWith(pencilDoubleTapAction: action);
        await _prefs.setString('gesturePencilDoubleTap', action.name);
      case EditorGestureSlot.pencilSqueeze:
        state = state.copyWith(pencilSqueezeAction: action);
        await _prefs.setString('gesturePencilSqueeze', action.name);
      case EditorGestureSlot.twoFingerTap:
        state = state.copyWith(twoFingerTapAction: action);
        await _prefs.setString('gestureTwoFingerTap', action.name);
      case EditorGestureSlot.threeFingerSwipeLeft:
        state = state.copyWith(threeFingerSwipeLeftAction: action);
        await _prefs.setString('gestureThreeFingerSwipeLeft', action.name);
      case EditorGestureSlot.threeFingerSwipeRight:
        state = state.copyWith(threeFingerSwipeRightAction: action);
        await _prefs.setString('gestureThreeFingerSwipeRight', action.name);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  throw UnimplementedError('settingsProvider must be overridden');
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});
