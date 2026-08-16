import 'crdt_delta.dart';

/// Tiny live channel used only when a second device is online.
abstract class LiveChannel {
  Future<void> heartbeat({required String notebookId});

  Future<bool> hasRemotePeer();

  Future<void> publish(CrdtDelta delta);

  Stream<CrdtDelta> watch(String notebookId);

  Future<void> dispose();
}
