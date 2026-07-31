import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/models/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../import_export/csv_service.dart';
import '../library/providers/library_providers.dart';

class FlashcardDeckScreen extends ConsumerStatefulWidget {
  const FlashcardDeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<FlashcardDeckScreen> createState() =>
      _FlashcardDeckScreenState();
}

class _FlashcardDeckScreenState extends ConsumerState<FlashcardDeckScreen> {
  FlashcardDeck? _deck;
  List<Flashcard> _cards = [];
  List<Flashcard> _queue = [];
  int _queueIndex = 0;
  bool _showBack = false;
  bool _loading = true;
  bool _studyMode = true;
  int _reviewed = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(notebookRepositoryProvider);
    final decks = await repo.getAllFlashcardDecks();
    FlashcardDeck? deck;
    for (final d in decks) {
      if (d.id == widget.deckId) {
        deck = d;
        break;
      }
    }
    final cards = await repo.getFlashcards(widget.deckId);
    if (!mounted) return;
    setState(() {
      _deck = deck;
      _cards = cards;
      _queue = cards.where((c) => c.isDue).toList()..shuffle();
      _loading = false;
      _queueIndex = 0;
      _showBack = false;
      _reviewed = 0;
      _studyMode = true;
    });
  }

  Flashcard? get _current {
    if (_queue.isEmpty) return null;
    if (_queueIndex < 0 || _queueIndex >= _queue.length) return null;
    return _queue[_queueIndex];
  }

  Future<void> _rate(FlashcardRating rating) async {
    final card = _current;
    if (card == null) return;
    final updated = applyFlashcardRating(card, rating);
    await ref.read(notebookRepositoryProvider).saveFlashcard(updated);
    final all = [
      for (final c in _cards)
        if (c.id == updated.id) updated else c,
    ];
    final nextQueue = List<Flashcard>.from(_queue)..removeAt(_queueIndex);
    // "Again" puts the card back near the end of today's session.
    if (rating == FlashcardRating.again) {
      nextQueue.add(updated);
    }
    setState(() {
      _cards = all;
      _queue = nextQueue;
      _queueIndex = nextQueue.isEmpty ? 0 : _queueIndex.clamp(0, nextQueue.length - 1);
      _showBack = false;
      _reviewed++;
    });
  }

  Future<void> _addCard() async {
    final l10n = AppLocalizations.of(context)!;
    final front = TextEditingController();
    final back = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newFlashcard),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: front,
              decoration: InputDecoration(labelText: l10n.flashcardFront),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: back,
              decoration: InputDecoration(labelText: l10n.flashcardBack),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final card = Flashcard.create(
      deckId: widget.deckId,
      front: front.text.trim(),
      back: back.text.trim(),
    );
    await ref.read(notebookRepositoryProvider).saveFlashcard(card);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_deck == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noFlashcardsYet)),
      );
    }

    final dueCount = _cards.where((c) => c.isDue).length;
    final card = _current;
    final sessionDone = _studyMode && _queue.isEmpty && _cards.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_deck!.title, style: AppTheme.headline()),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              const csv = CsvService();
              if (value == 'export') {
                final text = csv.flashcardsToCsv(
                  _cards,
                  deckTitle: _deck?.title,
                );
                await csv.shareCsv(
                  text,
                  '${_deck?.title ?? 'flashcards'}.csv',
                );
              } else if (value == 'import') {
                final raw = await csv.pickCsvText();
                if (raw == null) return;
                final n = await csv.importFlashcardsToDeck(
                  repo: ref.read(notebookRepositoryProvider),
                  deckId: widget.deckId,
                  csv: raw,
                );
                await _load();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.csvImportedCards(n))),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Text(l10n.csvExportFlashcards),
              ),
              PopupMenuItem(
                value: 'import',
                child: Text(l10n.csvImportFlashcards),
              ),
            ],
          ),
          if (_cards.isNotEmpty)
            IconButton(
              tooltip: _studyMode ? l10n.flashcardBrowse : l10n.flashcardStudy,
              onPressed: () {
                setState(() {
                  _studyMode = !_studyMode;
                  _showBack = false;
                  if (_studyMode) {
                    _queue = _cards.where((c) => c.isDue).toList()..shuffle();
                  } else {
                    _queue = List.of(_cards);
                  }
                  _queueIndex = 0;
                  _reviewed = 0;
                });
              },
              icon: Icon(
                _studyMode ? Icons.view_carousel_outlined : Icons.school_outlined,
              ),
            ),
          IconButton(
            tooltip: l10n.newFlashcard,
            onPressed: _addCard,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_cards.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.noFlashcardsYet,
                        style: AppTheme.headline(fontSize: 22),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addCard,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.newFlashcard),
                      ),
                    ],
                  ),
                ),
              )
            else if (sessionDone)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 56,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.flashcardSessionDone,
                        style: AppTheme.headline(fontSize: 22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.flashcardReviewedCount(_reviewed),
                        style: AppTheme.body(color: AppTheme.inkMuted),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _queue = List.of(_cards)..shuffle();
                            _queueIndex = 0;
                            _reviewed = 0;
                            _showBack = false;
                          });
                        },
                        child: Text(l10n.flashcardStudyAll),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                _studyMode
                    ? l10n.flashcardDueProgress(
                        (_queueIndex + 1).clamp(1, _queue.length),
                        _queue.length,
                        dueCount,
                      )
                    : '${_queueIndex + 1} / ${_cards.length}',
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showBack = !_showBack),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Color(_deck!.colorValue),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Color(
                            _deck!.colorValue,
                          ).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        card == null
                            ? ''
                            : (_showBack ? card.back : card.front),
                        textAlign: TextAlign.center,
                        style: AppTheme.headline(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tapToFlip,
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 20),
              if (_studyMode && _showBack && card != null)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RatingButton(
                      label: l10n.flashcardAgain,
                      color: const Color(0xFFB42318),
                      onTap: () => _rate(FlashcardRating.again),
                    ),
                    _RatingButton(
                      label: l10n.flashcardHard,
                      color: const Color(0xFFD4A017),
                      onTap: () => _rate(FlashcardRating.hard),
                    ),
                    _RatingButton(
                      label: l10n.flashcardGood,
                      color: const Color(0xFF1D4E89),
                      onTap: () => _rate(FlashcardRating.good),
                    ),
                    _RatingButton(
                      label: l10n.flashcardEasy,
                      color: const Color(0xFF2E7D32),
                      onTap: () => _rate(FlashcardRating.easy),
                    ),
                  ],
                )
              else if (!_studyMode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: _queueIndex > 0
                          ? () => setState(() {
                              _queueIndex--;
                              _showBack = false;
                            })
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 24),
                    IconButton.filledTonal(
                      onPressed: _queueIndex < _queue.length - 1
                          ? () => setState(() {
                              _queueIndex++;
                              _showBack = false;
                            })
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                )
              else
                Text(
                  l10n.flashcardFlipToRate,
                  style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
