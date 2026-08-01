import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../data/models/notebook.dart';
import '../../../shared/utils/page_size.dart';
import 'widgets/ink_painter.dart';
import 'widgets/page_background_painter.dart';
import 'widgets/shape_painter.dart';

/// In-memory bitmap previews of notebook pages for fast page flips.
///
/// Neighbors are rendered while the UI is idle. Entries live up to [ttl]
/// (default one hour) and are evicted when memory pressure / max entries hit.
///
/// Listeners are **per page id** so warming one neighbor never rebuilds
/// unrelated snapshots mid-swipe.
class PagePreviewCache {
  PagePreviewCache._();

  static final PagePreviewCache instance = PagePreviewCache._();

  static const Duration ttl = Duration(hours: 1);
  static const int maxEntries = 24;
  static const double _maxEdge = 1280;

  final Map<String, _Entry> _byPageId = {};
  final Map<String, ValueNotifier<ui.Image?>> _notifiers = {};
  final Set<String> _inflight = {};
  Timer? _idleTimer;
  Timer? _evictTimer;
  int _generation = 0;
  bool _paused = false;
  bool _rendering = false;

  /// Per-page listenable — widgets should listen only to their own page.
  ValueNotifier<ui.Image?> listenableFor(String pageId) {
    return _notifiers.putIfAbsent(pageId, () => ValueNotifier<ui.Image?>(null));
  }

  /// Pause idle work while the user is actively swiping / drawing.
  void setPaused(bool paused) {
    _paused = paused;
  }

  /// Drop a page when its content is about to change (or was deleted).
  void invalidate(String pageId) {
    final entry = _byPageId.remove(pageId);
    entry?.image.dispose();
    final n = _notifiers[pageId];
    if (n != null) n.value = null;
  }

  /// Returns a still-valid preview for [page], or null on miss/stale.
  ui.Image? get(NotePage page) {
    _evictExpired(notify: false);
    final entry = _byPageId[page.id];
    if (entry == null) return null;
    if (entry.revision != revisionOf(page)) {
      _byPageId.remove(page.id);
      entry.image.dispose();
      final n = _notifiers[page.id];
      if (n != null) n.value = null;
      return null;
    }
    entry.lastAccess = DateTime.now();
    return entry.image;
  }

  /// Content fingerprint used to detect stale cache rows.
  static String revisionOf(NotePage page) {
    final updated = page.updatedAt?.microsecondsSinceEpoch ?? 0;
    return '$updated:${page.strokes.length}:${page.shapes.length}:'
        '${page.textBlocks.length}:${page.images.length}:'
        '${page.template.name}:${page.paperFormat.name}:'
        '${page.orientation.name}:${page.backgroundPdfPath ?? ''}';
  }

  /// Queue neighbor (±[radius]) prerenders once the UI has been idle briefly.
  void scheduleNeighbors(
    List<NotePage> pages,
    int index, {
    int radius = 3,
  }) {
    _idleTimer?.cancel();
    if (pages.isEmpty) return;
    final gen = ++_generation;
    _idleTimer = Timer(const Duration(milliseconds: 280), () {
      if (gen != _generation || _paused) return;
      unawaited(_preloadNeighbors(pages, index, radius: radius, gen: gen));
    });
    _ensureEvictTimer();
  }

  /// Warm the cache for [page] immediately (e.g. page just left / saved).
  Future<void> ensure(NotePage page, {bool force = false}) async {
    _evictExpired(notify: false);
    if (!force) {
      final existing = get(page);
      if (existing != null) return;
    }
    if (_inflight.contains(page.id)) return;
    _inflight.add(page.id);
    try {
      final image = await _render(page);
      if (image == null) return;
      _store(page, image);
    } finally {
      _inflight.remove(page.id);
    }
  }

