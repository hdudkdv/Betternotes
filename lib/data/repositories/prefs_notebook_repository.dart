import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/editor/domain/ink_models.dart';
import '../../shared/utils/page_size.dart';
import '../models/content_models.dart';
import '../models/notebook.dart';
import 'content_extras_mixin.dart';
import 'notebook_repository.dart';

class PrefsNotebookRepository extends NotebookRepository
    with ContentExtrasMixin {
  PrefsNotebookRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _notebooksKey = 'bn_notebooks';
  static const _pagesPrefix = 'bn_pages_';
  static const _kvPrefix = 'bn_kv_';

  @override
  Future<String?> readKv(String key) async =>
      _prefs.getString('$_kvPrefix$key');

  @override
  Future<void> writeKv(String key, String value) async {
    await _prefs.setString('$_kvPrefix$key', value);
  }

  @override
  Future<void> deleteKv(String key) async {
    await _prefs.remove('$_kvPrefix$key');
  }

  List<Notebook> _readNotebooks() {
    final raw = _prefs.getString(_notebooksKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        Notebook.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<void> _writeNotebooks(List<Notebook> notebooks) async {
    await _prefs.setString(
      _notebooksKey,
      jsonEncode(notebooks.map((n) => n.toJson()).toList()),
    );
  }

  Future<List<NotePage>> _readPages(String notebookId) async {
    final raw = _prefs.getString('$_pagesPrefix$notebookId');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    final pages = [
      for (final item in list)
        NotePage.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    pages.sort((a, b) => a.index.compareTo(b.index));
    return pages;
  }

  Future<void> _writePages(String notebookId, List<NotePage> pages) async {
    await _prefs.setString(
      '$_pagesPrefix$notebookId',
      jsonEncode(pages.map((p) => p.toJson()).toList()),
    );
  }

  @override
  Future<String> resolveFilesDir() async => 'web_files';

  @override
  Future<List<Notebook>> getNotebooks({String query = ''}) async {
    var list = _readNotebooks();
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((n) => n.title.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      final aOpen = a.lastOpenedAt ?? a.updatedAt;
      final bOpen = b.lastOpenedAt ?? b.updatedAt;
      return bOpen.compareTo(aOpen);
    });
    return list;
  }

  @override
  Future<Notebook?> getNotebook(String id) async {
    try {
      return _readNotebooks().firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Notebook> createNotebook({
    required String title,
    required int coverColor,
    PageTemplate template = PageTemplate.blank,
    String? folderId,
    int? schoolClass,
    CanvasMode canvasMode = CanvasMode.page,
    PaperFormat paperFormat = PaperFormat.a4,
    PageOrientation orientation = PageOrientation.portrait,
  }) async {
    final notebook = Notebook.create(
      title: title,
      coverColor: coverColor,
      folderId: folderId,
      schoolClass: schoolClass,
      canvasMode: canvasMode,
      defaultPaperFormat: paperFormat,
      defaultOrientation: orientation,
      defaultTemplate: template,
    );
    final page = NotePage.create(
      notebookId: notebook.id,
      index: 0,
      template: template,
      paperFormat: paperFormat,
      orientation: orientation,
    );
    final notebooks = _readNotebooks()..add(notebook);
    await _writeNotebooks(notebooks);
    await _writePages(notebook.id, [page]);
    if (folderId != null) {
      await setNotebookFolderId(notebook.id, folderId);
    }
    if (schoolClass != null) {
      await setNotebookSchoolClass(notebook.id, schoolClass);
    }
    await enqueueSyncOp(
      SyncOp(
        id: const Uuid().v4(),
        entityType: 'notebook',
        entityId: notebook.id,
        payloadJson: jsonEncode(notebook.toJson()),
        createdAt: DateTime.now(),
      ),
    );
    return notebook;
  }

  @override
  Future<void> updateNotebook(Notebook notebook) async {
    final notebooks = _readNotebooks();
    final index = notebooks.indexWhere((n) => n.id == notebook.id);
    if (index < 0) return;
    notebooks[index] = notebook;
    await _writeNotebooks(notebooks);
    await setNotebookFolderId(notebook.id, notebook.folderId);
    await setNotebookSchoolClass(notebook.id, notebook.schoolClass);
    await setNotebookSubjectKey(notebook.id, notebook.subjectKey);
    await enqueueSyncOp(
      SyncOp(
        id: const Uuid().v4(),
        entityType: 'notebook',
        entityId: notebook.id,
        payloadJson: jsonEncode(notebook.toJson()),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> upsertRemoteNotebook(Notebook notebook) async {
    final notebooks = _readNotebooks();
    final index = notebooks.indexWhere((item) => item.id == notebook.id);
    if (index >= 0) {
      notebooks[index] = notebook;
    } else {
      notebooks.add(notebook);
    }
    await _writeNotebooks(notebooks);
    await setNotebookFolderId(notebook.id, notebook.folderId);
    await setNotebookSchoolClass(notebook.id, notebook.schoolClass);
    await setNotebookSubjectKey(notebook.id, notebook.subjectKey);
  }

  @override
  Future<void> deleteNotebook(String id) async {
    final notebooks = _readNotebooks()..removeWhere((n) => n.id == id);
    await _writeNotebooks(notebooks);
    await _prefs.remove('$_pagesPrefix$id');
    await deleteKv('outline_$id');
    await enqueueSyncOp(
      SyncOp(
        id: const Uuid().v4(),
        entityType: 'delete_notebook',
        entityId: id,
        payloadJson: jsonEncode({'id': id}),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<NotePage>> getPages(String notebookId) => _readPages(notebookId);

  @override
  Future<NotePage?> getPage(String pageId) async {
    final notebooks = _readNotebooks();
    for (final n in notebooks) {
      final pages = await _readPages(n.id);
      for (final p in pages) {
        if (p.id == pageId) return p;
      }
    }
    return null;
  }

  @override
  Future<NotePage> addPage({
    required String notebookId,
    PageTemplate template = PageTemplate.blank,
    String? backgroundPdfPath,
    String? paperTemplateId,
    PaperTemplate? customPaper,
    PaperFormat paperFormat = PaperFormat.a4,
    PageOrientation orientation = PageOrientation.portrait,
  }) async {
    final pages = await _readPages(notebookId);
    final page = NotePage.create(
      notebookId: notebookId,
      index: pages.length,
      template: template,
      backgroundPdfPath: backgroundPdfPath,
      paperTemplateId: paperTemplateId,
      customPaper: customPaper,
      paperFormat: paperFormat,
      orientation: orientation,
    );
    pages.add(page);
    await _writePages(notebookId, pages);

    final notebooks = _readNotebooks();
    final i = notebooks.indexWhere((n) => n.id == notebookId);
    if (i >= 0) {
      notebooks[i] = notebooks[i].copyWith(
        pageCount: pages.length,
        updatedAt: DateTime.now(),
      );
      await _writeNotebooks(notebooks);
    }
    await enqueueSyncOp(
      SyncOp(
        id: const Uuid().v4(),
        entityType: 'page',
        entityId: page.id,
        payloadJson: jsonEncode(page.toJson()),
        createdAt: DateTime.now(),
      ),
    );
    return page;
  }

  @override
  Future<List<NotePage>> addPages({
    required String notebookId,
    required List<NotePageDraft> drafts,
  }) async {
    if (drafts.isEmpty) return const [];
    final pages = await _readPages(notebookId);
    final created = <NotePage>[];
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final page = NotePage.create(
        notebookId: notebookId,
        index: pages.length + i,
        template: draft.template,
        backgroundPdfPath: draft.backgroundPdfPath,
        paperTemplateId: draft.paperTemplateId,
        customPaper: draft.customPaper,
        paperFormat: draft.paperFormat,
        orientation: draft.orientation,
      );
      created.add(page);
    }
    pages.addAll(created);
    await _writePages(notebookId, pages);

    final notebooks = _readNotebooks();
    final ni = notebooks.indexWhere((n) => n.id == notebookId);
    if (ni >= 0) {
      notebooks[ni] = notebooks[ni].copyWith(
        pageCount: pages.length,
        updatedAt: DateTime.now(),
      );
      await _writeNotebooks(notebooks);
    }
    for (final page in created) {
      await enqueueSyncOp(
        SyncOp(
          id: const Uuid().v4(),
          entityType: 'page',
          entityId: page.id,
          payloadJson: jsonEncode(page.toJson()),
          createdAt: DateTime.now(),
        ),
      );
    }
    return created;
  }

  @override
  Future<void> savePage(NotePage page) async {
    final timestampedPage = page.copyWith(updatedAt: DateTime.now());
    final pages = await _readPages(timestampedPage.notebookId);
    final i = pages.indexWhere((p) => p.id == timestampedPage.id);
    if (i >= 0) {
      pages[i] = timestampedPage;
    } else {
      pages.add(timestampedPage);
    }
    await _writePages(timestampedPage.notebookId, pages);

    final notebooks = _readNotebooks();
    final ni = notebooks.indexWhere((n) => n.id == timestampedPage.notebookId);
    if (ni >= 0) {
      notebooks[ni] = notebooks[ni].copyWith(updatedAt: DateTime.now());
      await _writeNotebooks(notebooks);
    }
    await enqueueSyncOp(
      SyncOp(
        id: const Uuid().v4(),
        entityType: 'page',
        entityId: timestampedPage.id,
        payloadJson: jsonEncode(timestampedPage.toJson()),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> upsertRemotePage(NotePage page) async {
    final pages = await _readPages(page.notebookId);
    final index = pages.indexWhere((item) => item.id == page.id);
    if (index >= 0) {
      pages[index] = page;
    } else {
      pages.add(page);
    }
    await _writePages(page.notebookId, pages);
  }

  @override
  Future<void> deletePage(String pageId) async {
    final notebooks = _readNotebooks();
    for (final n in notebooks) {
      final pages = await _readPages(n.id);
      final next = pages.where((p) => p.id != pageId).toList();
      if (next.length == pages.length) continue;
      for (var i = 0; i < next.length; i++) {
        next[i] = next[i].copyWith(index: i);
      }
      await _writePages(n.id, next);
      final ni = notebooks.indexWhere((x) => x.id == n.id);
      notebooks[ni] = notebooks[ni].copyWith(
        pageCount: next.length,
        updatedAt: DateTime.now(),
      );
      await _writeNotebooks(notebooks);
      await enqueueSyncOp(
        SyncOp(
          id: const Uuid().v4(),
          entityType: 'delete_page',
          entityId: pageId,
          payloadJson: jsonEncode({
            'id': pageId,
            'notebookId': n.id,
          }),
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
  }

  @override
  Future<void> touchOpened(String notebookId) async {
    final notebooks = _readNotebooks();
    final i = notebooks.indexWhere((n) => n.id == notebookId);
    if (i < 0) return;
    notebooks[i] = notebooks[i].copyWith(lastOpenedAt: DateTime.now());
    await _writeNotebooks(notebooks);
  }
}
