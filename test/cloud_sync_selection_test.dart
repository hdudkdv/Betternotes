import 'dart:convert';

import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/features/entitlements/entitlement_model.dart';
import 'package:betternotes/features/library/live_folder.dart';
import 'package:betternotes/features/sync/cloud_sync_selection.dart';
import 'package:flutter_test/flutter_test.dart';

SyncOp _op({
  required String type,
  required String entityId,
  String payload = '{}',
}) {
  return SyncOp(
    id: 'op',
    entityType: type,
    entityId: entityId,
    payloadJson: payload,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  test('live folder uses a stable system id', () {
    expect(kLiveFolderId, 'sys_live');
  });

  test('lite syncs only selected notebooks, pro syncs all', () {
    const selected = {'a', 'b'};
    expect(
      cloudSyncsNotebook('a', paid: PaidTier.lite, selected: selected),
      isTrue,
    );
    expect(
      cloudSyncsNotebook('c', paid: PaidTier.lite, selected: selected),
      isFalse,
    );
    expect(
      cloudSyncsNotebook('c', paid: PaidTier.pro, selected: selected),
      isTrue,
    );
    expect(
      cloudSyncsNotebook('a', paid: PaidTier.free, selected: selected),
      isFalse,
    );
    expect(cloudNotebookLimit(PaidTier.lite), 5);
    expect(cloudNotebookLimit(PaidTier.pro), isNull);
  });

  test('page ops resolve notebook id from payload', () {
    final op = _op(
      type: 'page',
      entityId: 'page-1',
      payload: jsonEncode({'notebookId': 'nb-9', 'id': 'page-1'}),
    );
    expect(notebookIdForSyncOp(op), 'nb-9');
    expect(
      shouldPushCloudOp(op, paid: PaidTier.lite, selected: {'nb-9'}),
      isTrue,
    );
    expect(
      shouldPushCloudOp(op, paid: PaidTier.lite, selected: {'other'}),
      isFalse,
    );
  });
}