  Future<void> _preloadNeighbors(
    List<NotePage> pages,
    int index, {
    required int radius,
    required int gen,
  }) async {
    if (_paused || gen != _generation) return;

    final order = <int>[index];
    for (var d = 1; d <= radius; d++) {
      order.add(index + d);
      order.add(index - d);
    }

    for (final i in order) {
      if (_paused || gen != _generation) return;
      if (i < 0 || i >= pages.length) continue;
      final page = pages[i];
      if (get(page) != null) continue;

      await _waitForIdle();
      if (_paused || gen != _generation) return;
      await ensure(page);
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _waitForIdle() async {
    while (_paused || _rendering) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    final completer = Completer<void>();
    SchedulerBinding.instance.scheduleTask(() {
      if (!completer.isCompleted) completer.complete();
    }, Priority.idle);
    await Future.any([
      completer.future,
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
  }

  Future<ui.Image?> _render(NotePage page) async {
    _rendering = true;
    try {
      final pageSize = NotePageSize.resolve(page.paperFormat, page.orientation);
      var scale = 1.5;
      final longest = math.max(pageSize.width, pageSize.height);
      if (longest * scale > _maxEdge) {
        scale = _maxEdge / longest;
      }
      final pw = math.max(1, (pageSize.width * scale).round());
      final ph = math.max(1, (pageSize.height * scale).round());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(scale, scale);

      PageBackgroundPainter(
        template: page.template,
        paper: page.customPaper,
      ).paint(canvas, pageSize);

      // Preview quality (live path) — much cheaper; fine for flip previews.
      InkPainter(strokes: page.strokes).paint(canvas, pageSize);
      ShapePainter(shapes: page.shapes).paint(canvas, pageSize);

      for (final block in page.textBlocks) {
        if (block.plainText.trim().isEmpty) continue;
        final style = block.spans.isNotEmpty ? block.spans.first : null;
        final fontSize = style?.fontSize ?? 16;
        final color = Color(style?.colorValue ?? 0xFF1A1A1A);
        final builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(fontSize: fontSize, maxLines: 12, ellipsis: '…'),
        )..pushStyle(ui.TextStyle(color: color, fontSize: fontSize));
        builder.addText(block.plainText);
        final paragraph = builder.build()
          ..layout(ui.ParagraphConstraints(width: block.width));
        canvas.drawParagraph(paragraph, Offset(block.x, block.y));
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(pw, ph);
      picture.dispose();
      return image;
    } catch (e, st) {
      assert(() {
        debugPrint('PagePreviewCache render failed: $e\n$st');
        return true;
      }());
      return null;
    } finally {
      _rendering = false;
    }
  }

  void _store(NotePage page, ui.Image image) {
    final revision = revisionOf(page);
    final previous = _byPageId.remove(page.id);
    // Keep previous image until notifier swap so the UI never flashes empty.
    _byPageId[page.id] = _Entry(
      image: image,
      revision: revision,
      createdAt: DateTime.now(),
      lastAccess: DateTime.now(),
    );
    listenableFor(page.id).value = image;
    previous?.image.dispose();
    _enforceLimits();
  }

  void _enforceLimits() {
    _evictExpired(notify: true);
    if (_byPageId.length <= maxEntries) return;
    final sorted = _byPageId.entries.toList()
      ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));
    final overflow = _byPageId.length - maxEntries;
    for (var i = 0; i < overflow; i++) {
      final id = sorted[i].key;
      final removed = _byPageId.remove(id);
      removed?.image.dispose();
      final n = _notifiers[id];
      if (n != null) n.value = null;
    }
  }

  void _evictExpired({required bool notify}) {
    final now = DateTime.now();
    final stale = <String>[];
    for (final e in _byPageId.entries) {
      if (now.difference(e.value.createdAt) > ttl) {
        stale.add(e.key);
      }
    }
    if (stale.isEmpty) return;
    for (final id in stale) {
      _byPageId.remove(id)?.image.dispose();
      if (notify) {
        final n = _notifiers[id];
        if (n != null) n.value = null;
      }
    }
  }

  void _ensureEvictTimer() {
    _evictTimer ??= Timer.periodic(const Duration(minutes: 5), (_) {
      final before = _byPageId.length;
      _evictExpired(notify: true);
      if (_byPageId.isEmpty && before == 0) {
        _evictTimer?.cancel();
        _evictTimer = null;
      }
    });
  }

  /// Test / shutdown helper.
  void clear() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _evictTimer?.cancel();
    _evictTimer = null;
    _generation++;
    for (final e in _byPageId.values) {
      e.image.dispose();
    }
    _byPageId.clear();
    for (final n in _notifiers.values) {
      n.value = null;
    }
    _inflight.clear();
  }
}

class _Entry {
  _Entry({
    required this.image,
    required this.revision,
    required this.createdAt,
    required this.lastAccess,
  });

  final ui.Image image;
  final String revision;
  final DateTime createdAt;
  DateTime lastAccess;
}
