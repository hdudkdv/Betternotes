import 'dart:async';

import 'import_models.dart';
import 'share_intake.dart';

class _StubShareIntake implements ShareIntake {
  final _controller = StreamController<List<InboxFile>>.broadcast();
  List<InboxFile>? _pending;

  @override
  Stream<List<InboxFile>> get pending => _controller.stream;

  @override
  List<InboxFile>? get peekPending => _pending;

  @override
  Future<void> start() async {}

  @override
  void offer(List<InboxFile> files) {
    if (files.isEmpty) return;
    _pending = files;
    _controller.add(files);
  }

  @override
  List<InboxFile>? takePending() {
    final value = _pending;
    _pending = null;
    return value;
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

ShareIntake createShareIntakeImpl({
  required Future<InboxFile> Function({
    required String sourcePath,
    String? name,
    String? mimeType,
  })
  stagePath,
}) {
  return _StubShareIntake();
}
