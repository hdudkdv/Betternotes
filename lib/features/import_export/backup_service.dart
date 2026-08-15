import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';

class BackupService {
  BackupService(this._repository);

  final NotebookRepository _repository;

  static const manifestVersion = 1;

  Future<File> buildBackupZip({SharedPreferences? prefs}) async {
    if (kIsWeb) throw UnsupportedError('Backup not available on web');

    final notebooks = await _repository.getNotebooks();
    final decks = await _repository.getAllFlashcardDecks();
    final folders = await _repository.getAllFolders();
    final papers = await _repository.getPaperTemplates();

    final notebookJson = <Map<String, dynamic>>[];
    final pagesJson = <Map<String, dynamic>>[];
    final cardsJson = <Map<String, dynamic>>[];

    for (final nb in notebooks) {
      notebookJson.add(nb.toJson());
      final pages = await _repository.getPages(nb.id);
      for (final page in pages) {
        pagesJson.add(page.toJson());
      }
      final outline = await _repository.getOutline(nb.id);
      if (outline.isNotEmpty) {
        notebookJson.last['outline'] = [
          for (final n in outline) n.toJson(),
        ];
      }
    }

    for (final deck in decks) {
      final cards = await _repository.getFlashcards(deck.id);
      cardsJson.addAll(cards.map((c) => c.toJson()));
    }

    final manifest = <String, dynamic>{
      'version': manifestVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'notebooks': notebookJson,
      'pages': pagesJson,
      'folders': [for (final f in folders) f.toJson()],
      'decks': [for (final d in decks) d.toJson()],
      'cards': cardsJson,
      'paperTemplates': [for (final t in papers) t.toJson()],
      if (prefs != null) ...{
        'plannerV1': prefs.getString('plannerV1'),
        'timetableV2': prefs.getString('timetableV2') ?? prefs.getString('timetableV1'),
        'userRole': prefs.getString('userRole'),
        'teacherTrack': prefs.getString('teacherTrack'),
        'profileSetupCompleted': prefs.getBool('profileSetupCompleted'),
        'teacherWorkspaceV1': prefs.getString('teacherWorkspaceV1'),
        'classroomAutoConnectEnabled':
            prefs.getBool('classroomAutoConnectEnabled'),
        'classroomAutoConnectAsked':
            prefs.getBool('classroomAutoConnectAsked'),
        'classroomAutoConnectSubject':
            prefs.getString('classroomAutoConnectSubject'),
        'classroomAutoConnectRoom':
            prefs.getString('classroomAutoConnectRoom'),
      },
    };

    final archive = Archive();
    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    final filesDir = await _repository.resolveFilesDir();
    final root = Directory(filesDir);
    if (await root.exists()) {
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final rel = p.relative(entity.path, from: filesDir).replaceAll('\\', '/');
        if (rel.startsWith('inbox/')) continue;
        final bytes = await entity.readAsBytes();
        archive.addFile(
          ArchiveFile('files/$rel', bytes.length, bytes),
        );
      }
    }

