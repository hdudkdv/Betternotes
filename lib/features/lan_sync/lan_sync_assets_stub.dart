import 'dart:typed_data';

import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';

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

Future<LanPackedAssets> packPageAssets(List<NotePage> pages) async {
  return LanPackedAssets(
    pagesJson: [for (final page in pages) page.toJson()],
    assets: const [],
  );
}

Future<Map<String, dynamic>> packSinglePage(NotePage page) async {
  return {'page': page.toJson(), 'assets': <LanAssetDescriptor>[]};
}

Future<String> writeNearbyAsset({
  required NotebookRepository repository,
  required String notebookId,
  required String key,
  required String fileName,
  required Uint8List bytes,
}) async {
  return 'web_files/nearby/$notebookId/${key}_$fileName';
}

Map<String, dynamic> remapPageAssetPaths(
  Map<String, dynamic> pageJson,
  Map<String, String> keyToPath,
) => Map<String, dynamic>.from(pageJson);

List<Map<String, dynamic>> chunkAssetMessages(LanAssetDescriptor asset) =>
    const [];
