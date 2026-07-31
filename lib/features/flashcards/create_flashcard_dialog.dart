import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../library/providers/library_providers.dart';

Future<bool> showCreateFlashcardDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String initialFront,
  String initialBack = '',
}) async {
  final l10n = AppLocalizations.of(context)!;
  final front = TextEditingController(text: initialFront);
  final back = TextEditingController(text: initialBack);
  String? selectedDeckId;
  final decks = await ref.read(notebookRepositoryProvider).getAllFlashcardDecks();
  if (!context.mounted) return false;
  if (decks.isNotEmpty) selectedDeckId = decks.first.id;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.noteToFlashcard),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: front,
                    decoration: InputDecoration(labelText: l10n.flashcardFront),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: back,
                    decoration: InputDecoration(labelText: l10n.flashcardBack),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: selectedDeckId,
                    decoration: InputDecoration(labelText: l10n.flashcards),
                    items: [
                      for (final d in decks)
                        DropdownMenuItem(value: d.id, child: Text(d.title)),
                      DropdownMenuItem(
                        value: '__new__',
                        child: Text(l10n.newFlashcardDeck),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedDeckId = v),
                  ),
                ],
              ),
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
          );
        },
      );
    },
  );
  if (ok != true || !context.mounted) return false;

  final repo = ref.read(notebookRepositoryProvider);
  var deckId = selectedDeckId;
  if (deckId == null || deckId == '__new__') {
    final deck = await repo.createFlashcardDeck(
      title: l10n.newFlashcardDeck,
    );
    deckId = deck.id;
  }
  await repo.saveFlashcard(
    Flashcard.create(
      deckId: deckId,
      front: front.text.trim(),
      back: back.text.trim(),
    ),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.flashcardCreated)),
    );
  }
  return true;
}

/// Convenience wrapper when only a BuildContext + ref are available in editor.
Future<void> createFlashcardFromEditorSelection({
  required BuildContext context,
  required WidgetRef ref,
  required String frontHint,
  String backHint = '',
}) {
  return showCreateFlashcardDialog(
    context: context,
    ref: ref,
    initialFront: frontHint,
    initialBack: backHint,
  );
}
