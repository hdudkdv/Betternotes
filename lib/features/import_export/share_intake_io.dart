import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:share_handler/share_handler.dart';

import 'import_models.dart';
import 'share_intake.dart';

class IoShareIntake implements ShareIntake {
  IoShareIntake({required this.stagePath});

  final Future<InboxFile> Function({
    required String sourcePath,
    String? name,
    String? mimeType,
  })
  stagePath;

  final _controller = StreamController<List<InboxFile>>.broadcast();
  StreamSubscription<SharedMedia>? _sub;
  List<InboxFile>? _pending;
  bool _started = false;

  @override
  Stream<List<InboxFile>> get pending => _controller.stream;

  @override
  List<InboxFile>? get peekPending => _pending;

  @override
  Future<void> start() async {
    if (_started || kIsWeb) return;
    _started = true;
    try {
      final handler = ShareHandler.instance;
      final initial = await handler.getInitialSharedMedia();
      if (initial != null) {
        await _handle(initial);
        await handler.resetInitialSharedMedia();
      }
      _sub = handler.sharedMediaStream.listen(_handle);
    } catch (_) {
      // Plugin unavailable on this platform build.
    }
  }

  Future<void> _handle(SharedMedia media) async {
    final staged = <InboxFile>[];
    final attachments = media.attachments ?? const [];
      for (final attachment in attachments) {
      if (attachment == null) continue;
      final path = attachment.path;
      if (path.isEmpty) continue;
      try {
        staged.add(
          await stagePath(
            sourcePath: path,
            name: path.split(RegExp(r'[/\\]')).last,
            mimeType: null,
          ),
        );
      } catch (_) {}
    }
    final content = media.content?.trim();
    if (staged.isEmpty && content != null && content.isNotEmpty) {
      // Text shares are ignored for notebook import; user can paste manually.
    }
    if (staged.isNotEmpty) offer(staged);
  }

  @override
  void offer(List<InboxFile> files) {
    if (files.isEmpty) return;
    _pending = files;
    _controller.add(List.unmodifiable(files));
  }

  @override
  List<InboxFile>? takePending() {
    final value = _pending;
    _pending = null;
    return value;
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
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
  return IoShareIntake(stagePath: stagePath);
}
