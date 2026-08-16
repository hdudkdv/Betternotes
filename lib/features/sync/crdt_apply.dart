import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../editor/domain/ink_models.dart';
import 'crdt_delta.dart';
import 'vector_clock.dart';

NotePage applyCrdtDelta(NotePage page, CrdtDelta delta) {
  switch (delta.type) {
    case CrdtOpType.addStroke:
      final strokeJson = delta.payload['stroke'];
      if (strokeJson is! Map) return page;
      final stroke = InkStroke.fromJson(
        Map<String, dynamic>.from(strokeJson),
      );
      if (page.strokes.any((s) => s.id == stroke.id)) return page;
      return page.copyWith(
        strokes: [...page.strokes, stroke],
        updatedAt: delta.createdAt,
      );
    case CrdtOpType.removeStroke:
      final id = delta.payload['strokeId']?.toString();
      if (id == null || id.isEmpty) return page;
      return page.copyWith(
        strokes: [for (final s in page.strokes) if (s.id != id) s],
        updatedAt: delta.createdAt,
      );
    case CrdtOpType.insertText:
    case CrdtOpType.updateText:
      final blockJson = delta.payload['block'];
      if (blockJson is! Map) return page;
      final block = TextBlock.fromJson(Map<String, dynamic>.from(blockJson));
      final existing = page.textBlocks.indexWhere((b) => b.id == block.id);
      final next = [...page.textBlocks];
      if (existing >= 0) {
        next[existing] = block;
      } else {
        next.add(block);
      }
      return page.copyWith(textBlocks: next, updatedAt: delta.createdAt);
    case CrdtOpType.addImage:
      final imageJson = delta.payload['image'];
      if (imageJson is! Map) return page;
      final image = ImageElement.fromJson(
        Map<String, dynamic>.from(imageJson),
      );
      if (page.images.any((i) => i.id == image.id)) return page;
      return page.copyWith(
        images: [...page.images, image],
        updatedAt: delta.createdAt,
      );
    case CrdtOpType.addPage:
    case CrdtOpType.updatePage:
    case CrdtOpType.checkpoint:
      return page;
  }
}

List<CrdtDelta> diffsBetweenPages({
  required NotePage? previous,
  required NotePage next,
  required String deviceId,
  required VectorClock clock,
}) {
  final deltas = <CrdtDelta>[];
  var currentClock = clock;
  void add(CrdtOpType type, Map<String, dynamic> payload) {
    currentClock = currentClock.increment(deviceId);
    deltas.add(
      CrdtDelta(
        id: '${next.id}_${type.name}_${currentClock.ticks[deviceId]}',
        notebookId: next.notebookId,
        pageId: next.id,
        type: type,
        payload: payload,
        clock: currentClock,
        deviceId: deviceId,
        createdAt: next.updatedAt ?? DateTime.now(),
      ),
    );
  }

  final beforeStrokes = {for (final s in previous?.strokes ?? const []) s.id};
  for (final stroke in next.strokes) {
    if (!beforeStrokes.contains(stroke.id)) {
      add(CrdtOpType.addStroke, {'stroke': stroke.toJson()});
    }
  }
  final afterStrokes = {for (final s in next.strokes) s.id};
  for (final stroke in previous?.strokes ?? const <InkStroke>[]) {
    if (!afterStrokes.contains(stroke.id)) {
      add(CrdtOpType.removeStroke, {'strokeId': stroke.id});
    }
  }

  final beforeText = {
    for (final block in previous?.textBlocks ?? const []) block.id: block,
  };
  for (final block in next.textBlocks) {
    final old = beforeText[block.id];
    if (old == null) {
      add(CrdtOpType.insertText, {'block': block.toJson()});
    } else if (old.plainText != block.plainText ||
        old.x != block.x ||
        old.y != block.y) {
      add(CrdtOpType.updateText, {'block': block.toJson()});
    }
  }

  final beforeImages = {for (final image in previous?.images ?? const []) image.id};
  for (final image in next.images) {
    if (!beforeImages.contains(image.id)) {
      add(CrdtOpType.addImage, {'image': image.toJson()});
    }
  }

  return deltas;
}
