import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

Future<List<({String rel, Uint8List bytes})>> listBackupFiles(
  String filesDir,
) async {
  final root = Directory(filesDir);
  if (!await root.exists()) return const [];
  final out = <({String rel, Uint8List bytes})>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final rel = p.relative(entity.path, from: filesDir).replaceAll('\\', '/');
    if (rel.startsWith('inbox/')) continue;
    out.add((rel: rel, bytes: await entity.readAsBytes()));
  }
  return out;
}
