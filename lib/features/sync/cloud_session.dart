import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notebook.dart';
import '../auth/auth_repository.dart';
import '../entitlements/entitlement_model.dart';
import '../library/account_handover_sheet.dart';
import '../library/account_library_service.dart';
import '../library/providers/library_providers.dart';
import '../planner/planner_model.dart';
import '../teacher/gradebook/gradebook_store.dart';
import '../timetable/timetable_model.dart';
import 'sync_engine.dart';

Future<void> loadCloudNotebooks(
  WidgetRef ref, {
  bool replaceLocal = false,
}) async {
  await ref.read(syncEngineProvider).bootstrapCloud(
    replaceLocal: replaceLocal || kIsWeb,
  );
  ref.read(entitlementProvider.notifier).reloadFromPrefs();
  ref.read(settingsProvider.notifier).reloadFromPrefs();
  ref.invalidate(plannerProvider);
  ref.invalidate(timetableProvider);
  ref.invalidate(gradebookProvider);
  refreshLibraryLists(ref);
}

Future<void> _applyHandover({
  required AccountLibraryService service,
  required LibraryHandoverAction action,
  required List<Notebook> notebooks,
  required String ownerUid,
}) async {
  switch (action) {
    case LibraryHandoverAction.deleteLocal:
      await service.deleteLocal(notebooks);
    case LibraryHandoverAction.saveToCloud:
      await service.saveToCloudThenRemoveLocal(notebooks);
    case LibraryHandoverAction.lockLocal:
      await service.lockLocal(notebooks, ownerUid: ownerUid);
  }
}

Future<void> signInAndLoadCloud(
  WidgetRef ref,
  Future<void> Function() signIn, {
  BuildContext? context,
}) async {
  final repo = ref.read(notebookRepositoryProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  final service = AccountLibraryService(repo, prefs);
  final previousUid = service.lastUid ?? ref.read(authProvider).user?.uid;

  await signIn();
  final uid = ref.read(authProvider).user?.uid;
  if (uid == null) return;

  if (previousUid == null || previousUid == uid) {
    await service.stampUnlocked(ownerUid: uid);
  } else if (context != null && context.mounted) {
    final notebooks = await repo.getNotebooks();
    final leftover = [
      ...service.plaintextForeign(notebooks, uid),
      for (final notebook in notebooks)
        if (!notebook.locked && notebook.ownerUid == null) notebook,
    ];
    if (leftover.isNotEmpty && context.mounted) {
      final action = await showAccountHandoverSheet(
        context,
        notebookCount: leftover.length,
        canSaveToCloud: false,
        canLock: false,
      );
      if (action != null) {
        await _applyHandover(
          service: service,
          action: action,
          notebooks: leftover,
          ownerUid: previousUid,
        );
      }
    }
  }

  await service.unlockOwned(uid);
  await service.rememberUid(uid);
  await loadCloudNotebooks(ref, replaceLocal: true);
  await service.stampUnlocked(ownerUid: uid);
  refreshLibraryLists(ref);
}

Future<void> signOutWithHandover(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(notebookRepositoryProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  final service = AccountLibraryService(repo, prefs);
  final uid = ref.read(authProvider).user?.uid;
  if (uid != null) {
    await service.stampUnlocked(ownerUid: uid);
    final mine = service.unsignedOrOwned(await repo.getNotebooks(), uid);
    if (mine.isNotEmpty && context.mounted) {
      final action = await showAccountHandoverSheet(
        context,
        notebookCount: mine.length,
        canSaveToCloud: true,
      );
      if (action == null) return;
      await _applyHandover(
        service: service,
        action: action,
        notebooks: mine,
        ownerUid: uid,
      );
    }
    AccountLibraryService.forgetVault(uid);
    await service.rememberUid(uid);
  }
  await ref.read(authProvider.notifier).signOut();
  refreshLibraryLists(ref);
}
