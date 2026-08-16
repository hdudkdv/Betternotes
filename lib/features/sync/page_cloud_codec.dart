import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../data/models/notebook.dart';

/// Compresses page bodies for object storage and keeps Firestore pointers tiny.
abstract final class PageCloudCodec {
  static const pointerKind = 'pointer';
  static const cloudPrefix = 'cloud:';

  static Map<String, dynamic> bodyJson(NotePage page) {
    final json = page.toJson();
    json.remove('searchIndex');
    return json;
  }

  static String hashBody(Map<String, dynamic> body) {
    return sha256.convert(utf8.encode(jsonEncode(body))).toString();
  }

  static Uint8List encodeBody(Map<String, dynamic> body) {
    final raw = utf8.encode(jsonEncode(body));
    return Uint8List.fromList(GZipEncoder().encode(raw));
  }

  static Map<String, dynamic> decodeBody(Uint8List bytes) {
    final unzipped = GZipDecoder().decodeBytes(bytes, verify: false);
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(unzipped)) as Map);
  }

  static bool isPointer(Map<String, dynamic> json) {
    if (json['kind'] == pointerKind) return true;
    return json['blobKey'] is String && json['strokes'] == null;
  }

  static Map<String, dynamic> pointer({
    required NotePage page,
    required String contentHash,
    required String blobKey,
    List<String> assetKeys = const [],
  }) {
    return {
      'kind': pointerKind,
      'id': page.id,
      'notebookId': page.notebookId,
      'index': page.index,
      'template': page.template.name,
      'paperFormat': page.paperFormat.name,
      'orientation': page.orientation.name,
      'paperTemplateId': page.paperTemplateId,
      'updatedAt':
          page.updatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'contentHash': contentHash,
      'blobKey': blobKey,
      'assetKeys': assetKeys,
    };
  }

  static bool isRemotePath(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith(cloudPrefix);
  }

  static bool isUploadablePath(String? path) {
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('memory:')) return false;
    if (path.startsWith('nearby:')) return false;
    if (path.startsWith(cloudPrefix)) return false;
    return true;
  }

  static String cloudPath(String key) => '$cloudPrefix$key';

  static String? keyFromCloudPath(String? path) {
    if (!isRemotePath(path)) return null;
    return path!.substring(cloudPrefix.length);
  }
}
