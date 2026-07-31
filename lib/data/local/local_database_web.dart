import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/notebook_repository.dart';
import '../repositories/prefs_notebook_repository.dart';

abstract final class LocalDatabase {
  static NotebookRepository? _repository;

  static NotebookRepository get repository {
    final repo = _repository;
    if (repo == null) {
      throw StateError('LocalDatabase not initialized');
    }
    return repo;
  }

  static Future<NotebookRepository> init() async {
    if (_repository != null) return _repository!;
    final prefs = await SharedPreferences.getInstance();
    _repository = PrefsNotebookRepository(prefs);
    return _repository!;
  }
}
