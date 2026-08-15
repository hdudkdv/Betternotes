import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';

Future<List<String>> scanNativePages({int maxPages = 30}) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
    return const [];
  }
  try {
    final pictures = await CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      isGalleryImportAllowed: true,
    );
    if (pictures == null) return const [];
    return pictures.where((path) => path.isNotEmpty).toList();
  } catch (e, st) {
    assert(() {
      debugPrint('Native document scanner failed: $e\n$st');
      return true;
    }());
    return const [];
  }
}
