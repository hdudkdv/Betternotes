import 'dart:typed_data';

import 'file_store_base.dart';

export 'file_store_base.dart';

class WebFileStore implements FileStore {
  @override
  Future<Uint8List> readBytes(String path) {
    throw UnsupportedError('Use memory: paths on web');
  }

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {}
}

FileStore createFileStore() => WebFileStore();
