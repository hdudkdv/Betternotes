import 'dart:typed_data';

abstract class FileStore {
  Future<void> writeBytes(String path, Uint8List bytes);
  Future<Uint8List> readBytes(String path);
}
