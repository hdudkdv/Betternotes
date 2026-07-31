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

  /// Floating pills (tool options, undo, page badge).
  static Color get floating => _p.floating;
  static Color get floatingBorder => _p.onChrome.withValues(alpha: 0.12);

  /// Selection accent used for the active tool and options.
  static Color get selected => _p.chromeActive;
  static Color get selectedSoft => _p.chromeActive.withValues(alpha: 0.22);

  /// Subtle fill for pressed or active chrome buttons.
  static Color get chip => _p.onChrome.withValues(alpha: 0.10);

  static Color get onDark => _p.onChrome;
  static Color get onDarkMuted => _p.onChromeMuted;
  static Color get divider => _p.onChrome.withValues(alpha: 0.14);

  static const tabRowHeight = 40.0;
  static const toolRowHeight = 54.0;
  static const pillRadius = 22.0;

  static List<BoxShadow> get pillShadow => const [
    BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Legacy aliases kept so older call sites keep compiling.
  static Color get toolbar => floating;
  static Color get toolbarSelected => selected;
  static Color get topBarActive => tabActive;
}