    final encoded = ZipEncoder().encode(archive);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final out = File(p.join(dir.path, 'betternotes_backup_$stamp.zip'));
    await out.writeAsBytes(Uint8List.fromList(encoded), flush: true);
    return out;
  }

  Future<void> shareBackup({SharedPreferences? prefs}) async {
    final file = await buildBackupZip(prefs: prefs);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: 'application/zip', name: p.basename(file.path)),
        ],
      ),
    );
  }

  Future<int> restoreFromPicker({
    required SharedPreferences prefs,
    required bool merge,
  }) async {
    if (kIsWeb) throw UnsupportedError('Restore not available on web');
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return 0;
    final bytes = result.files.first.bytes;
    if (bytes == null) return 0;
    return restoreFromBytes(bytes: bytes, prefs: prefs, merge: merge);
  }

  Future<int> restoreFromBytes({
    required Uint8List bytes,
    required SharedPreferences prefs,
    required bool merge,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    ArchiveFile? manifestFile;
    for (final f in archive) {
      if (f.name == 'manifest.json' || f.name.endsWith('/manifest.json')) {
        manifestFile = f;
        break;
      }
    }
    if (manifestFile == null) {
      throw StateError('Backup missing manifest.json');
    }
    final manifest = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map,
    );

    final filesDir = await _repository.resolveFilesDir();
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name.replaceAll('\\', '/');
      if (!name.contains('files/')) continue;
      final idx = name.indexOf('files/');
      final rel = name.substring(idx + 'files/'.length);
      if (rel.isEmpty) continue;
      final out = File(p.join(filesDir, rel));
      await out.parent.create(recursive: true);
      await out.writeAsBytes(Uint8List.fromList(entry.content as List<int>));
    }

    if (!merge) {
      final existing = await _repository.getNotebooks();
      for (final nb in existing) {
        await _repository.deleteNotebook(nb.id);
      }
      for (final deck in await _repository.getAllFlashcardDecks()) {
        await _repository.deleteFlashcardDeck(deck.id);
      }
    }

    final folders = [
      for (final item in (manifest['folders'] as List? ?? const []))
        LibraryFolder.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    for (final folder in folders) {
      await _repository.updateFolder(folder);
    }

    final notebooks = [
      for (final item in (manifest['notebooks'] as List? ?? const []))
        Map<String, dynamic>.from(item as Map),
    ];
    for (final raw in notebooks) {
      final outlineRaw = raw.remove('outline');
      final nb = Notebook.fromJson(raw);
      await _repository.upsertRemoteNotebook(nb);
      if (outlineRaw is List) {
        final nodes = [
          for (final n in outlineRaw)
            OutlineNode.fromJson(Map<String, dynamic>.from(n as Map)),
        ];
        await _repository.saveOutline(nb.id, nodes);
      }
    }

    final pages = [
      for (final item in (manifest['pages'] as List? ?? const []))
        NotePage.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    for (final page in pages) {
      await _repository.upsertRemotePage(page);
    }

    final decks = [
      for (final item in (manifest['decks'] as List? ?? const []))
        FlashcardDeck.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    for (final deck in decks) {
      await _repository.updateFlashcardDeck(deck);
    }

    final cards = [
      for (final item in (manifest['cards'] as List? ?? const []))
        Flashcard.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    for (final card in cards) {
      await _repository.saveFlashcard(card);
    }

    final papers = [
      for (final item in (manifest['paperTemplates'] as List? ?? const []))
        PaperTemplate.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    for (final paper in papers) {
      await _repository.savePaperTemplate(paper);
    }

    final planner = manifest['plannerV1'];
    if (planner is String && planner.isNotEmpty) {
      await prefs.setString('plannerV1', planner);
    }
    final timetable = manifest['timetableV2'] ?? manifest['timetableV1'];
    if (timetable is String && timetable.isNotEmpty) {
      await prefs.setString('timetableV2', timetable);
    }
    final userRole = manifest['userRole'];
    if (userRole is String && userRole.isNotEmpty) {
      await prefs.setString('userRole', userRole);
    }
    final teacherTrack = manifest['teacherTrack'];
    if (teacherTrack is String && teacherTrack.isNotEmpty) {
      await prefs.setString('teacherTrack', teacherTrack);
    }
    final profileSetup = manifest['profileSetupCompleted'];
    if (profileSetup is bool) {
      await prefs.setBool('profileSetupCompleted', profileSetup);
    }
    final teacherWorkspace = manifest['teacherWorkspaceV1'];
    if (teacherWorkspace is String && teacherWorkspace.isNotEmpty) {
      await prefs.setString('teacherWorkspaceV1', teacherWorkspace);
    }
    final autoConnectEnabled = manifest['classroomAutoConnectEnabled'];
    if (autoConnectEnabled is bool) {
      await prefs.setBool('classroomAutoConnectEnabled', autoConnectEnabled);
    }
    final autoConnectAsked = manifest['classroomAutoConnectAsked'];
    if (autoConnectAsked is bool) {
      await prefs.setBool('classroomAutoConnectAsked', autoConnectAsked);
    }
    final autoConnectSubject = manifest['classroomAutoConnectSubject'];
    if (autoConnectSubject is String) {
      await prefs.setString('classroomAutoConnectSubject', autoConnectSubject);
    }
    final autoConnectRoom = manifest['classroomAutoConnectRoom'];
    if (autoConnectRoom is String) {
      await prefs.setString('classroomAutoConnectRoom', autoConnectRoom);
    }

    return notebooks.length;
  }
}
