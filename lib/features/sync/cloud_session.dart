import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entitlements/entitlement_model.dart';
import '../library/providers/library_providers.dart';
import '../planner/planner_model.dart';
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
  refreshLibraryLists(ref);
}

Future<void> signInAndLoadCloud(
  WidgetRef ref,
  Future<void> Function() signIn,
) async {
  await signIn();
  await loadCloudNotebooks(ref, replaceLocal: true);
}
