import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class StickerDef {
  const StickerDef({
    required this.id,
    required this.emoji,
    required this.pack,
  });

  final String id;
  final String emoji;
  final String pack;
}

/// Built-in GoodNotes-style sticker packs (emoji, no extra assets).
abstract final class StickerCatalog {
  static const school = <StickerDef>[
    StickerDef(id: 'star', emoji: '⭐', pack: 'school'),
    StickerDef(id: 'check', emoji: '✅', pack: 'school'),
    StickerDef(id: 'cross', emoji: '❌', pack: 'school'),
    StickerDef(id: 'bang', emoji: '❗', pack: 'school'),
    StickerDef(id: 'question', emoji: '❓', pack: 'school'),
    StickerDef(id: 'hundred', emoji: '💯', pack: 'school'),
    StickerDef(id: 'memo', emoji: '📝', pack: 'school'),
    StickerDef(id: 'pin', emoji: '📌', pack: 'school'),
    StickerDef(id: 'books', emoji: '📚', pack: 'school'),
    StickerDef(id: 'brain', emoji: '🧠', pack: 'school'),
    StickerDef(id: 'idea', emoji: '💡', pack: 'school'),
    StickerDef(id: 'target', emoji: '🎯', pack: 'school'),
  ];

  static const marks = <StickerDef>[
    StickerDef(id: 'heart', emoji: '❤️', pack: 'marks'),
    StickerDef(id: 'fire', emoji: '🔥', pack: 'marks'),
    StickerDef(id: 'up', emoji: '👍', pack: 'marks'),
    StickerDef(id: 'clap', emoji: '👏', pack: 'marks'),
    StickerDef(id: 'party', emoji: '🎉', pack: 'marks'),
    StickerDef(id: 'sparkle', emoji: '✨', pack: 'marks'),
    StickerDef(id: 'right', emoji: '➡️', pack: 'marks'),
    StickerDef(id: 'upArrow', emoji: '⬆️', pack: 'marks'),
  ];

  static const mood = <StickerDef>[
    StickerDef(id: 'smile', emoji: '😊', pack: 'mood'),
    StickerDef(id: 'cool', emoji: '😎', pack: 'mood'),
    StickerDef(id: 'think', emoji: '🤔', pack: 'mood'),
    StickerDef(id: 'sweat', emoji: '😅', pack: 'mood'),
    StickerDef(id: 'love', emoji: '😍', pack: 'mood'),
    StickerDef(id: 'sleep', emoji: '😴', pack: 'mood'),
  ];

  static const packs = <String>['school', 'marks', 'mood'];

  static List<StickerDef> forPack(String pack) => switch (pack) {
    'marks' => marks,
    'mood' => mood,
    _ => school,
  };

  static const all = <StickerDef>[...school, ...marks, ...mood];

  static StickerDef? byId(String id) {
    for (final sticker in all) {
      if (sticker.id == id) return sticker;
    }
    return null;
  }

  static void paint(
    Canvas canvas,
    StickerDef def,
    Rect rect, {
    double opacity = 1,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: rect.shortestSide * 0.78,
        textAlign: TextAlign.center,
      ),
    )..addText(def.emoji);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: rect.width));
    if (opacity < 1) {
      canvas.saveLayer(
        rect,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
    }
    canvas.drawParagraph(
      paragraph,
      Offset(rect.left, rect.top + (rect.height - paragraph.height) / 2),
    );
    if (opacity < 1) canvas.restore();
  }
}
