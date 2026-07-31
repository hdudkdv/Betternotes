import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/local/local_database.dart';
import 'features/entitlements/rewarded_ad_service.dart';
import 'features/library/providers/library_providers.dart';
import 'features/sync/firebase_bootstrap.dart';
import 'startup_error_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show UI immediately so startup failures are visible instead of a white crash.
  runApp(const _BootApp());
}

class _BootApp extends StatefulWidget {
  const _BootApp();

  @override
  State<_BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<_BootApp> {
  String _step = 'Starte…';
  Object? _error;
  StackTrace? _stack;
  String? _previousCrash;
  Widget? _readyApp;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _boot() async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        StartupErrorLog.write(
          'FlutterError: ${details.exceptionAsString()}\n${details.stack}',
        ),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(StartupErrorLog.write('PlatformError: $error\n$stack'));
      if (mounted) {
        setState(() {
          _error = error;
          _stack = stack;
        });
      }
      return true;
    };

    final previous = await StartupErrorLog.read();
    if (previous != null && mounted) {
      setState(() => _previousCrash = previous);
    }

    try {
      setState(() => _step = 'Firebase wird initialisiert…');
      final firebase = await FirebaseBootstrap.initialize();
      await StartupErrorLog.breadcrumb(
        'firebase ok (available=${firebase.available}'
        '${firebase.error == null ? '' : ', error=${firebase.error}'})',
      );

      setState(() => _step = 'Lokale Datenbank wird geöffnet…');
      await LocalDatabase.init();
      await StartupErrorLog.breadcrumb('database ok');

      setState(() => _step = 'Einstellungen werden geladen…');
      final prefs = await SharedPreferences.getInstance();
      await StartupErrorLog.breadcrumb('prefs ok');

      // Non-fatal; ads are Android-only in this app.
      unawaited(RewardedAdService.instance.initialize());

      await StartupErrorLog.clear();
      if (!mounted) return;
      setState(() {
        _readyApp = ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            settingsProvider.overrideWith((ref) => SettingsNotifier(prefs)),
            firebaseBootstrapProvider.overrideWithValue(firebase),
          ],
          child: const BetterNotesApp(),
        );
      });
    } catch (error, stack) {
      debugPrint('Startup failed: $error\n$stack');
      await StartupErrorLog.write('Startup failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _error = error;
        _stack = stack;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_readyApp != null) return _readyApp!;

    final message = _error?.toString();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F4EF),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: message == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(_step, textAlign: TextAlign.center),
                            if (_previousCrash != null) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Letzter Absturz / Fehler:',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                _previousCrash!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'BetterNotes konnte nicht starten',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SelectableText(
                              message,
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (_stack != null) ...[
                              const SizedBox(height: 12),
                              SelectableText(
                                '$_stack',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
