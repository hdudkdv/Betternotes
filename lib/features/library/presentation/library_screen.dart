import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../data/models/content_models.dart';
import '../../../data/models/notebook.dart';
import '../../../l10n/app_localizations.dart';
import '../../editor/providers/open_tabs_provider.dart';
import '../../search/global_search_screen.dart';
import '../../planner/planner_screen.dart';
import '../../planner/school_year.dart';
import '../../planner/school_year_rollover.dart';
import '../../timetable/timetable_screen.dart';
import '../providers/library_providers.dart';
import 'widgets/library_create_dialogs.dart';
import 'widgets/notebook_cover.dart';
import 'widgets/school_year_rollover_cover.dart';
import 'widgets/upcoming_school_strip.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final Set<String> _rolloverDismissed = {};
  bool _rolloverLoaded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _ensureRolloverDismissedLoaded() async {
    if (_rolloverLoaded) return;
    _rolloverLoaded = true;
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getStringList('bn_school_year_rollover_dismissed') ?? [];
    if (!mounted || raw.isEmpty) return;
    setState(() => _rolloverDismissed.addAll(raw));
  }

  Future<void> _dismissRollover(SchoolYearRolloverCandidate candidate) async {
    final key = SchoolYearRollover.dismissKey(
      candidate.source.id,
      SchoolYear.current(),
    );
    setState(() => _rolloverDismissed.add(key));
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(
      'bn_school_year_rollover_dismissed',
      _rolloverDismissed.toList(),
    );
  }

  Future<void> _createSchoolYearNotebook(
    SchoolYearRolloverCandidate candidate,
  ) async {
    final repo = ref.read(notebookRepositoryProvider);
    final source = candidate.source;
    final outline = await repo.getOutline(source.id);
    final chapterTitles = [
      for (final node in outline)
        if (node.depth == 0) node.title,
    ];
    if (!mounted) return;
    final selected = await promptSchoolYearChapterImport(
      context,
      source: source,
      nextClass: candidate.nextClass,
      chapterTitles: chapterTitles,
    );
    if (selected == null || !mounted) return;

    final notebook = await repo.createNotebook(
      title: source.title,
      coverColor: source.coverColor,
      template: source.defaultTemplate,
      folderId: source.folderId ?? ref.read(currentFolderIdProvider),
      schoolClass: candidate.nextClass,
      canvasMode: source.canvasMode,
      paperFormat: source.defaultPaperFormat,
      orientation: source.defaultOrientation,
    );

    if (selected.isNotEmpty) {
      final nodes = <OutlineNode>[];
      for (var i = 0; i < selected.length; i++) {
        nodes.add(
          OutlineNode.create(
            notebookId: notebook.id,
            title: selected[i],
            depth: 0,
            sortIndex: i,
          ),
        );
      }
      await repo.saveOutline(notebook.id, nodes);
    }

    await _dismissRollover(candidate);
    ref.invalidate(notebooksProvider);
    if (!mounted) return;
    ref.read(openNotebookTabsProvider.notifier).open(notebook.id);
    context.push('/notebook/${notebook.id}');
  }

  void _dismissSearchFocus() {
    if (_searchFocus.hasFocus) {
      _searchFocus.unfocus();
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _createNotebook({
    CanvasMode initialMode = CanvasMode.page,
  }) async {
    final settings = ref.read(settingsProvider);
    final folderId = ref.read(currentFolderIdProvider);
    final result = await promptCreateNotebook(
      context,
      defaultTemplate: settings.defaultTemplate,
      initialMode: initialMode,
    );
    if (result == null) return;
    var notebook = await ref
        .read(notebookRepositoryProvider)
        .createNotebook(
          title: result.title,
          coverColor: result.color,
          template: result.template,
          folderId: folderId,
          schoolClass: result.schoolClass,
          canvasMode: result.canvasMode,
          paperFormat: result.paperFormat,
          orientation: result.orientation,
        );
    if (result.favorite) {
      notebook = notebook.copyWith(isFavorite: true, updatedAt: DateTime.now());
      await ref.read(notebookRepositoryProvider).updateNotebook(notebook);
    }
    ref.invalidate(notebooksProvider);
    if (!mounted) return;
    ref.read(openNotebookTabsProvider.notifier).open(notebook.id);
    context.push('/notebook/${notebook.id}');
  }

  Future<void> _createFolder({LibraryFolder? existing}) async {
    final result = await promptCreateOrEditFolder(context, existing: existing);
    if (result == null) return;
    final repo = ref.read(notebookRepositoryProvider);
    if (existing != null) {
      await repo.updateFolder(
        existing.copyWith(
          name: result.name,
          colorValue: result.color,
          iconKey: result.iconKey,
        ),
      );
    } else {
      await repo.createFolder(
        name: result.name,
        parentId: ref.read(currentFolderIdProvider),
        colorValue: result.color,
        iconKey: result.iconKey,
      );
    }
    ref.invalidate(foldersProvider);
    ref.invalidate(allFoldersProvider);
  }

  Future<void> _folderActions(LibraryFolder folder) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.editFolder),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l10n.delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _createFolder(existing: folder);
      return;
    }
    if (action == 'delete') {
      await _deleteFolder(folder);
    }
  }

  Future<void> _deleteFolder(LibraryFolder folder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(dialogL10n.deleteFolderTitle),
          content: Text(dialogL10n.deleteFolderBody(folder.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(dialogL10n.delete),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final repo = ref.read(notebookRepositoryProvider);
    await repo.deleteFolder(folder.id);
    final current = ref.read(currentFolderIdProvider);
    if (current != null) {
      final remaining = await repo.getAllFolders();
      if (!remaining.any((f) => f.id == current)) {
        ref.read(currentFolderIdProvider.notifier).state = folder.parentId;
      }
    }
    ref.invalidate(foldersProvider);
    ref.invalidate(allFoldersProvider);
    ref.invalidate(notebooksProvider);
    ref.invalidate(flashcardDecksProvider);
  }

  Future<void> _submitSearch() async {
    final query = ref.read(libraryQueryProvider).trim();
    if (query.length < 2) return;
    final hits = await ref.read(librarySearchProvider.future);
    if (!mounted || hits.isEmpty) return;
    if (!hits.any((hit) => hit.exactMatch)) return;
    await _openSearchHit(hits.first);
  }

  String _hitSubtitle(AppLocalizations l10n, SearchHit hit) {
    return [
      _kindLabel(l10n, hit.kind),
      if (hit.path != null && hit.path!.isNotEmpty) hit.path,
      if (hit.subtitle != null &&
          hit.subtitle!.isNotEmpty &&
          hit.subtitle != hit.path)
        hit.subtitle,
      if (hit.notebookTitle != null && hit.kind != 'notebook') hit.notebookTitle,
    ].whereType<String>().toSet().join(' · ');
  }

  Future<void> _createFlashcards() async {
    final result = await promptCreateDeck(context);
    if (result == null) return;
    final deck = await ref
        .read(notebookRepositoryProvider)
        .createFlashcardDeck(
          title: result.title,
          folderId: ref.read(currentFolderIdProvider),
          colorValue: result.color,
        );
    ref.invalidate(flashcardDecksProvider);
    if (!mounted) return;
    context.push('/flashcards/${deck.id}');
  }

  void _showCreateMenu() {
    showLibraryCreateSheet(
      context,
      onFolder: () => _createFolder(),
      onNotebook: () => _createNotebook(),
      onInfinite: () => _createNotebook(initialMode: CanvasMode.infinite),
      onFlashcards: _createFlashcards,
    );
  }

  Future<void> _openSearchHit(SearchHit hit) async {
    _dismissSearchFocus();
    switch (hit.kind) {
      case 'folder':
        if (hit.folderId != null) {
          ref.read(currentFolderIdProvider.notifier).state = hit.folderId;
          _searchController.clear();
          ref.read(libraryQueryProvider.notifier).state = '';
          setState(() {});
        }
      case 'flashcard':
        if (hit.deckId != null) {
          context.push('/flashcards/${hit.deckId}');
        }
      case 'notebook':
      case 'outline':
      case 'text':
      case 'tag':
        final id = hit.notebookId;
        if (id == null) return;
        await ref.read(notebookRepositoryProvider).touchOpened(id);
        ref.read(openNotebookTabsProvider.notifier).open(id);
        if (!mounted) return;
        final params = <String, String>{};
        if (hit.pageId != null) params['pageId'] = hit.pageId!;
        if (hit.outlineId != null) params['outlineId'] = hit.outlineId!;
        final query = params.isEmpty
            ? ''
            : '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
        context.push('/notebook/$id$query');
    }
  }

  Future<void> _rename(Notebook notebook) async {
    final controller = TextEditingController(text: notebook.title);
    final subjectController = TextEditingController(
      text: notebook.subjectKey ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(dialogL10n.rename),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(labelText: dialogL10n.title),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: dialogL10n.notebookSubject,
                  hintText: dialogL10n.notebookSubjectHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(dialogL10n.save),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final title = controller.text.trim();
    if (title.isEmpty) return;
    final subject = subjectController.text.trim();
    await ref
        .read(notebookRepositoryProvider)
        .updateNotebook(
          notebook.copyWith(
            title: title,
            updatedAt: DateTime.now(),
            subjectKey: subject.isEmpty ? null : subject.toLowerCase(),
            clearSubjectKey: subject.isEmpty,
          ),
        );
    ref.invalidate(notebooksProvider);
  }

  Future<void> _delete(Notebook notebook) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(dialogL10n.deleteNotebookTitle),
          content: Text(dialogL10n.deleteNotebookBody(notebook.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(context, true),
              child: Text(dialogL10n.delete),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await ref.read(notebookRepositoryProvider).deleteNotebook(notebook.id);
    ref.invalidate(notebooksProvider);
  }

  IconData _hitIcon(String kind) {
    switch (kind) {
      case 'folder':
        return Icons.folder_outlined;
      case 'outline':
        return Icons.list_alt;
      case 'text':
        return Icons.text_fields;
      case 'flashcard':
        return Icons.style_outlined;
      case 'tag':
        return Icons.sell_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  String _kindLabel(AppLocalizations l10n, String kind) {
    switch (kind) {
      case 'folder':
        return l10n.folders;
      case 'notebook':
        return l10n.notebooks;
      case 'outline':
        return l10n.chapters;
      case 'flashcard':
        return l10n.flashcards;
      case 'text':
        return l10n.entries;
      case 'tag':
        return l10n.addTag;
      default:
        return kind;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = ref.watch(libraryQueryProvider);
    final searching = query.trim().length >= 2;
    final folderId = ref.watch(currentFolderIdProvider);
    final allFolders = ref.watch(allFoldersProvider).valueOrNull ?? [];
    LibraryFolder? currentFolder;
    if (folderId != null) {
      for (final f in allFolders) {
        if (f.id == folderId) {
          currentFolder = f;
          break;
        }
      }
    }
    final notebooksAsync = ref.watch(notebooksProvider);
    final foldersAsync = ref.watch(foldersProvider);
    final decksAsync = ref.watch(flashcardDecksProvider);
    final searchAsync = ref.watch(librarySearchProvider);
    final appSettings = ref.watch(settingsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1200
        ? 5
        : width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissSearchFocus,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: folderId == null ? 140 : 100,
              // Cream brand header stays light in every theme — force dark
              // chrome so the title/icons stay readable (dark mode was washing
              // AppTheme.ink into near-white on this gradient).
              foregroundColor: const Color(0xFF17171C),
              iconTheme: const IconThemeData(color: Color(0xFF17171C)),
              actionsIconTheme: const IconThemeData(color: Color(0xFF17171C)),
              leading: folderId == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () {
                        ref.read(currentFolderIdProvider.notifier).state =
                            currentFolder?.parentId;
                      },
                    ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                title: Text(
                  folderId == null
                      ? l10n.appTitle
                      : (currentFolder?.name ?? l10n.folder),
                  style: AppTheme.headline(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17171C),
                    fontSize: folderId == null ? 30 : 26,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF7F2E8),
                        Color(0xFFE7F0EB),
                        Color(0xFFEDE6D8),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (appSettings.isTeacher)
                  IconButton(
                    tooltip: l10n.teacherWorkspace,
                    onPressed: () => context.push('/teacher'),
                    icon: const Icon(Icons.co_present_outlined),
                  ),
                IconButton(
                  tooltip: l10n.importAnyFile,
                  onPressed: () => context.push('/import'),
                  icon: const Icon(Icons.file_open_outlined),
                ),
                IconButton(
                  tooltip: l10n.settings,
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.tune_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  onTapOutside: (_) => _dismissSearchFocus(),
                  onChanged: (v) {
                    ref.read(libraryQueryProvider.notifier).state = v;
                    setState(() {});
                  },
                  onSubmitted: (_) => _submitSearch(),
                  decoration: InputDecoration(
                    hintText: l10n.searchEverything,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(libraryQueryProvider.notifier).state =
                                  '';
                              _dismissSearchFocus();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
            ),
            if (searching)
              searchAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    SliverFillRemaining(child: Center(child: Text('$e'))),
                data: (hits) {
                  if (hits.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(child: Text(l10n.searchEmpty)),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: hits.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final hit = hits[index];
                        return ListTile(
                          leading: Icon(_hitIcon(hit.kind)),
                          title: Text(hit.snippet),
                          subtitle: Text(_hitSubtitle(l10n, hit)),
                          onTap: () => _openSearchHit(hit),
                        );
                      },
                    ),
                  );
                },
              )
            else ...[
              if (folderId == null) ...[
                const SliverToBoxAdapter(child: UpcomingSchoolStrip()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                    child: LibrarySchoolRow(
                      onTimetable: () => context.push('/timetable'),
                      onGrades: () => context.push('/grades'),
                      onCalendar: () => context.push('/calendar'),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: NowSubjectBanner()),
              ],
              foldersAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (folders) {
                  if (folders.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.folders,
                            style: AppTheme.headline(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final folder in folders)
                                GestureDetector(
                                  onLongPress: () => _folderActions(folder),
                                  child: ActionChip(
                                    avatar: Icon(
                                      folderIconFor(folder.iconKey),
                                      color: Color(folder.colorValue),
                                    ),
                                    label: Text(
                                      folder.name,
                                      style: AppTheme.body(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.ink,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onPressed: () =>
                                        ref
                                            .read(
                                              currentFolderIdProvider.notifier,
                                            )
                                            .state = folder
                                            .id,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              decksAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (decks) {
                  if (decks.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.flashcards,
                            style: AppTheme.headline(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final deck in decks)
                                ActionChip(
                                  avatar: Icon(
                                    Icons.style,
                                    color: Color(deck.colorValue),
                                  ),
                                  label: Text(deck.title),
                                  onPressed: () =>
                                      context.push('/flashcards/${deck.id}'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              notebooksAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    SliverFillRemaining(child: Center(child: Text('$e'))),
                data: (notebooks) {
                  final folders = foldersAsync.valueOrNull ?? [];
                  final decks = decksAsync.valueOrNull ?? [];
                  final settings = ref.watch(settingsProvider);
                  // Fire-and-forget prefs load for dismissed rollover cards.
                  _ensureRolloverDismissedLoaded();
                  final rollovers = SchoolYearRollover.candidates(
                    folderNotebooks: notebooks,
                    level: settings.educationLevel,
                    state: settings.germanState,
                    dismissedKeys: _rolloverDismissed,
                  );
                  if (notebooks.isEmpty &&
                      folders.isEmpty &&
                      decks.isEmpty &&
                      rollovers.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.noNotebooksYet,
                              style: AppTheme.headline(fontSize: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noNotebooksHint,
                              style: AppTheme.body(
                                color: AppTheme.inkMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _showCreateMenu,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.create),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (notebooks.isEmpty && rollovers.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    );
                  }
                  final itemCount = rollovers.length + notebooks.length;
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              l10n.sectionNotebooks,
                              style: AppTheme.headline(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                        ),
                        SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 20,
                                childAspectRatio: 0.72,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index < rollovers.length) {
                              final candidate = rollovers[index];
                              return SchoolYearRolloverCover(
                                candidate: candidate,
                                onCreate: () =>
                                    _createSchoolYearNotebook(candidate),
                                onDismiss: () => _dismissRollover(candidate),
                              );
                            }
                            final notebook =
                                notebooks[index - rollovers.length];
                            return NotebookCover(
                              notebook: notebook,
                              onOpen: () async {
                                await ref
                                    .read(notebookRepositoryProvider)
                                    .touchOpened(notebook.id);
                                ref
                                    .read(openNotebookTabsProvider.notifier)
                                    .open(notebook.id);
                                if (!context.mounted) return;
                                context.push('/notebook/${notebook.id}');
                              },
                              onFavorite: () async {
                                await ref
                                    .read(notebookRepositoryProvider)
                                    .updateNotebook(
                                      notebook.copyWith(
                                        isFavorite: !notebook.isFavorite,
                                      ),
                                    );
                                ref.invalidate(notebooksProvider);
                              },
                              onRename: () => _rename(notebook),
                              onDelete: () => _delete(notebook),
                              onLink: () => CrossLinkDialog.show(
                                context,
                                ref,
                                notebook.id,
                              ),
                            );
                          }, childCount: itemCount),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _dismissSearchFocus();
          _showCreateMenu();
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.create),
      ),
    );
  }
}
