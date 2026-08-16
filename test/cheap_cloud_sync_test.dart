import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/data/models/notebook.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:betternotes/features/sync/crdt_apply.dart';
import 'package:betternotes/features/sync/crdt_delta.dart';
import 'package:betternotes/features/sync/page_cloud_codec.dart';
import 'package:betternotes/features/sync/sync_queue.dart';
import 'package:betternotes/features/sync/vector_clock.dart';
import 'package:betternotes/shared/utils/page_size.dart';
import 'package:flutter_test/flutter_test.dart';

NotePage _page({
  List<InkStroke> strokes = const [],
  String? searchIndex,
}) {
  return NotePage(
    id: 'p1',
    notebookId: 'n1',
    index: 0,
    template: PageTemplate.lined,
    strokes: strokes,
    searchIndex: searchIndex,
    paperFormat: PaperFormat.a4,
    orientation: PageOrientation.portrait,
  );
}

void main() {
  test('page cloud codec strips searchIndex and round-trips gzip', () {
    final page = _page(
      searchIndex: 'secret local index',
      strokes: [
        InkStroke(
          id: 's1',
          tool: InkTool.pen,
          colorValue: 0xFF000000,
          width: 2,
          points: const [StrokePoint(x: 1, y: 2, pressure: 0.5, t: 0)],
        ),
      ],
    );
    final body = PageCloudCodec.bodyJson(page);
    expect(body.containsKey('searchIndex'), isFalse);
    final encoded = PageCloudCodec.encodeBody(body);
    final decoded = PageCloudCodec.decodeBody(encoded);
    expect(decoded['id'], 'p1');
    expect(decoded['strokes'], isNotEmpty);
    expect(PageCloudCodec.isPointer(PageCloudCodec.pointer(
      page: page,
      contentHash: 'abc',
      blobKey: 'pages/p1/abc.bin',
    )), isTrue);
  });

  test('queue coalesces pending page snapshots', () {
    final first = SyncOp(
      id: '1',
      entityType: 'page',
      entityId: 'p1',
      payloadJson: '{"n":1}',
      createdAt: DateTime(2026, 1, 1),
    );
    final second = SyncOp(
      id: '2',
      entityType: 'page',
      entityId: 'p1',
      payloadJson: '{"n":2}',
      createdAt: DateTime(2026, 1, 2),
    );
    final notebook = SyncOp(
      id: '3',
      entityType: 'notebook',
      entityId: 'n1',
      payloadJson: '{}',
      createdAt: DateTime(2026, 1, 3),
    );
    final queued = appendCoalesced(appendCoalesced([first], second), notebook);
    expect(queued, hasLength(2));
    expect(queued.first.id, '2');
    expect(queued.last.id, '3');
  });

  test('CRDT add/remove stroke is idempotent', () {
    final empty = _page();
    final stroke = InkStroke(
      id: 's1',
      tool: InkTool.pen,
      colorValue: 0xFF000000,
      width: 2,
      points: const [StrokePoint(x: 4, y: 8, pressure: 1, t: 1)],
    );
    final add = CrdtDelta(
      id: 'd1',
      notebookId: 'n1',
      pageId: 'p1',
      type: CrdtOpType.addStroke,
      payload: {'stroke': stroke.toJson()},
      clock: VectorClock.empty().increment('dev'),
      deviceId: 'dev',
      createdAt: DateTime(2026, 2, 1),
    );
    final once = applyCrdtDelta(empty, add);
    final twice = applyCrdtDelta(once, add);
    expect(twice.strokes, hasLength(1));
    final removed = applyCrdtDelta(
      twice,
      CrdtDelta(
        id: 'd2',
        notebookId: 'n1',
        pageId: 'p1',
        type: CrdtOpType.removeStroke,
        payload: {'strokeId': 's1'},
        clock: VectorClock.empty().increment('dev'),
        deviceId: 'dev',
        createdAt: DateTime(2026, 2, 2),
      ),
    );
    expect(removed.strokes, isEmpty);
  });
}
