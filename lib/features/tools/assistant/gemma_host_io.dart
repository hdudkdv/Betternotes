import 'dart:io';

class GemmaHost {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static int get processorCount =>
      Platform.numberOfProcessors < 1 ? 4 : Platform.numberOfProcessors;
}
