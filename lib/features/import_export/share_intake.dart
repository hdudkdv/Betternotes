import 'import_models.dart';

import 'share_intake_stub.dart'
    if (dart.library.io) 'share_intake_io.dart' as impl;

/// Pending shared/import files waiting for notebook selection.
abstract class ShareIntake {
  Stream<List<InboxFile>> get pending;

  /// Pending files without clearing (for cold-start navigation).
  List<InboxFile>? get peekPending;

  Future<void> start();

  void offer(List<InboxFile> files);

  List<InboxFile>? takePending();

  Future<void> dispose();
}

ShareIntake createShareIntake({
  required Future<InboxFile> Function({
    required String sourcePath,
    String? name,
    String? mimeType,
  })
  stagePath,
}) {
  return impl.createShareIntakeImpl(stagePath: stagePath);
}
