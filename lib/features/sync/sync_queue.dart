import '../../data/models/content_models.dart';

/// Keeps one pending snapshot per notebook/page so drawing does not enqueue
/// a full document on every 450 ms save.
List<SyncOp> appendCoalesced(List<SyncOp> ops, SyncOp incoming) {
  if (incoming.entityType == 'page' || incoming.entityType == 'notebook') {
    return [
      for (final op in ops)
        if (op.synced ||
            op.entityType != incoming.entityType ||
            op.entityId != incoming.entityId)
          op,
      incoming,
    ];
  }
  return [...ops, incoming];
}
