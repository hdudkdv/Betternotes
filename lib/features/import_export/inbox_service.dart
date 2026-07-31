import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../data/repositories/notebook_repository.dart';
import 'import_models.dart';

class InboxService {
  InboxService(this._repository);

  final NotebookRepository _repository;
  static const _uuid = Uuid();

  Future<String> _inboxDir() async {
    final root = await _repository.resolveFilesDir();
    final dir = Directory(p.join(root, 'inbox'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> _attachmentsDir() async {
    final root = await _repository.resolveFilesDir();
    final dir = Directory(p.join(root, 'attachments'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<InboxFile> stageBytes({
    required Uint8List bytes,
    required String name,
    String? mimeType,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Inbox staging is not available on web');
    }
    final safe = _safeName(name);
    final out = p.join(await _inboxDir(), '${_uuid.v4()}_$safe');
    await File(out).writeAsBytes(bytes);
    return InboxFile(path: out, name: safe, mimeType: mimeType);
  }

  Future<InboxFile> stagePath({
    required String sourcePath,
    String? name,
    String? mimeType,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Inbox staging is not available on web');
    }
    final source = File(sourcePath);
    final bytes = await source.readAsBytes();
    return stageBytes(
      bytes: bytes,
      name: name ?? p.basename(sourcePath),
      mimeType: mimeType,
    );
  }

  Future<String> persistAttachment({
    required Uint8List bytes,
    required String name,
  }) async {
    final safe = _safeName(name);
    final out = p.join(await _attachmentsDir(), '${_uuid.v4()}_$safe');
    await File(out).writeAsBytes(bytes);
    return out;
  }

  String _safeName(String name) {
    final base = p.basename(name).replaceAll(RegExp(r'[^\w.\- ()\[\]]+'), '_');
    return base.isEmpty ? 'file.bin' : base;
  }
}
