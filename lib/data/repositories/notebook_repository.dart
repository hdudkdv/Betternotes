import '../models/content_models.dart';
import '../models/notebook.dart';
import '../../features/editor/domain/ink_models.dart';
import '../../shared/utils/page_size.dart';

/// Lightweight input for [NotebookRepository.addPages].
class NotePageDraft {
  const NotePageDraft({
    this.template = PageTemplate.blank,
    this.backgroundPdfPath,
    this.paperTemplateId,
    this.customPaper,
    this.paperFormat = PaperFormat.a4,
    this.orientation = PageOrientation.portrait,
  });

  final PageTemplate template;
  final String? backgroundPdfPath;
  final String? paperTemplateId;
  final PaperTemplate? customPaper;
  final PaperFormat paperFormat;
  final PageOrientation orientation;
}

abstract class NotebookRepository {
  Future<String?> readKv(String key);
  Future<void> writeKv(String key, String value);
  Future<void> deleteKv(String key);

  Future<void> setNotebookAccess(
    String notebookId, {
    String? ownerUid,
    bool? locked,
  });

  Future<List<Notebook>> getNotebooks({String query = ''});

  Future<Notebook?> getNotebook(String id);

  Future<Notebook> createNotebook({
    required String title,
    required int coverColor,
    PageTemplate template = PageTemplate.blank,
    String? folderId,
    int? schoolClass,
    CanvasMode canvasMode = CanvasMode.page,
    PaperFormat paperFormat = PaperFormat.a4,
    PageOrientation orientation = PageOrientation.portrait,
  });

  Future<void> updateNotebook(Notebook notebook);

  Future<void> deleteNotebook(String id);

  /// Applies a cloud change without enqueueing another local sync operation.
  Future<void> upsertRemoteNotebook(Notebook notebook);

  Future<List<NotePage>> getPages(String notebookId);

  Future<NotePage?> getPage(String pageId);

  Future<NotePage> addPage({
    required String notebookId,
    PageTemplate template = PageTemplate.blank,
    String? backgroundPdfPath,
    String? paperTemplateId,
    PaperTemplate? customPaper,
    PaperFormat paperFormat = PaperFormat.a4,
    PageOrientation orientation = PageOrientation.portrait,
  });

  /// Bulk insert used by PDF import — one txn / sync flush instead of N.
  Future<List<NotePage>> addPages({
    required String notebookId,
    required List<NotePageDraft> drafts,
  });

  Future<void> savePage(NotePage page);

  Future<void> deletePage(String pageId);

  /// Applies a cloud page change without enqueueing another local sync operation.
  Future<void> upsertRemotePage(NotePage page);

  Future<void> touchOpened(String notebookId);

  Future<String> resolveFilesDir();

  /// Removes a notebook from this device without enqueueing a cloud delete.
  Future<void> deleteLocalNotebookOnly(String id);

  /// Drops local notebooks/pages so a session can be replaced from cloud.
  /// Locked notebooks belonging to another account stay on the device.
  Future<void> clearLocalNotebooksForCloudReload() async {}

  // Outline
  Future<List<OutlineNode>> getOutline(String notebookId);
  Future<void> saveOutline(String notebookId, List<OutlineNode> nodes);

  // Paper templates
  Future<List<PaperTemplate>> getPaperTemplates();
  Future<void> savePaperTemplate(PaperTemplate template);
  Future<void> deletePaperTemplate(String id);

  // Tags / links
  Future<List<NoteTag>> getTags({String? notebookId});
  Future<void> saveTag(NoteTag tag);
  Future<void> deleteTag(String id);
  Future<List<NoteLink>> getLinks({String? notebookId});
  Future<void> saveLink(NoteLink link);
  Future<void> deleteLink(String id);

  // Search
  Future<List<SearchHit>> globalSearch(String query);

  // Folders
  Future<List<LibraryFolder>> getFolders({String? parentId});
  Future<List<LibraryFolder>> getAllFolders();
  Future<LibraryFolder> createFolder({
    required String name,
    String? parentId,
    int colorValue = 0xFF1D4E89,
    String iconKey = 'folder',
  });
  Future<void> updateFolder(LibraryFolder folder);
  Future<void> deleteFolder(String id);

  // Flashcards
  Future<List<FlashcardDeck>> getFlashcardDecks({String? folderId});
  Future<List<FlashcardDeck>> getAllFlashcardDecks();
  Future<FlashcardDeck> createFlashcardDeck({
    required String title,
    String? folderId,
    int colorValue = 0xFF9A5B13,
  });
  Future<void> updateFlashcardDeck(FlashcardDeck deck);
  Future<void> deleteFlashcardDeck(String id);
  Future<List<Flashcard>> getFlashcards(String deckId);
  Future<void> saveFlashcard(Flashcard card);
  Future<void> deleteFlashcard(String id);

  // Sync queue
  Future<List<SyncOp>> getPendingSyncOps();
  Future<void> enqueueSyncOp(SyncOp op);
  Future<void> markSyncOpSynced(String id);
  Future<void> pruneSyncedOps({int keep = 40});
  Future<int> pendingSyncCount();

  // Local page version history
  Future<List<PageLocalSnapshot>> getPageSnapshots(String pageId);
  Future<void> savePageSnapshot(PageLocalSnapshot snapshot);
  Future<void> deletePageSnapshot(String pageId, String snapshotId);
}
