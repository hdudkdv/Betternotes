import 'package:betternotes/app/theme.dart';
import 'package:betternotes/features/editor/presentation/editor_chrome.dart';
import 'package:betternotes/features/library/providers/library_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Google Fonts reaches for the asset bundle while building the text theme.
  TestWidgetsFlutterBinding.ensureInitialized();
  // Unknown family names still throw; only the download is switched off.
  GoogleFonts.config.allowRuntimeFetching = false;

  test('every look resolves in both brightnesses', () {
    for (final look in AppLook.values) {
      for (final brightness in Brightness.values) {
        final palette = paletteFor(look, brightness);
        expect(palette.look, look);
        expect(palette.brightness, brightness);
        expect(palette.isDark, brightness == Brightness.dark);
        // Text has to stay readable on its own background.
        expect(palette.ink, isNot(palette.surface));
        expect(palette.onChrome, isNot(palette.chrome));
        // A family Google Fonts does not know would throw on first paint.
        final families = GoogleFonts.asMap();
        expect(
          families.keys,
          containsAll([palette.headlineFont, palette.bodyFont]),
          reason: palette.id,
        );
      }
    }
  });

  test('dark palettes are darker than their light twin', () {
    for (final look in AppLook.values) {
      final light = paletteFor(look, Brightness.light);
      final dark = paletteFor(look, Brightness.dark);
      expect(
        dark.surface.computeLuminance(),
        lessThan(light.surface.computeLuminance()),
        reason: look.name,
      );
    }
  });

  test('studio light chrome recedes; workspace is a desk', () {
    final studio = paletteFor(AppLook.studio, Brightness.light);
    expect(studio.chrome.computeLuminance(), greaterThan(0.7));
    expect(studio.workspace.computeLuminance(), greaterThan(0.5));
    expect(studio.onChrome.computeLuminance(), lessThan(0.2));
    expect(studio.look, AppLook.studio);
  });

  test('activating a look moves the app and editor tokens with it', () {
    AppTheme.use(paletteFor(AppLook.paper, Brightness.light));
    final paperSurface = AppTheme.paper;
    final paperChrome = EditorChrome.topBar;

    AppTheme.use(paletteFor(AppLook.fresh, Brightness.dark));
    expect(AppTheme.paper, isNot(paperSurface));
    expect(EditorChrome.topBar, isNot(paperChrome));
    expect(AppTheme.paper, paletteFor(AppLook.fresh, Brightness.dark).surface);
    expect(
      EditorChrome.workspace,
      paletteFor(AppLook.fresh, Brightness.dark).workspace,
    );

    AppTheme.use(paletteFor(AppLook.studio, Brightness.light));
  });

  test('the picked look and theme mode survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final notifier = SettingsNotifier(prefs);
    await notifier.setLook(AppLook.mono);
    await notifier.setThemeMode(ThemeMode.dark);

    final restarted = SettingsNotifier(prefs);
    expect(restarted.state.look, AppLook.mono);
    expect(restarted.state.themeMode, ThemeMode.dark);
  });
}
