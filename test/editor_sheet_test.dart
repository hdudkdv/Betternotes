import 'package:betternotes/app/theme.dart';
import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:betternotes/features/editor/presentation/widgets/editor_more_sheet.dart';
import 'package:betternotes/features/editor/presentation/widgets/editor_top_bar.dart';
import 'package:betternotes/features/editor/presentation/widgets/share_export_sheet.dart';
import 'package:betternotes/features/library/providers/library_providers.dart';
import 'package:betternotes/l10n/app_localizations.dart';
import 'package:betternotes/shared/utils/page_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<EditorMenuAction>> _openMoreSheet(
  WidgetTester tester, {
  required CanvasMode canvasMode,
  Size window = const Size(420, 640),
}) async {
  final actions = <EditorMenuAction>[];
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.themeFor(paletteFor(AppLook.studio, Brightness.light)),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showEditorMoreSheet(
            context,
            template: PageTemplate.lined,
            browseMode: PageBrowseMode.swipeHorizontal,
            canvasMode: canvasMode,
            defaultPaperFormat: PaperFormat.a4,
            defaultOrientation: PageOrientation.portrait,
            onAction: actions.add,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return actions;
}

Future<void> _openShareSheet(
  WidgetTester tester, {
  required Size window,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.themeFor(paletteFor(AppLook.studio, Brightness.light)),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showShareExportSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('more sheet fits a short screen and scrolls', (tester) async {
    await _openMoreSheet(
      tester,
      canvasMode: CanvasMode.page,
      window: const Size(400, 560),
    );

    expect(tester.takeException(), isNull);

    // The last entry starts off screen and scrolls into view.
    final before = tester.getTopLeft(find.text('Einstellungen')).dy;
    expect(before, greaterThan(560));

    await tester.drag(find.text('Papier-Editor'), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Einstellungen')).dy, lessThan(560));
    expect(tester.takeException(), isNull);
  });

  testWidgets('page notebooks cannot be turned into infinite ones', (
    tester,
  ) async {
    await _openMoreSheet(tester, canvasMode: CanvasMode.page);

    expect(find.byType(Switch), findsNothing);
    expect(find.text('Dokumenttyp'), findsOneWidget);
    expect(find.text('Seitenmodus'), findsOneWidget);
  });

  testWidgets('infinite documents report their type and hide page browsing', (
    tester,
  ) async {
    await _openMoreSheet(tester, canvasMode: CanvasMode.infinite);

    expect(find.text('Unendliches Dokument'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Scrollrichtung'), findsNothing);
  });

  testWidgets('share sheet fits a flat screen and reaches the extras', (
    tester,
  ) async {
    await _openShareSheet(tester, window: const Size(1024, 648));

    expect(tester.takeException(), isNull);
    expect(find.text('Drucken / PDF-Vorschau'), findsOneWidget);

    await tester.drag(
      find.text('Drucken / PDF-Vorschau'),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Audio-Transkription')).dy,
      lessThan(648),
    );
    expect(tester.takeException(), isNull);
  });
}
