import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palettes.dart';

export 'palettes.dart' show AppLook, AppPalette, paletteFor;

/// Colours and text styles of the currently active look.
///
/// The root widget calls [use] before the rest of the tree builds, so screens
/// can read `AppTheme.ink` and friends without threading a palette through every
/// constructor.
class AppTheme {
  static AppPalette _current = paletteFor(AppLook.studio, Brightness.light);

  static AppPalette get palette => _current;

  static void use(AppPalette palette) => _current = palette;

  static Color get ink => _current.ink;
  static Color get inkMuted => _current.inkMuted;

  /// Screen background. Named `paper` for historical reasons.
  static Color get paper => _current.surface;

  /// Recessed fill: rows, wells, empty states.
  static Color get paperDeep => _current.surfaceAlt;

  /// Raised fill: cards, sheets, dialogs.
  static Color get card => _current.surfaceRaised;

  static Color get accent => _current.accent;
  static Color get accentSoft => _current.accentSoft;
  static Color get onAccent => _current.onAccent;
  static Color get danger => _current.danger;
  static Color get outline => _current.outline;
  static Color get toolbar => _current.chrome;
  static double get radius => _current.radius;
  static bool get isDark => _current.isDark;

  static TextStyle headline({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) => GoogleFonts.getFont(
    _current.headlineFont,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
  );

  static TextStyle body({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) => GoogleFonts.getFont(
    _current.bodyFont,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
  );

  static ThemeData themeFor(AppPalette palette) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.accent,
        onPrimary: palette.onAccent,
        primaryContainer: palette.accentSoft,
        onPrimaryContainer: palette.ink,
        secondary: palette.accent,
        onSecondary: palette.onAccent,
        surface: palette.surface,
        onSurface: palette.ink,
        surfaceContainerHighest: palette.surfaceAlt,
        outline: palette.outline,
        error: palette.danger,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: palette.surface,
    );

    final radius = BorderRadius.circular(palette.radius);
    final text = GoogleFonts.getTextTheme(palette.bodyFont, base.textTheme)
        .apply(bodyColor: palette.ink, displayColor: palette.ink)
        .copyWith(
          // Spelled out instead of going through [headline]: the theme is built
          // before the palette below is published.
          displayLarge: GoogleFonts.getFont(
            palette.headlineFont,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
          headlineMedium: GoogleFonts.getFont(
            palette.headlineFont,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
          titleLarge: GoogleFonts.getFont(
            palette.headlineFont,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.getFont(
          palette.headlineFont,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: palette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: palette.accent, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: palette.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
        titleTextStyle: GoogleFonts.getFont(
          palette.headlineFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(palette.radius + 6),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dividerTheme: DividerThemeData(color: palette.outline, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: palette.inkMuted,
        textColor: palette.ink,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.onAccent
              : palette.surfaceRaised,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.surfaceAlt,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.accent,
        inactiveTrackColor: palette.surfaceAlt,
        thumbColor: palette.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ink,
        contentTextStyle: GoogleFonts.getFont(
          palette.bodyFont,
          color: palette.surface,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        selectedColor: palette.accent,
        disabledColor: palette.surfaceAlt,
        labelStyle: GoogleFonts.getFont(
          palette.bodyFont,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: palette.ink,
        ),
        secondaryLabelStyle: GoogleFonts.getFont(
          palette.bodyFont,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: palette.onAccent,
        ),
        side: BorderSide(color: palette.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.radius + 6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.getFont(
              palette.bodyFont,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? palette.onAccent
                : palette.ink,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? palette.accent
                : palette.surfaceAlt,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: palette.outline)),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? palette.onAccent
                : palette.inkMuted,
          ),
        ),
      ),
    );
  }
}

const coverPalette = <int>[
  0xFF0F6E56,
  0xFF1D4E89,
  0xFF8B2942,
  0xFF9A5B13,
  0xFF3F3A71,
  0xFF2F5D50,
  0xFF6B4F3A,
  0xFF245B6B,
  0xFFB45309,
  0xFFBE123C,
  0xFF0369A1,
  0xFF15803D,
  0xFF7C3AED,
  0xFF0F766E,
  0xFF334155,
  0xFFEA580C,
  0xFF1E3A5F,
  0xFF4C1D95,
  0xFF831843,
  0xFF14532D,
  0xFF9F1239,
  0xFF155E75,
  0xFF713F12,
  0xFF1E293B,
  0xFFC2410C,
  0xFF6D28D9,
  0xFF0E7490,
  0xFFA16207,
  0xFF166534,
  0xFF9D174D,
  0xFF1D4ED8,
  0xFF44403C,
];

/// Folder icon keys stored on [LibraryFolder.iconKey].
IconData folderIconFor(String key) {
  switch (key) {
    case 'school':
      return Icons.school_rounded;
    case 'science':
      return Icons.science_rounded;
    case 'language':
      return Icons.translate_rounded;
    case 'math':
      return Icons.functions_rounded;
    case 'art':
      return Icons.palette_rounded;
    case 'music':
      return Icons.music_note_rounded;
    case 'sports':
      return Icons.sports_soccer_rounded;
    case 'work':
      return Icons.work_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'code':
      return Icons.code_rounded;
    case 'computer':
      return Icons.computer_rounded;
    case 'biology':
      return Icons.biotech_rounded;
    case 'geo':
      return Icons.public_rounded;
    case 'history':
      return Icons.history_edu_rounded;
    case 'psychology':
      return Icons.psychology_rounded;
    case 'chemistry':
      return Icons.bubble_chart_rounded;
    case 'physics':
      return Icons.bolt_rounded;
    case 'religion':
      return Icons.auto_awesome_rounded;
    case 'economy':
      return Icons.account_balance_rounded;
    case 'food':
      return Icons.restaurant_rounded;
    case 'travel':
      return Icons.flight_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'pets':
      return Icons.pets_rounded;
    case 'theater':
      return Icons.theater_comedy_rounded;
    case 'camera':
      return Icons.photo_camera_rounded;
    case 'heart':
      return Icons.favorite_rounded;
    case 'flag':
      return Icons.flag_rounded;
    default:
      return Icons.folder_rounded;
  }
}

const folderIconKeys = <String>[
  'folder',
  'school',
  'book',
  'language',
  'math',
  'science',
  'chemistry',
  'physics',
  'biology',
  'geo',
  'history',
  'psychology',
  'religion',
  'economy',
  'art',
  'music',
  'theater',
  'sports',
  'code',
  'computer',
  'camera',
  'work',
  'food',
  'travel',
  'home',
  'pets',
  'heart',
  'flag',
  'star',
];
