import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../data/repositories/notebook_repository.dart';
import '../../shared/utils/file_store.dart';
import 'import_models.dart';

class InboxService {
  InboxService(this._repository);

  final NotebookRepository _repository;
  final FileStore _files = createFileStore();
  static const _uuid = Uuid();

  Future<String> _inboxDir() async {
    return p.join(await _repository.resolveFilesDir(), 'inbox');
  }

  Future<String> _attachmentsDir() async {
    return p.join(await _repository.resolveFilesDir(), 'attachments');
  }

  Future<InboxFile> stageBytes({
    required Uint8List bytes,
    required String name,
    String? mimeType,
  }) async {
    final safe = _safeName(name);
    final out = p.join(await _inboxDir(), '${_uuid.v4()}_$safe');
    await _files.writeBytes(out, bytes);
    return InboxFile(path: out, name: safe, mimeType: mimeType, bytes: bytes);
  }

  Future<InboxFile> stagePath({
    required String sourcePath,
    String? name,
    String? mimeType,
  }) async {
    final bytes = await _files.readBytes(sourcePath);
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
    await _files.writeBytes(out, bytes);
    return out;
  }

  String _safeName(String name) {
    final base = p.basename(name).replaceAll(RegExp(r'[^\w.\- ()\[\]]+'), '_');
    return base.isEmpty ? 'file.bin' : base;
  }
}
