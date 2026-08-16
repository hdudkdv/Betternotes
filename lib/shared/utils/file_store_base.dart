import 'dart:typed_data';

abstract class FileStore {
  Future<void> writeBytes(String path, Uint8List bytes);
  Future<Uint8List> readBytes(String path);

  /// Immediate cache lookup used by image widgets. Disk-backed stores
  /// return null and let [Image.file] load the path instead.
  Uint8List? peekBytes(String path) => null;
}
