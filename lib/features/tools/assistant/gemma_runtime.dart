// On-device Gemma (MediaPipe / LiteRT) is stubbed on all platforms for now.
// flutter_gemma's native libraries abort() in dyld static constructors on
// iPadOS 26 (App Store crash 1.0.3+10, IPS FAE3C264). Re-enable
// gemma_runtime_io.dart plus the pubspec dependency once that is fixed.
export 'gemma_runtime_stub.dart';
