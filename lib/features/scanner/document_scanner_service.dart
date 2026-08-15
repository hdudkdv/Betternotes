import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'scanner_bridge.dart';

/// Opens the system document scanner (VisionKit / ML Kit) with camera fallback.
class DocumentScannerService {
  const DocumentScannerService();

  Future<List<String>> scanPages({int maxPages = 30}) async {
    final native = await scanNativePages(maxPages: maxPages);
    if (native.isNotEmpty) return native;
    return _cameraFallback();
  }

  Future<List<String>> _cameraFallback() async {
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      if (shot == null) return const [];
      return [shot.path];
    } catch (e, st) {
      assert(() {
        debugPrint('Camera fallback failed: $e\n$st');
        return true;
      }());
      return const [];
    }
  }
}
