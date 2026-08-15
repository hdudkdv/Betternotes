import 'dart:convert';

import '../../features/search/fuzzy_match.dart';
import '../../features/search/search_query.dart';
import '../models/content_models.dart';
import '../models/notebook.dart';

/// Shared helpers for outline/paper/tags/links/sync JSON stores.
mixin ContentExtrasMixin {
  Future<String?> readKv(String key);
  Future<void> writeKv(String key, String value);
  Future<void> deleteKv(String key);
  Future<List<Notebook>> getNotebooks({String query = ''});
  Future<void> updateNotebook(Notebook notebook);
  Future<List<NotePage>> getPages(String notebookId);

  Future<List<OutlineNode>> getOutline(String notebookId) async {
    final raw = await readKv('outline_$notebookId');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    final nodes = [
      for (final item in list)
        OutlineNode.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    nodes.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return nodes;
  }

  Future<void> saveOutline(String notebookId, List<OutlineNode> nodes) async {
    await writeKv(
      'outline_$notebookId',
      jsonEncode(nodes.map((n) => n.toJson()).toList()),
    );
  }

  Future<List<PaperTemplate>> getPaperTemplates() async {
    final raw = await readKv('paper_templates');
    final custom = <PaperTemplate>[];
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List;
      custom.addAll([
        for (final item in list)
          PaperTemplate.fromJson(Map<String, dynamic>.from(item as Map)),
      ]);
    }
    return [...PaperTemplate.builtins(), ...custom];
  }

  Future<void> savePaperTemplate(PaperTemplate template) async {
    final all = await getPaperTemplates();
    final custom = all.where((t) => !t.isBuiltin).toList();
    final i = custom.indexWhere((t) => t.id == template.id);
    if (i >= 0) {
      custom[i] = template;
    } else {
      custom.add(template);
    }
    await writeKv(
      'paper_templates',
      jsonEncode(custom.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> deletePaperTemplate(String id) async {
    final all = await getPaperTemplates();
    final custom = all.where((t) => !t.isBuiltin && t.id != id).toList();
    await writeKv(
      'paper_templates',
      jsonEncode(custom.map((t) => t.toJson()).toList()),
    );
  }

  Future<List<NoteTag>> getTags({String? notebookId}) async {
    final raw = await readKv('tags');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    var tags = [
      for (final item in list)
        NoteTag.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    if (notebookId != null) {
      tags = tags.where((t) => t.notebookId == notebookId).toList();
    }
    return tags;
  }

  Future<void> saveTag(NoteTag tag) async {
    final tags = await getTags();
    final i = tags.indexWhere((t) => t.id == tag.id);
    if (i >= 0) {
      tags[i] = tag;
    } else {
      tags.add(tag);
    }
    await writeKv('tags', jsonEncode(tags.map((t) => t.toJson()).toList()));
  }

  Future<void> deleteTag(String id) async {
    final tags = await getTags();
    tags.removeWhere((t) => t.id == id);
    await writeKv('tags', jsonEncode(tags.map((t) => t.toJson()).toList()));
  }

  Future<List<NoteLink>> getLinks({String? notebookId}) async {
    final raw = await readKv('links');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    var links = [
      for (final item in list)
        NoteLink.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    if (notebookId != null) {
      links = links
          .where(
            (l) =>
                l.fromNotebookId == notebookId || l.toNotebookId == notebookId,
          )
          .toList();
    }
    return links;
  }

  Future<void> saveLink(NoteLink link) async {
    final links = await getLinks();
    final i = links.indexWhere((l) => l.id == link.id);
    if (i >= 0) {
      links[i] = link;
    } else {
      links.add(link);
    }
    await writeKv('links', jsonEncode(links.map((l) => l.toJson()).toList()));
  }

  Future<void> deleteLink(String id) async {
    final links = await getLinks();
    links.removeWhere((l) => l.id == id);
    await writeKv('links', jsonEncode(links.map((l) => l.toJson()).toList()));
  }

  Future<List<SearchHit>> globalSearch(String query) async {
    final parsed = ParsedSearchQuery.parse(query);
    if (parsed.isEmpty) return [];
    final q = parsed.text.trim().toLowerCase();
    final hits = <SearchHit>[];
    final folders = await getAllFolders();
    final folderById = {for (final folder in folders) folder.id: folder};

    String folderPath(String? folderId) {
      if (folderId == null) return '';
      final parts = <String>[];
      var current = folderById[folderId];
      final seen = <String>{};
      while (current != null && seen.add(current.id)) {
        parts.add(current.name);
        current = current.parentId == null
            ? null
            : folderById[current.parentId];
      }
      return parts.reversed.join('/');
    }

    String withTrailingSlash(String path) =>
        path.isEmpty ? path : (path.endsWith('/') ? path : '$path/');

    for (final folder in folders) {
      final name = folder.name;
      if (q.isNotEmpty && FuzzyMatch.matches(q, name)) {
        final parent = folderPath(folder.parentId);
        hits.add(
          SearchHit(
            kind: 'folder',
            snippet: name,
            folderId: folder.id,
            subtitle: 'Folder',
            path: withTrailingSlash(
              parent.isEmpty ? name : '$parent/$name',
            ),
            exactMatch: name.toLowerCase() == q,
          ),
        );
      }
    }

    final notebooks = await getNotebooks();
    for (final nb in notebooks) {
      final rawFolderPath = folderPath(nb.folderId);
      if (!parsed.matchesScope(notebook: nb, folderPath: rawFolderPath)) {
        continue;
      }
      final nbFolderPath = withTrailingSlash(rawFolderPath);
      final nbPath = withTrailingSlash(
        nbFolderPath.isEmpty ? nb.title : '$nbFolderPath$nb.title',
      );
      if (q.isEmpty || FuzzyMatch.matches(q, nb.title)) {
        hits.add(
          SearchHit(
            kind: 'notebook',
            snippet: nb.title,
            notebookId: nb.id,
            notebookTitle: nb.title,
            folderId: nb.folderId,
            subtitle: 'Notebook',
            path: nbFolderPath.isEmpty ? null : nbFolderPath,
            exactMatch: q.isNotEmpty && nb.title.toLowerCase() == q,
          ),
        );
      }
      if (q.isEmpty) continue;

      final outline = await getOutline(nb.id);
      for (final node in outline) {
        if (FuzzyMatch.matches(q, node.title)) {
          hits.add(
            SearchHit(
              kind: 'outline',
              snippet: node.title,
              notebookId: nb.id,
              notebookTitle: nb.title,
              folderId: nb.folderId,
              pageId: node.pageId,
              outlineId: node.id,
              subtitle: nb.title,
              path: nbPath,
              exactMatch: node.title.toLowerCase() == q,
            ),
          );
        }
      }

      final pages = await getPages(nb.id);
      for (final page in pages) {
        for (final block in page.textBlocks) {
          final text = block.plainText;
          if (FuzzyMatch.matches(q, text)) {
            hits.add(
              SearchHit(
                kind: 'text',
                snippet: text.length > 80 ? '${text.substring(0, 80)}…' : text,
                notebookId: nb.id,
                notebookTitle: nb.title,
                folderId: nb.folderId,
                pageId: page.id,
                subtitle: nb.title,
                path: nbPath,
                exactMatch: text.trim().toLowerCase() == q,
              ),
            );
          }
        }
        final index = page.searchIndex?.trim() ?? '';
        if (index.isNotEmpty && FuzzyMatch.matches(q, index)) {
          final already = hits.any(
            (h) => h.pageId == page.id && h.notebookId == nb.id,
          );
          if (!already) {
            hits.add(
              SearchHit(
                kind: 'text',
                snippet: _indexSnippet(index, q),
                notebookId: nb.id,
                notebookTitle: nb.title,
                folderId: nb.folderId,
                pageId: page.id,
                subtitle: nb.title,
                path: nbPath,
                exactMatch: index.toLowerCase() == q,
              ),
            );
          }
        }
      }

      final tags = await getTags(notebookId: nb.id);
      for (final tag in tags) {
        if (tag.label.toLowerCase().contains(q)) {
          hits.add(
            SearchHit(
              kind: 'tag',
              snippet: '#${tag.label}',
              notebookId: nb.id,
              notebookTitle: nb.title,
              folderId: nb.folderId,
              subtitle: nb.title,
              path: nbPath,
              exactMatch: tag.label.toLowerCase() == q,
            ),
          );
        }
      }
    }

    final decks = await getAllFlashcardDecks();
    for (final deck in decks) {
      if (q.isEmpty) break;
      final deckFolderPath = withTrailingSlash(folderPath(deck.folderId));
      if (deck.title.toLowerCase().contains(q)) {
        hits.add(
          SearchHit(
            kind: 'flashcard',
            snippet: deck.title,
            deckId: deck.id,
            folderId: deck.folderId,
            subtitle: 'Flashcards',
            path: deckFolderPath.isEmpty ? null : deckFolderPath,
            exactMatch: deck.title.toLowerCase() == q,
          ),
        );
      }
      final cards = await getFlashcards(deck.id);
      for (final card in cards) {
        if (card.front.toLowerCase().contains(q) ||
            card.back.toLowerCase().contains(q)) {
          hits.add(
            SearchHit(
              kind: 'flashcard',
              snippet: card.front.isEmpty ? card.back : card.front,
              deckId: deck.id,
              folderId: deck.folderId,
              subtitle: deck.title,
              path: deckFolderPath.isEmpty ? null : deckFolderPath,
              exactMatch:
                  card.front.trim().toLowerCase() == q ||
                  card.back.trim().toLowerCase() == q,
            ),
          );
        }
      }
    }

    hits.sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      if (byRank != 0) return byRank;
      return a.snippet.toLowerCase().compareTo(b.snippet.toLowerCase());
    });
    return hits;
  }

  String _indexSnippet(String index, String query) {
    final lower = index.toLowerCase();
    final q = query.toLowerCase();
    final at = lower.indexOf(q);
    if (at < 0) {
      return index.length > 80 ? '${index.substring(0, 80)}…' : index;
    }
    final start = at > 20 ? at - 20 : 0;
    final end = (at + q.length + 40).clamp(0, index.length);
    final slice = index.substring(start, end);
    return '${start > 0 ? '…' : ''}$slice${end < index.length ? '…' : ''}';
  }

  Future<List<LibraryFolder>> getFolders({String? parentId}) async {
    final raw = await readKv('folders');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    var folders = [
      for (final item in list)
        LibraryFolder.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    folders = folders.where((f) => f.parentId == parentId).toList();
    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return folders;
  }

  Future<List<LibraryFolder>> getAllFolders() async {
    final raw = await readKv('folders');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        LibraryFolder.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<void> _writeFolders(List<LibraryFolder> folders) async {
    await writeKv(
      'folders',
      jsonEncode(folders.map((f) => f.toJson()).toList()),
    );
  }

  Future<LibraryFolder> createFolder({
    required String name,
    String? parentId,
    int colorValue = 0xFF1D4E89,
    String iconKey = 'folder',
  }) async {
    final all = await getAllFolders();
    final folder = LibraryFolder.create(
      name: name,
      parentId: parentId,
      colorValue: colorValue,
      iconKey: iconKey,
    );
    all.add(folder);
    await _writeFolders(all);
    return folder;
  }

  Future<void> updateFolder(LibraryFolder folder) async {
    final all = await getAllFolders();
    final i = all.indexWhere((f) => f.id == folder.id);
    if (i < 0) {
      all.add(folder);
    } else {
      all[i] = folder;
    }
    await _writeFolders(all);
  }

  Future<void> deleteFolder(String id) async {
    final all = await getAllFolders();
    final removeIds = <String>{id};
    var grew = true;
    while (grew) {
      grew = false;
      for (final folder in all) {
        if (folder.parentId != null &&
            removeIds.contains(folder.parentId) &&
            removeIds.add(folder.id)) {
          grew = true;
        }
      }
    }
    all.removeWhere((folder) => removeIds.contains(folder.id));
    await _writeFolders(all);

    // Notebooks and decks that lived in the deleted tree move to the root.
    final folderMap = await readNotebookFolderMap();
    var mapChanged = false;
    for (final entry in folderMap.entries.toList()) {
      if (removeIds.contains(entry.value)) {
        folderMap.remove(entry.key);
        mapChanged = true;
      }
    }
    if (mapChanged) {
      await writeKv('notebook_folders', jsonEncode(folderMap));
    }
    final notebooks = await getNotebooks();
    for (final notebook in notebooks) {
      if (notebook.folderId != null && removeIds.contains(notebook.folderId)) {
        await updateNotebook(
          notebook.copyWith(clearFolder: true, updatedAt: DateTime.now()),
        );
      }
    }

    final decks = await getAllFlashcardDecks();
    var decksChanged = false;
    final nextDecks = <FlashcardDeck>[];
    for (final deck in decks) {
      if (deck.folderId != null && removeIds.contains(deck.folderId)) {
        decksChanged = true;
        nextDecks.add(deck.copyWith(clearFolder: true));
      } else {
        nextDecks.add(deck);
      }
    }
    if (decksChanged) {
      await _writeDecks(nextDecks);
    }
  }

  Future<List<FlashcardDeck>> getFlashcardDecks({String? folderId}) async {
    final raw = await readKv('flashcard_decks');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    var decks = [
      for (final item in list)
        FlashcardDeck.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    if (folderId == null) {
      decks = decks.where((d) => d.folderId == null).toList();
    } else {
      decks = decks.where((d) => d.folderId == folderId).toList();
    }
    decks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return decks;
  }

  Future<List<FlashcardDeck>> getAllFlashcardDecks() async {
    final raw = await readKv('flashcard_decks');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        FlashcardDeck.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<void> _writeDecks(List<FlashcardDeck> decks) async {
    await writeKv(
      'flashcard_decks',
      jsonEncode(decks.map((d) => d.toJson()).toList()),
    );
  }

  Future<FlashcardDeck> createFlashcardDeck({
    required String title,
    String? folderId,
    int colorValue = 0xFF9A5B13,
  }) async {
    final all = await getAllFlashcardDecks();
    final deck = FlashcardDeck.create(
      title: title,
      folderId: folderId,
      colorValue: colorValue,
    );
    all.add(deck);
    await _writeDecks(all);
    return deck;
  }

  Future<void> updateFlashcardDeck(FlashcardDeck deck) async {
    final all = await getAllFlashcardDecks();
    final i = all.indexWhere((d) => d.id == deck.id);
    if (i < 0) {
      all.add(deck);
    } else {
      all[i] = deck;
    }
    await _writeDecks(all);
  }

  Future<void> deleteFlashcardDeck(String id) async {
    final all = await getAllFlashcardDecks();
    all.removeWhere((d) => d.id == id);
    await _writeDecks(all);
    await deleteKv('flashcards_$id');
  }

  Future<List<Flashcard>> getFlashcards(String deckId) async {
    final raw = await readKv('flashcards_$deckId');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        Flashcard.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<void> saveFlashcard(Flashcard card) async {
    final cards = await getFlashcards(card.deckId);
    final i = cards.indexWhere((c) => c.id == card.id);
    if (i >= 0) {
      cards[i] = card;
    } else {
      cards.add(card);
    }
    await writeKv(
      'flashcards_${card.deckId}',
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> deleteFlashcard(String id) async {
    final decks = await getAllFlashcardDecks();
    for (final deck in decks) {
      final cards = await getFlashcards(deck.id);
      final next = cards.where((c) => c.id != id).toList();
      if (next.length != cards.length) {
        await writeKv(
          'flashcards_${deck.id}',
          jsonEncode(next.map((c) => c.toJson()).toList()),
        );
        return;
      }
    }
  }

  Future<Map<String, String>> readNotebookFolderMap() async {
    final raw = await readKv('notebook_folders');
    if (raw == null || raw.isEmpty) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return {
      for (final e in map.entries)
        if (e.value != null) e.key: e.value.toString(),
    };
  }

  Future<void> setNotebookFolderId(String notebookId, String? folderId) async {
    final map = await readNotebookFolderMap();
    if (folderId == null || folderId.isEmpty) {
      map.remove(notebookId);
    } else {
      map[notebookId] = folderId;
    }
    await writeKv('notebook_folders', jsonEncode(map));
  }

  Future<String?> notebookFolderId(String notebookId) async {
    final map = await readNotebookFolderMap();
    return map[notebookId];
  }

  Future<Map<String, int>> readNotebookSchoolClassMap() async {
    final raw = await readKv('notebook_school_classes');
    if (raw == null || raw.isEmpty) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return {
      for (final e in map.entries)
        if (e.value is num) e.key: (e.value as num).toInt(),
    };
  }

  Future<void> setNotebookSchoolClass(
    String notebookId,
    int? schoolClass,
  ) async {
    final map = await readNotebookSchoolClassMap();
    if (schoolClass == null) {
      map.remove(notebookId);
    } else {
      map[notebookId] = schoolClass;
    }
    await writeKv('notebook_school_classes', jsonEncode(map));
  }

  Future<int?> notebookSchoolClass(String notebookId) async {
    final map = await readNotebookSchoolClassMap();
    return map[notebookId];
  }

  Future<Map<String, String>> readNotebookSubjectMap() async {
    final raw = await readKv('notebook_subjects');
    if (raw == null || raw.isEmpty) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return {
      for (final e in map.entries)
        if (e.value != null && e.value.toString().trim().isNotEmpty)
          e.key: e.value.toString().trim().toLowerCase(),
    };
  }

  Future<void> setNotebookSubjectKey(
    String notebookId,
    String? subjectKey,
  ) async {
    final map = await readNotebookSubjectMap();
    final key = subjectKey?.trim().toLowerCase();
    if (key == null || key.isEmpty) {
      map.remove(notebookId);
    } else {
      map[notebookId] = key;
    }
    await writeKv('notebook_subjects', jsonEncode(map));
  }

  Future<String?> notebookSubjectKey(String notebookId) async {
    final map = await readNotebookSubjectMap();
    return map[notebookId];
  }

  Future<List<SyncOp>> getPendingSyncOps() async {
    final raw = await readKv('sync_ops');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        SyncOp.fromJson(Map<String, dynamic>.from(item as Map)),
    ].where((o) => !o.synced).toList();
  }

  Future<void> enqueueSyncOp(SyncOp op) async {
    final raw = await readKv('sync_ops');
    final ops = <SyncOp>[];
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List;
      ops.addAll([
        for (final item in list)
          SyncOp.fromJson(Map<String, dynamic>.from(item as Map)),
      ]);
    }
    ops.add(op);
    await writeKv('sync_ops', jsonEncode(ops.map((o) => o.toJson()).toList()));
  }

  Future<void> markSyncOpSynced(String id) async {
    final raw = await readKv('sync_ops');
    if (raw == null || raw.isEmpty) return;
    final list = jsonDecode(raw) as List;
    final ops = [
      for (final item in list)
        SyncOp.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    final next = [
      for (final o in ops)
        if (o.id == id) o.copyWith(synced: true) else o,
    ];
    await writeKv('sync_ops', jsonEncode(next.map((o) => o.toJson()).toList()));
  }

  Future<void> pruneSyncedOps({int keep = 40}) async {
    final raw = await readKv('sync_ops');
    if (raw == null || raw.isEmpty) return;
    final list = jsonDecode(raw) as List;
    final ops = [
      for (final item in list)
        SyncOp.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    final pending = ops.where((o) => !o.synced).toList();
    final synced = ops.where((o) => o.synced).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final kept = [...pending, ...synced.take(keep)];
    await writeKv('sync_ops', jsonEncode(kept.map((o) => o.toJson()).toList()));
  }

  Future<int> pendingSyncCount() async {
    final ops = await getPendingSyncOps();
    return ops.length;
  }

  static const _maxPageSnapshots = 20;

  Future<List<PageLocalSnapshot>> getPageSnapshots(String pageId) async {
    final raw = await readKv('page_snapshots_$pageId');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    final snaps = [
      for (final item in list)
        PageLocalSnapshot.fromJson(Map<String, dynamic>.from(item as Map)),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snaps;
  }

  Future<void> savePageSnapshot(PageLocalSnapshot snapshot) async {
    final existing = await getPageSnapshots(snapshot.pageId);
    final next = [snapshot, ...existing.where((s) => s.id != snapshot.id)]
        .take(_maxPageSnapshots)
        .toList();
    await writeKv(
      'page_snapshots_${snapshot.pageId}',
      jsonEncode(next.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> deletePageSnapshot(String pageId, String snapshotId) async {
    final existing = await getPageSnapshots(pageId);
    final next = existing.where((s) => s.id != snapshotId).toList();
    await writeKv(
      'page_snapshots_$pageId',
      jsonEncode(next.map((s) => s.toJson()).toList()),
    );
  }
}
