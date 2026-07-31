import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/providers/library_providers.dart';
import 'backup_service.dart';
import 'export_service.dart';
import 'inbox_service.dart';
import 'import_pipeline.dart';
import 'share_intake.dart';

final inboxServiceProvider = Provider<InboxService>((ref) {
  return InboxService(ref.watch(notebookRepositoryProvider));
});

final importPipelineProvider = Provider<ImportPipeline>((ref) {
  return ImportPipeline(
    repository: ref.watch(notebookRepositoryProvider),
    pdfService: ref.watch(pdfServiceProvider),
    inbox: ref.watch(inboxServiceProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    pdfService: ref.watch(pdfServiceProvider),
  );
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(notebookRepositoryProvider));
});

final shareIntakeProvider = Provider<ShareIntake>((ref) {
  final inbox = ref.watch(inboxServiceProvider);
  final intake = createShareIntake(stagePath: inbox.stagePath);
  ref.onDispose(() => intake.dispose());
  return intake;
});

final allNotebooksProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(notebookRepositoryProvider).getNotebooks();
});
