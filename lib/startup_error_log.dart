import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last startup/runtime failure so it can be shown on the next launch
/// when the process was killed before a Flutter error screen could appear.
abstract final class StartupErrorLog {
  static const _key = 'betternotes.startup_error_log';
  static const _maxChars = 4000;

  static Future<void> write(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clipped = message.length > _maxChars
          ? message.substring(0, _maxChars)
          : message;
      await prefs.setString(_key, clipped);
    } catch (error) {
      debugPrint('StartupErrorLog.write failed: $error');
    }
  }

  static Future<void> breadcrumb(String message) async {
    await write('ok: $message');
  }

  static Future<String?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
