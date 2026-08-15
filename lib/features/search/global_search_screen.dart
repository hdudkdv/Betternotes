import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../editor/providers/open_tabs_provider.dart';
import '../library/providers/library_providers.dart';
import 'search_at_hints.dart';
import 'search_query.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  List<SearchHit> _hits = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final hits = await ref.read(notebookRepositoryProvider).globalSearch(q);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _loading = false;
    });
  }

  Future<void> _open(SearchHit hit) async {
    switch (hit.kind) {
      case 'folder':
        if (hit.folderId != null) {
          ref.read(currentFolderIdProvider.notifier).state = hit.folderId;
          context.go('/');
        }
      case 'flashcard':
        if (hit.deckId != null) context.push('/flashcards/${hit.deckId}');
      default:
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.globalSearch, style: AppTheme.headline()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    final parsed = ParsedSearchQuery.parse(v);
                    if (parsed.hasFilters || parsed.text.trim().length >= 2) {
                      _search(v);
                    } else {
                      _hits = [];
                    }
                  },
                  onSubmitted: (_) {
                    if (_hits.isEmpty) return;
                    if (!_hits.any((hit) => hit.exactMatch)) return;
                    _open(_hits.first);
                  },
                ),
                SearchAtHints(
                  query: _controller.text,
                  folders: ref.watch(allFoldersProvider).valueOrNull ?? const [],
                  notebooks:
                      ref.watch(notebooksProvider).valueOrNull ?? const [],
                  onInsert: (next) {
                    _controller.value = TextEditingValue(
                      text: next,
                      selection: TextSelection.collapsed(offset: next.length),
                    );
                    final parsed = ParsedSearchQuery.parse(next);
                    if (parsed.hasFilters || parsed.text.trim().length >= 2) {
                      _search(next);
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _hits.isEmpty
                ? Center(
                    child: Text(
                      l10n.searchEmpty,
                      style: AppTheme.body(
                        color: AppTheme.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _hits.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final hit = _hits[index];
                      return ListTile(
                        leading: Icon(_iconFor(hit.kind)),
                        title: Text(hit.snippet),
                        subtitle: Text(
                          [
                            hit.kind,
                            if (hit.path != null && hit.path!.isNotEmpty)
                              hit.path,
                            if (hit.subtitle != null) hit.subtitle,
                            if (hit.notebookTitle != null) hit.notebookTitle,
                          ].whereType<String>().toSet().join(' · '),
                        ),
                        onTap: () => _open(hit),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'folder':
        return Icons.folder_outlined;
      case 'text':
        return Icons.text_fields;
      case 'outline':
        return Icons.list_alt;
      case 'tag':
        return Icons.sell_outlined;
      case 'flashcard':
        return Icons.style_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }
}

class CrossLinkDialog {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    String fromId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(notebookRepositoryProvider);
    final notebooks = await repo.getNotebooks();
    if (!context.mounted) return;
    final others = notebooks.where((n) => n.id != fromId).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.needAnotherNotebook)));
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return SimpleDialog(
          title: Text(dialogL10n.linkToNotebook),
          children: [
            for (final n in others)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, n.id),
                child: Text(n.title),
              ),
          ],
        );
      },
    );
    if (selected == null) return;
    await repo.saveLink(
      NoteLink.create(
        fromNotebookId: fromId,
        toNotebookId: selected,
        label: 'related',
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.crossLinkCreated)));
  }
}
