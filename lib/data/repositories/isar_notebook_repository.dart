import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../features/editor/domain/ink_models.dart';
import '../../shared/utils/page_size.dart';
import '../local/isar_entities.dart';
import '../local/local_database_native.dart';
import '../models/content_models.dart';
import '../models/notebook.dart';
import 'content_extras_mixin.dart';
import 'notebook_repository.dart';

class IsarNotebookRepository extends NotebookRepository
    with ContentExtrasMixin {
  IsarNotebookRepository(this._isar, this._filesDir);

  final Isar _isar;
  final String _filesDir;

  @override
  Future<String?> readKv(String key) async {
    final e = await _isar.kvEntitys.filter().keyEqualTo(key).findFirst();
    return e?.valueJson;
  }

  @override
  Future<void> writeKv(String key, String value) async {
    final existing = await _isar.kvEntitys.filter().keyEqualTo(key).findFirst();
    final entity = existing ?? KvEntity();
    entity.key = key;
    entity.valueJson = value;
    await _isar.writeTxn(() async {
      await _isar.kvEntitys.put(entity);
    });
  }

  @override
  Future<void> deleteKv(String key) async {
    final existing = await _isar.kvEntitys.filter().keyEqualTo(key).findFirst();
    if (existing == null) return;
    await _isar.writeTxn(() async {
      await _isar.kvEntitys.delete(existing.id);
    });
  }

  @override
  Future<String> resolveFilesDir() async {
    return p.join(_filesDir, 'betternotes_files');
  }

  @override
  Future<List<Notebook>> getNotebooks({String query = ''}) async {
    final all = await _isar.notebookEntitys.where().findAll();
    final folderMap = await readNotebookFolderMap();
    final classMap = await readNotebookSchoolClassMap();
    final subjectMap = await readNotebookSubjectMap();
    var list = all.map((e) {
      final nb = notebookFromEntity(e);
      return nb.copyWith(
        folderId: folderMap[nb.id],
        schoolClass: classMap[nb.id],
        subjectKey: subjectMap[nb.id],
      );
    }).toList();
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
    final e = await _isar.notebookEntitys.filter().uuidEqualTo(id).findFirst();
    if (e == null) return null;
    final nb = notebookFromEntity(e);
    final folderId = await notebookFolderId(id);
    final schoolClass = await notebookSchoolClass(id);
    final subjectKey = await notebookSubjectKey(id);
    return nb.copyWith(
      folderId: folderId,
      schoolClass: schoolClass,
      subjectKey: subjectKey,
    );
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

    final notebookEntity = NotebookEntity();
    applyNotebookToEntity(notebook, notebookEntity);
    final pageEntity = PageEntity()
      ..strokesJson = '[]'
      ..textBlocksJson = '[]';
    applyPageToEntity(page, pageEntity);

    await _isar.writeTxn(() async {
      await _isar.notebookEntitys.put(notebookEntity);
      await _isar.pageEntitys.put(pageEntity);
    });

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
    final existing = await _isar.notebookEntitys
        .filter()
        .uuidEqualTo(notebook.id)
        .findFirst();
    if (existing == null) return;
    applyNotebookToEntity(notebook, existing);
    await _isar.writeTxn(() async {
      await _isar.notebookEntitys.put(existing);
    });
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
    final existing = await _isar.notebookEntitys
        .filter()
        .uuidEqualTo(notebook.id)
        .findFirst();
    final entity = existing ?? NotebookEntity();
    applyNotebookToEntity(notebook, entity);
    await _isar.writeTxn(() async {
      await _isar.notebookEntitys.put(entity);
    });
    await setNotebookFolderId(notebook.id, notebook.folderId);
    await setNotebookSchoolClass(notebook.id, notebook.schoolClass);
    await setNotebookSubjectKey(notebook.id, notebook.subjectKey);
  }

  @override
  Future<void> deleteNotebook(String id) async {
    final notebook = await _isar.notebookEntitys
        .filter()
        .uuidEqualTo(id)
        .findFirst();
    final pages = await _isar.pageEntitys
        .filter()
        .notebookIdEqualTo(id)
        .findAll();
    await _isar.writeTxn(() async {
      if (notebook != null) {
        await _isar.notebookEntitys.delete(notebook.id);
      }
      for (final page in pages) {
        await _isar.pageEntitys.delete(page.id);
      }
    });
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
  Future<List<NotePage>> getPages(String notebookId) async {
    final pages = await _isar.pageEntitys
        .filter()
        .notebookIdEqualTo(notebookId)
        .findAll();
    pages.sort((a, b) => a.index.compareTo(b.index));
    return pages.map(pageFromEntity).toList();
  }

  @override
  Future<NotePage?> getPage(String pageId) async {
    final e = await _isar.pageEntitys.filter().uuidEqualTo(pageId).findFirst();
    return e == null ? null : pageFromEntity(e);
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
    final pages = await getPages(notebookId);
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
    final entity = PageEntity()
      ..strokesJson = '[]'
      ..textBlocksJson = '[]';
    applyPageToEntity(page, entity);

    final notebook = await _isar.notebookEntitys
        .filter()
        .uuidEqualTo(notebookId)
        .findFirst();

    await _isar.writeTxn(() async {
      await _isar.pageEntitys.put(entity);
      if (notebook != null) {
        notebook.pageCount = pages.length + 1;
        notebook.updatedAt = DateTime.now();
        await _isar.notebookEntitys.put(notebook);
      }
    });
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
    final existing = await getPages(notebookId);
    final created = <NotePage>[];
    final entities = <PageEntity>[];
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final page = NotePage.create(
        notebookId: notebookId,
        index: existing.length + i,
        template: draft.template,
        backgroundPdfPath: draft.backgroundPdfPath,
        paperTemplateId: draft.paperTemplateId,
        customPaper: draft.customPaper,
        paperFormat: draft.paperFormat,
        orientation: draft.orientation,
      );
      final entity = PageEntity()
        ..strokesJson = '[]'
        ..textBlocksJson = '[]';
      applyPageToEntity(page, entity);
      created.add(page);
      entities.add(entity);
    }

    final notebook = await _isar.notebookEntitys
        .filter()
        .uuidEqualTo(notebookId)
        .findFirst();

    await _isar.writeTxn(() async {
      await _isar.pageEntitys.putAll(entities);
      if (notebook != null) {
        notebook.pageCount = existing.length + created.length;
        notebook.updatedAt = DateTime.now();
        await _isar.notebookEntitys.put(notebook);
      }
    });

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
    final existing = await _isar.pageEntitys
        .filter()
        .uuidEqualTo(timestampedPage.id)
        .findFirst();
    final entity =
        existing ??
        (PageEntity()
          ..strokesJson = '[]'
          ..textBlocksJson = '[]');
    applyPageToEntity(timestampedPage, entity);

    final notebook = await _isar.notebookEntitys
        .filter()
        .uuidEqualTo(timestampedPage.notebookId)
        .findFirst();

    await _isar.writeTxn(() async {
      await _isar.pageEntitys.put(entity);
      if (notebook != null) {
        notebook.updatedAt = DateTime.now();
        await _isar.notebookEntitys.put(notebook);
      }
    });

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
    final existing = await _isar.pageEntitys
        .filter()
        .uuidEqualTo(page.id)
        .findFirst();
    final entity =
        existing ??
        (PageEntity()
          ..strokesJson = '[]'
          ..textBlocksJson = '[]');
    applyPageToEntity(page, entity);
    await _isar.writeTxn(() async {
      await _isar.pageEntitys.put(entity);
    });
  }

  @override
  Future<void> deletePage(String pageId) async {
    final page = await _isar.pageEntitys
        .filter()
        .uuidEqualTo(pageId)
        .findFirst();
    if (page == null) return;
    final notebookId = page.notebookId;
    await _isar.writeTxn(() async {
      await _isar.pageEntitys.delete(page.id);
    });
    final remaining = await getPages(notebookId);
    for (var i = 0; i < remaining.length; i++) {
      await savePage(remaining[i].copyWith(index: i));
    }
    final notebook = await _isar.notebookEntitys
        .filter()
        .uuidEqualTo(notebookId)
        .findFirst();
    if (notebook != null) {
      notebook.pageCount = remaining.length;
      notebook.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.notebookEntitys.put(notebook);
      });
    }
    await enqueueSyncOp(
      SyncOp(
        id: const Uuid().v4(),
        entityType: 'delete_page',
        entityId: pageId,
        payloadJson: jsonEncode({
          'id': pageId,
          'notebookId': notebookId,
        }),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> touchOpened(String notebookId) async {
    final notebook = await _isar.notebookEntitys
        .filter()
        .uuidEqualTo(notebookId)
        .findFirst();
    if (notebook == null) return;
    notebook.lastOpenedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.notebookEntitys.put(notebook);
    });
  }
}
