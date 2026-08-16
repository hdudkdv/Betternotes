import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';

import '../features/auth/auth_repository.dart';
import '../features/auth/web_login_screen.dart';
import '../features/billing/revenuecat_billing.dart';
import '../features/editor/presentation/editor_screen.dart';
import '../features/entitlements/entitlement_model.dart';
import '../features/collaboration/collaboration_screen.dart';
import '../features/lan_sync/nearby_sync_screen.dart';
import '../features/flashcards/flashcard_deck_screen.dart';
import '../features/import_export/import_export_providers.dart';
import '../features/import_export/import_notebook_picker_screen.dart';
import '../features/legal/legal_document_screen.dart';
import '../features/lan_sync/classroom_auto_connect.dart';
import '../features/lan_sync/lan_sync_controller.dart';
import '../features/lan_sync/lan_sync_protocol.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/marketplace/marketplace_screen.dart';
import '../features/library/providers/library_providers.dart';
import '../features/onboarding/profile_setup_screen.dart';
import '../features/onboarding/role_onboarding_screen.dart';
import '../features/search/global_search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/sync/cloud_session.dart';
import '../features/planner/planner_screen.dart';
import '../features/teacher/catalog/assignment_page.dart';
import '../features/teacher/catalog/assignment_results_page.dart';
import '../features/teacher/catalog/assignment_session.dart';
import '../features/teacher/teacher_audio_screen.dart';
import '../features/teacher/teacher_screen.dart';
import '../features/timetable/timetable_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Keeps [GoRouter] alive; role changes only refresh redirects.
class _RouterRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen<(AppUserRole?, bool)>(
    settingsProvider.select(
      (settings) => (settings.userRole, settings.profileSetupCompleted),
    ),
    (_, _) => refresh.bump(),
  );
  ref.listen<bool>(
    authProvider.select((auth) => auth.signedIn),
    (_, _) => refresh.bump(),
  );
  ref.onDispose(refresh.dispose);

  final initial = ref.read(settingsProvider);
  final signedIn = ref.read(authProvider).signedIn;
  return GoRouter(
    initialLocation: kIsWeb && !signedIn
        ? '/login'
        : initial.userRole == null
        ? '/welcome'
        : (initial.profileSetupCompleted ? '/' : '/setup'),
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      final role = settings.userRole;
      final loc = state.matchedLocation;
      final onWelcome = loc == '/welcome';
      final onSetup = loc == '/setup';
      final onLogin = loc == '/login';
      final onLegal = loc.startsWith('/legal');
      if (kIsWeb && !ref.read(authProvider).signedIn) {
        if (onLogin || onLegal) return null;
        return '/login';
      }
      if (onLogin) {
        if (role == null) return '/welcome';
        if (!settings.profileSetupCompleted) return '/setup';
        return '/';
      }
      if (role == null && !onWelcome) return '/welcome';
      if (role != null && !settings.profileSetupCompleted && !onSetup) {
        return '/setup';
      }
      if (settings.profileSetupCompleted && (onWelcome || onSetup)) {
        return '/';
      }
      if (loc.startsWith('/teacher') && role != AppUserRole.teacher) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const WebLoginScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const RoleOnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/notebook/:id',
        name: 'editor',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditorScreen(
            notebookId: id,
            initialPageId: state.uri.queryParameters['pageId'],
            initialOutlineId: state.uri.queryParameters['outlineId'],
          );
        },
      ),
      GoRoute(
        path: '/collaboration/:id',
        name: 'collaboration',
        builder: (context, state) =>
            CollaborationScreen(notebookId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/nearby-sync/:id',
        name: 'nearbySync',
        builder: (context, state) =>
            NearbySyncScreen(notebookId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/flashcards/:id',
        name: 'flashcards',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FlashcardDeckScreen(deckId: id);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/marketplace',
        name: 'marketplace',
        builder: (context, state) => const MarketplaceScreen(),
      ),
      GoRoute(
        path: '/import',
        name: 'import',
        builder: (context, state) => const ImportNotebookPickerScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        name: 'legalPrivacy',
        builder: (context, state) =>
            const LegalDocumentScreen(kind: LegalDocKind.privacy),
      ),
      GoRoute(
        path: '/legal/terms',
        name: 'legalTerms',
        builder: (context, state) =>
            const LegalDocumentScreen(kind: LegalDocKind.terms),
      ),
      GoRoute(
        path: '/legal/impressum',
        name: 'legalImpressum',
        builder: (context, state) =>
            const LegalDocumentScreen(kind: LegalDocKind.impressum),
      ),
      GoRoute(
        path: '/timetable',
        name: 'timetable',
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: '/grades',
        name: 'grades',
        builder: (context, state) => const GradesScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/planner',
        name: 'planner',
        builder: (context, state) => const GradesScreen(),
      ),
      GoRoute(
        path: '/teacher',
        name: 'teacher',
        builder: (context, state) => const TeacherScreen(),
      ),
      GoRoute(
        path: '/teacher/audio',
        name: 'teacherAudio',
        builder: (context, state) => const TeacherAudioScreen(),
      ),
      GoRoute(
        path: '/teacher/assignment/:runId',
        name: 'teacherAssignmentResults',
        builder: (context, state) => AssignmentResultsPage(
          runId: state.pathParameters['runId']!,
        ),
      ),
      GoRoute(
        path: '/assignment/:runId',
        name: 'assignment',
        builder: (context, state) => AssignmentPage(
          runId: state.pathParameters['runId']!,
        ),
      ),
    ],
  );
});

class BetterNotesApp extends ConsumerStatefulWidget {
  const BetterNotesApp({super.key});

