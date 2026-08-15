import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as ink;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../editor/domain/ink_models.dart';

bool get _supported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

ink.DigitalInkRecognizer? _inkRecognizer;
String? _inkLanguage;
TextRecognizer? _textRecognizer;

Future<String> recognizeInkImpl(List<InkStroke> strokes) async {
  if (!_supported || strokes.isEmpty) return '';
  try {
    const language = 'de';
    if (_inkRecognizer == null || _inkLanguage != language) {
      await _inkRecognizer?.close();
      final manager = ink.DigitalInkRecognizerModelManager();
      if (!await manager.isModelDownloaded(language)) {
        await manager.downloadModel(language);
      }
      _inkRecognizer = ink.DigitalInkRecognizer(languageCode: language);
      _inkLanguage = language;
    }
    final payload = ink.Ink();
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final line = ink.Stroke();
      line.points = [
        for (final point in stroke.points)
          ink.StrokePoint(x: point.x, y: point.y, t: point.t),
      ];
      payload.strokes.add(line);
    }
    if (payload.strokes.isEmpty) return '';
    final candidates = await _inkRecognizer!.recognize(payload);
    if (candidates.isEmpty) return '';
    return candidates.first.text;
  } catch (e, st) {
    assert(() {
      debugPrint('Digital ink recognition failed: $e\n$st');
      return true;
    }());
    return '';
  }
}

Future<String> recognizeImagePathImpl(String path) async {
  if (!_supported) return '';
  if (path.isEmpty || path.startsWith('memory:')) return '';
  final file = File(path);
  if (!file.existsSync()) return '';
  try {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    final input = InputImage.fromFile(file);
    final result = await _textRecognizer!.processImage(input);
    return result.text;
  } catch (e, st) {
    assert(() {
      debugPrint('Text recognition failed: $e\n$st');
      return true;
    }());
    return '';
  }
}
