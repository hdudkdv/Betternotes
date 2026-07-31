import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../library/providers/library_providers.dart';

/// Remembers the page a notebook was left on, per device.
///
/// This is view state, so it stays local instead of travelling with the
/// notebook through sync.
class LastPageStore {
  const LastPageStore(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'bn_last_page_';

  String? read(String notebookId) => _prefs.getString('$_prefix$notebookId');

  Future<void> write(String notebookId, String pageId) =>
      _prefs.setString('$_prefix$notebookId', pageId);

  Future<void> clear(String notebookId) => _prefs.remove('$_prefix$notebookId');
}

final lastPageStoreProvider = Provider<LastPageStore>((ref) {
  return LastPageStore(ref.watch(sharedPreferencesProvider));
});