  @override
  ConsumerState<BetterNotesApp> createState() => _BetterNotesAppState();
}

class _BetterNotesAppState extends ConsumerState<BetterNotesApp> {
  StreamSubscription? _shareSub;
  VoidCallback? _lanListener;
  bool _lanListenerAttached = false;
  bool _autoBrowsing = false;
  bool _autoConnecting = false;
  int _handledLanEventSeq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      unawaited(() async {
        try {
          await ref.read(revenueCatBillingProvider).initialize(
            appUserId: ref.read(authProvider).user?.uid,
          );
          final billing = ref.read(revenueCatBillingProvider);
          if (billing.configured) {
            await ref.read(entitlementProvider.notifier).setTier(billing.tier);
          }
        } catch (error, stack) {
          debugPrint('RevenueCat init skipped: $error\n$stack');
        }
      }());
      final intake = ref.read(shareIntakeProvider);
      await intake.start();
      _shareSub = intake.pending.listen((files) {
        if (files.isEmpty) return;
        ref.read(appRouterProvider).go('/import');
      });
      if (intake.peekPending != null && intake.peekPending!.isNotEmpty) {
        ref.read(appRouterProvider).go('/import');
      }
      await _startClassroomAutoConnect();
      if (kIsWeb && ref.read(authProvider).signedIn) {
        unawaited(loadCloudNotebooks(ref, replaceLocal: true));
      }
    });
  }

  Future<void> _startClassroomAutoConnect() async {
    final settings = ref.read(settingsProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    if (settings.userRole != AppUserRole.student ||
        !ClassroomAutoConnect.isEnabled(prefs)) {
      return;
    }
    final lan = ref.read(lanSyncProvider);
    if (lan.isActive || _autoBrowsing) return;
    _lanListener ??= () {
      final controller = ref.read(lanSyncProvider);
      final event = controller.lastEvent;
      if (event != null && controller.eventSeq != _handledLanEventSeq) {
        _handledLanEventSeq = controller.eventSeq;
        if (event.kind == LanSyncEventKind.snapshotApplied &&
            event.notebookId != null) {
          _autoBrowsing = false;
          _autoConnecting = false;
          ref.read(appRouterProvider).go('/notebook/${event.notebookId}');
          return;
        }
      }
      if (!_autoBrowsing || _autoConnecting || controller.isActive) return;
      final match = controller.discoveredHosts
          .where(
            (host) => ClassroomAutoConnect.hasMatchingCriteria(
              prefs,
              subject: host.classroomSubject,
              room: host.classroomRoom,
            ),
          )
          .firstOrNull;
      if (match == null) return;
      _autoConnecting = true;
      final expectedSubject = prefs.getString(ClassroomAutoConnect.subjectKey);
      final expectedRoom = prefs.getString(ClassroomAutoConnect.roomKey);
      unawaited(() async {
        await controller.stopBrowsing();
        _autoBrowsing = false;
        await controller.joinDiscovered(
          match,
          displayName: 'Schüler',
          autoReconnect: true,
          expectedSubject: expectedSubject,
          expectedRoom: expectedRoom,
        );
      }());
    };
    if (!_lanListenerAttached) {
      lan.addListener(_lanListener!);
      _lanListenerAttached = true;
    }
    _autoBrowsing = true;
    await lan.startBrowsing();
  }

  @override
  void dispose() {
    unawaited(_shareSub?.cancel() ?? Future.value());
    final listener = _lanListener;
    if (listener != null) {
      ref.read(lanSyncProvider).removeListener(listener);
      _lanListenerAttached = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);
    final autoConnectEnabled = ref.watch(
      classroomAutoConnectEnabledProvider,
    );
    if (settings.userRole == AppUserRole.student &&
        autoConnectEnabled &&
        !_autoBrowsing &&
        !_autoConnecting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_startClassroomAutoConnect());
      });
    } else if (!autoConnectEnabled && _autoBrowsing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _autoBrowsing = false;
        unawaited(ref.read(lanSyncProvider).stopBrowsing());
      });
    }
    ref.listen<String?>(
      authProvider.select((auth) => auth.user?.uid),
      (previous, next) {
        if (previous == next) return;
        unawaited(ref.read(revenueCatBillingProvider).syncAppUser(next));
      },
    );
    ref.listen<AppTier>(
      revenueCatBillingProvider.select((billing) => billing.tier),
      (previous, next) {
        if (!ref.read(revenueCatBillingProvider).configured) return;
        unawaited(ref.read(entitlementProvider.notifier).setTier(next));
      },
    );
    ref.listen<int>(
      lanSyncProvider.select((controller) => controller.assignmentEventSeq),
      (previous, next) {
        final event = ref.read(lanSyncProvider).lastAssignmentEvent;
        if (event == null) return;
        ref.read(studentAssignmentProvider.notifier).onLanEvent(event);
        ref.read(assignmentHostProvider.notifier).onLanEvent(event);
        if (event.type == 'assignment_start' &&
            ref.read(lanSyncProvider).role == LanSyncRole.guest) {
          final runId = event.payload['runId']?.toString();
          if (runId != null && runId.isNotEmpty) {
            ref.read(appRouterProvider).go('/assignment/$runId');
          }
        }
      },
    );
    return MaterialApp.router(
      title: 'Notis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(paletteFor(settings.look, Brightness.light)),
      darkTheme: AppTheme.themeFor(paletteFor(settings.look, Brightness.dark)),
      themeMode: settings.themeMode,
      builder: (context, child) {
        AppTheme.use(paletteFor(settings.look, Theme.of(context).brightness));
        return child!;
      },
      routerConfig: router,
      locale: settings.localeOverride,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
