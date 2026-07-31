import 'package:betternotes/app/theme.dart';
import 'package:betternotes/l10n/app_localizations.dart';
import 'package:betternotes/shared/widgets/color_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// What the sheet handed back to its caller.
class _Result {
  int? value;
  var closed = false;
}

Future<_Result> _openPicker(
  WidgetTester tester, {
  required int initialValue,
  bool allowOpacity = true,
}) async {
  final result = _Result();
  // The sheet is taller than the default 800x600 test window.
  tester.view.physicalSize = const Size(900, 1500);
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
          onPressed: () async {
            result.value = await showColorPickerSheet(
              context,
              initialValue: initialValue,
              allowOpacity: allowOpacity,
            );
            result.closed = true;
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

/// The saturation/value square, found by the height it lays itself out at.
Finder get _square =>
    find.byWidgetPredicate((w) => w is SizedBox && w.height == 172);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('opens on the colour it was given', (tester) async {
    await _openPicker(tester, initialValue: 0xFF1D4E89);

    expect(find.text('1D4E89'), findsOneWidget);
    expect(find.text('Farbton'), findsOneWidget);
    expect(find.text('Deckkraft'), findsOneWidget);
  });

  testWidgets('hides opacity when the caller does not allow it', (
    tester,
  ) async {
    await _openPicker(tester, initialValue: 0xFF1D4E89, allowOpacity: false);

    expect(find.text('Deckkraft'), findsNothing);
  });

  testWidgets('a typed hex value is what gets applied', (tester) async {
    final result = await _openPicker(tester, initialValue: 0xFF1D4E89);

    await tester.enterText(find.byType(TextField), '00FF00');
    await tester.pump();
    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();

    expect(result.value, 0xFF00FF00);
  });

  testWidgets('dragging the square to the top left picks white', (
    tester,
  ) async {
    final result = await _openPicker(tester, initialValue: 0xFF1D4E89);

    final square = tester.getRect(_square.first);
    await tester.dragFrom(square.center, square.topLeft - square.center);
    await tester.pumpAndSettle();
    expect(find.text('FFFFFF'), findsOneWidget);

    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();

    expect(result.value, 0xFFFFFFFF);
  });

  testWidgets('cancelling reports no colour at all', (tester) async {
    final result = await _openPicker(tester, initialValue: 0xFF1D4E89);

    await tester.enterText(find.byType(TextField), 'FF0000');
    await tester.pump();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    expect(result.value, isNull);
  });

  testWidgets('the opacity slider carries into the applied colour', (
    tester,
  ) async {
    final result = await _openPicker(tester, initialValue: 0xFF1D4E89);

    // Hue comes first, opacity second.
    final track = tester.getRect(
      find.byWidgetPredicate((w) => w is SizedBox && w.height == 30).at(1),
    );
    await tester.tapAt(Offset(track.left + track.width * 0.25, track.center.dy));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();

    expect(result.value, isNotNull);
    expect(Color(result.value!).a, lessThan(1.0));
  });
}
