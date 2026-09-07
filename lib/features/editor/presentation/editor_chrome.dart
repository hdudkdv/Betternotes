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

  /// Slightly deeper desk tone for a vignette around the paper.
  static Color get workspaceDeep => Color.lerp(
    workspace,
    _p.isDark ? const Color(0xFF000000) : const Color(0xFF3A3632),
    _p.isDark ? 0.22 : 0.10,
  )!;

  /// Hairline around the paper — warmer than the chrome divider.
  static Color get pageEdge => _p.isDark
      ? Colors.white.withValues(alpha: 0.06)
      : const Color(0x33000000);

  /// Floating tools (options, undo, page badge) — raised desk objects, not pills.
  static Color get floating => _p.floating;
  static Color get floatingBorder => _p.outline.withValues(alpha: 0.72);

  /// Selection accent used for the active tool and options.
  static Color get selected => _p.chromeActive;
  static Color get selectedSoft => _p.chromeActive.withValues(alpha: 0.16);

  /// Subtle fill for pressed or active chrome buttons.
  static Color get chip => _p.accentSoft;

  static Color get onDark => _p.onChrome;
  static Color get onDarkMuted => _p.onChromeMuted;
  static Color get divider => _p.outline;

  static const tabRowHeight = 48.0;
  static const toolRowHeight = 54.0;
  static const dockWidth = 58.0;
  static const pillRadius = 14.0;
  static const dockBreakpoint = 720.0;

  static List<BoxShadow> get pillShadow {
    final dark = _p.isDark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.42 : 0.10),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.22 : 0.04),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];
  }

  /// Soft lift under the notebook page — the paper sits on a desk.
  static List<BoxShadow> get pageShadow {
    final dark = _p.isDark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.55 : 0.14),
        blurRadius: 36,
        offset: const Offset(0, 18),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.28 : 0.06),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> get barShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: _p.isDark ? 0.35 : 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  /// Legacy aliases kept so older call sites keep compiling.
  static Color get toolbar => floating;
  static Color get toolbarSelected => selected;
  static Color get topBarActive => tabActive;
}

/// Soft vignette behind the pages so the paper reads as an object on a desk.
class WorkspaceBackdrop extends StatelessWidget {
  const WorkspaceBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.08),
          radius: 1.15,
          colors: [EditorChrome.workspace, EditorChrome.workspaceDeep],
        ),
      ),
    );
  }
}
