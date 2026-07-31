import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../shared/utils/file_store.dart';

/// Persist scanned worksheets / exams next to a grade entry.
class GradeAttachmentStore {
  GradeAttachmentStore({FileStore? store})
    : _store = store ?? createFileStore();

  final FileStore _store;
  final _uuid = const Uuid();

  Future<String> _dirFor(String gradeId) async {
    final root = await getApplicationDocumentsDirectory();
    return p.join(root.path, 'grade_scans', gradeId);
  }

  Future<String?> pickFromGallery() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await _store.readBytes(file.path!);
    }
    if (bytes == null) return null;
    return _writeTemp(bytes, file.extension ?? 'jpg');
  }

  Future<String?> pickFromCamera() async {
    final picker = ImagePicker();
    final shot = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (shot == null) return null;
    final bytes = await shot.readAsBytes();
    final ext = p.extension(shot.path).replaceAll('.', '');
    return _writeTemp(bytes, ext.isEmpty ? 'jpg' : ext);
  }

  Future<String> _writeTemp(Uint8List bytes, String ext) async {
    final root = await getApplicationDocumentsDirectory();
    final clean = ext.replaceAll('.', '');
    final tmp = p.join(
      root.path,
      'grade_scans',
      '_inbox',
      '${_uuid.v4()}.$clean',
    );
    await _store.writeBytes(tmp, bytes);
    return tmp;
  }

  /// Move inbox / external paths into the grade folder; returns final paths.
  Future<List<String>> commitForGrade({
    required String gradeId,
    required List<String> paths,
  }) async {
    final dir = await _dirFor(gradeId);
    final out = <String>[];
    for (final path in paths) {
      if (path.contains(p.join('grade_scans', gradeId))) {
        out.add(path);
        continue;
      }
      final bytes = await _store.readBytes(path);
      final ext = p.extension(path).replaceAll('.', '');
      final dest = p.join(dir, '${_uuid.v4()}.${ext.isEmpty ? 'jpg' : ext}');
      await _store.writeBytes(dest, bytes);
      out.add(dest);
    }
    return out;
  }
}
