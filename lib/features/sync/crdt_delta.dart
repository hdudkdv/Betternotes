import 'vector_clock.dart';

enum CrdtOpType {
  addStroke,
  removeStroke,
  insertText,
  updateText,
  addPage,
  updatePage,
  addImage,
  checkpoint,
}

/// Atomic CRDT operation persisted locally and routed by [TransportManager].
class CrdtDelta {
  const CrdtDelta({
    required this.id,
    required this.notebookId,
    required this.type,
    required this.payload,
    required this.clock,
    required this.deviceId,
    required this.createdAt,
    this.pageId,
  });

  final String id;
  final String notebookId;
  final String? pageId;
  final CrdtOpType type;
  final Map<String, dynamic> payload;
  final VectorClock clock;
  final String deviceId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'notebookId': notebookId,
    'pageId': pageId,
    'type': type.name,
    'payload': payload,
    'clock': clock.toJson(),
    'deviceId': deviceId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CrdtDelta.fromJson(Map<String, dynamic> json) {
    return CrdtDelta(
      id: json['id'] as String,
      notebookId: json['notebookId'] as String,
      pageId: json['pageId'] as String?,
      type: CrdtOpType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CrdtOpType.checkpoint,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      clock: VectorClock.fromJson(
        json['clock'] == null
            ? null
            : Map<String, dynamic>.from(json['clock'] as Map),
      ),
      deviceId: json['deviceId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
