import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Chrome colors and metrics shared by the notebook editor surfaces.
///
/// Every colour comes from the active look, so the editor follows the palette
/// the user picked in the settings.
abstract final class EditorChrome {
  static AppPalette get _p => AppTheme.palette;

  /// Tab strip at the very top of the editor.
  static Color get topBar => _p.chrome;

  /// Icon row directly below the tab strip.
  static Color get toolBar => _p.chromeAlt;

  /// Active document tab.
  static Color get tabActive => _p.chromeAlt;

  /// Page thumbnail rail next to the canvas.
  static Color get sidebar => _p.chromeAlt;

  /// Background behind the pages.
  static Color get workspace => _p.workspace;

  /// Floating tools (options, undo, page badge) — raised desk objects, not pills.
  static Color get floating => _p.floating;
  static Color get floatingBorder => _p.outline;

  /// Selection accent used for the active tool and options.
  static Color get selected => _p.chromeActive;
  static Color get selectedSoft => _p.chromeActive.withValues(alpha: 0.16);

  /// Subtle fill for pressed or active chrome buttons.
  static Color get chip => _p.accentSoft;

  static Color get onDark => _p.onChrome;
  static Color get onDarkMuted => _p.onChromeMuted;
  static Color get divider => _p.outline;

  static const tabRowHeight = 44.0;
  static const toolRowHeight = 52.0;
  static const dockWidth = 56.0;
  static const pillRadius = 12.0;
  static const dockBreakpoint = 720.0;

  static List<BoxShadow> get pillShadow => const [];

  /// Legacy aliases kept so older call sites keep compiling.
  static Color get toolbar => floating;
  static Color get toolbarSelected => selected;
  static Color get topBarActive => tabActive;
}
