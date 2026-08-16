import 'dart:convert';
import 'dart:typed_data';

import 'file_store_base.dart';

export 'file_store_base.dart';

class WebFileStore implements FileStore {
  static final Map<String, Uint8List> _mem = {};

  static Uint8List? lookup(String path) {
    if (path.startsWith('memory:')) {
      try {
        return base64Decode(path.substring(7));
      } catch (_) {
        return null;
      }
    }
    return _mem[path];
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    final bytes = lookup(path);
    if (bytes == null) {
      throw StateError('Missing web file: $path');
    }
    return bytes;
  }

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    _mem[path] = bytes;
  }

  @override
  Uint8List? peekBytes(String path) => lookup(path);
}

FileStore createFileStore() => WebFileStore();
