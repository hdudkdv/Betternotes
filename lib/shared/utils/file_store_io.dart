import 'dart:io';
import 'dart:typed_data';

import 'file_store_base.dart';

export 'file_store_base.dart';

class IoFileStore implements FileStore {
  @override
  Future<Uint8List> readBytes(String path) => File(path).readAsBytes();

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }
}

FileStore createFileStore() => IoFileStore();
