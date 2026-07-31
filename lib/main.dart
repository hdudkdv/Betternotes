import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/local/local_database.dart';
import 'features/entitlements/rewarded_ad_service.dart';
import 'features/library/providers/library_providers.dart';
import 'features/sync/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebase = await FirebaseBootstrap.initialize();
  await LocalDatabase.init();
  final prefs = await SharedPreferences.getInstance();
  // Warms up the first rewarded ad; no-op where AdMob is unavailable.
  unawaited(RewardedAdService.instance.initialize());
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        settingsProvider.overrideWith((ref) => SettingsNotifier(prefs)),
        firebaseBootstrapProvider.overrideWithValue(firebase),
      ],
      child: const BetterNotesApp(),
    ),
  );
}
