import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';

/// Max raw bytes per asset chunk before base64 (~120 KiB keeps frames small).
const int kLanAssetChunkBytes = 120 * 1024;

class LanPackedAssets {
  const LanPackedAssets({
    required this.pagesJson,
    required this.assets,
  });

  final List<Map<String, dynamic>> pagesJson;
  final List<LanAssetDescriptor> assets;
}

class LanAssetDescriptor {
  const LanAssetDescriptor({
    required this.key,
    required this.fileName,
    required this.bytes,
  });

  final String key;
  final String fileName;
  final Uint8List bytes;
}

/// Collects local PDF/image files referenced by pages and rewrites paths to
/// `nearby://<key>` placeholders for transport.
Future<LanPackedAssets> packPageAssets(List<NotePage> pages) async {
  final pathToKey = <String, String>{};
  final assets = <LanAssetDescriptor>[];

  Future<String?> ensureAsset(String? path) async {
    if (path == null || path.isEmpty) return path;
    if (path.startsWith('nearby://')) return path;
    if (pathToKey.containsKey(path)) return 'nearby://${pathToKey[path]}';
    final file = File(path);
    if (!await file.exists()) return path;
    final bytes = await file.readAsBytes();
    final key = sha1.convert(utf8.encode(path)).toString().substring(0, 16);
    pathToKey[path] = key;
    assets.add(
      LanAssetDescriptor(
        key: key,
        fileName: p.basename(path),
        bytes: bytes,
      ),
    );
    return 'nearby://$key';
  }

  final pagesJson = <Map<String, dynamic>>[];
  for (final page in pages) {
    final json = page.toJson();
    json['backgroundPdfPath'] = await ensureAsset(page.backgroundPdfPath);
    final images = <Map<String, dynamic>>[];
    for (final image in page.images) {
      final imageJson = image.toJson();
      imageJson['localPath'] = await ensureAsset(image.localPath);
      images.add(imageJson);
    }
    json['images'] = images;
    pagesJson.add(json);
  }

  return LanPackedAssets(pagesJson: pagesJson, assets: assets);
}

Future<Map<String, dynamic>> packSinglePage(NotePage page) async {
  final packed = await packPageAssets([page]);
  return {
    'page': packed.pagesJson.first,
    'assets': packed.assets,
  };
}

/// Writes received asset bytes under the notebook files dir and returns the
/// local absolute path.
Future<String> writeNearbyAsset({
  required NotebookRepository repository,
  required String notebookId,
  required String key,
  required String fileName,
  required Uint8List bytes,
}) async {
  final root = await repository.resolveFilesDir();
  final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
  final dir = Directory(p.join(root, 'nearby', notebookId));
  await dir.create(recursive: true);
  final path = p.join(dir.path, '${key}_$safeName');
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

Map<String, dynamic> remapPageAssetPaths(
  Map<String, dynamic> pageJson,
  Map<String, String> keyToPath,
) {
  final out = Map<String, dynamic>.from(pageJson);
  final bg = out['backgroundPdfPath']?.toString();
  if (bg != null && bg.startsWith('nearby://')) {
    final key = bg.substring('nearby://'.length);
    out['backgroundPdfPath'] = keyToPath[key] ?? bg;
  }
  final images = <Map<String, dynamic>>[];
  for (final raw in (out['images'] as List? ?? const [])) {
    if (raw is! Map) continue;
    final image = Map<String, dynamic>.from(raw);
    final path = image['localPath']?.toString();
    if (path != null && path.startsWith('nearby://')) {
      final key = path.substring('nearby://'.length);
      image['localPath'] = keyToPath[key] ?? path;
    }
    images.add(image);
  }
  out['images'] = images;
  return out;
}

List<Map<String, dynamic>> chunkAssetMessages(LanAssetDescriptor asset) {
  final total = (asset.bytes.length / kLanAssetChunkBytes).ceil().clamp(1, 0x7fffffff);
  final messages = <Map<String, dynamic>>[
    {
      'type': 'asset_meta',
      'key': asset.key,
      'fileName': asset.fileName,
      'size': asset.bytes.length,
      'totalChunks': total,
    },
  ];
  for (var i = 0; i < total; i++) {
    final start = i * kLanAssetChunkBytes;
    final end = (start + kLanAssetChunkBytes).clamp(0, asset.bytes.length);
    final slice = asset.bytes.sublist(start, end);
    messages.add({
      'type': 'asset_chunk',
      'key': asset.key,
      'index': i,
      'data': base64Encode(slice),
    });
  }
  return messages;
}
