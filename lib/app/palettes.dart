import 'package:flutter/material.dart';

/// Visual identities the user can pick from. Only colours, radii and fonts
/// change — every feature stays where it is.
enum AppLook {
  /// Calm graphite surfaces with one indigo accent.
  studio,

  /// Warm cream paper with a deep green accent and serif headlines.
  paper,

  /// Bright white with a vivid accent and generous rounding.
  fresh,

  /// Almost monochrome; colour is reserved for the active tool.
  mono,
}

/// Semantic colours for one look in one brightness.
///
/// Screens never name a raw colour: they ask the palette, so switching the look
/// or the system brightness restyles everything at once.
class AppPalette {
  const AppPalette({
    required this.look,
    required this.brightness,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.danger,
    required this.outline,
    required this.workspace,
    required this.chrome,
    required this.chromeAlt,
    required this.chromeActive,
    required this.onChrome,
    required this.onChromeMuted,
    required this.floating,
    required this.radius,
    required this.headlineFont,
    required this.bodyFont,
  });

  final AppLook look;
  final Brightness brightness;

  /// Page background of every screen.
  final Color surface;

  /// Slightly recessed areas: list rows, fills, empty states.
  final Color surfaceAlt;

  /// Cards and sheets that sit above [surface].
  final Color surfaceRaised;

  final Color ink;
  final Color inkMuted;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color danger;
  final Color outline;

  /// Backdrop behind the notebook pages — a desk, not a dark void.
  final Color workspace;

  /// Thin editor rail.
  final Color chrome;

  /// Tool dock, one step apart from [chrome].
  final Color chromeAlt;

  /// Active tool / selection accent inside the editor chrome.
  final Color chromeActive;

  final Color onChrome;
  final Color onChromeMuted;

  /// Floating pills over the canvas.
  final Color floating;

  /// Corner rounding for cards and sheets.
  final double radius;

  final String headlineFont;
  final String bodyFont;

  bool get isDark => brightness == Brightness.dark;

  /// Identity of the resolved palette, used to force a restyle of the tree.
  String get id => '${look.name}_${brightness.name}';
}

const _studioLight = AppPalette(
  look: AppLook.studio,
  brightness: Brightness.light,
  surface: Color(0xFFF6F6F8),
  surfaceAlt: Color(0xFFECECF1),
  surfaceRaised: Color(0xFFFFFFFF),
  ink: Color(0xFF17171C),
  inkMuted: Color(0xFF5B5B69),
  accent: Color(0xFF5B4BE0),
  accentSoft: Color(0xFFE4E0FB),
  onAccent: Color(0xFFFFFFFF),
  danger: Color(0xFFC0362C),
  outline: Color(0xFFD8D8E0),
  workspace: Color(0xFFD4D4DC),
  chrome: Color(0xFFF6F6F8),
  chromeAlt: Color(0xFFEEEEF2),
  chromeActive: Color(0xFF5B4BE0),
  onChrome: Color(0xFF17171C),
  onChromeMuted: Color(0xFF5B5B69),
  floating: Color(0xFFFFFFFF),
  radius: 14,
  headlineFont: 'Plus Jakarta Sans',
  bodyFont: 'Inter',
);

const _studioDark = AppPalette(
  look: AppLook.studio,
  brightness: Brightness.dark,
  surface: Color(0xFF14141A),
  surfaceAlt: Color(0xFF1D1D25),
  surfaceRaised: Color(0xFF22222B),
  ink: Color(0xFFF1F1F5),
  inkMuted: Color(0xFF9E9EAE),
  accent: Color(0xFF8B7CFF),
  accentSoft: Color(0xFF2E2A4D),
  onAccent: Color(0xFF15121F),
  danger: Color(0xFFF07167),
  outline: Color(0xFF32323D),
  workspace: Color(0xFF0E0E12),
  chrome: Color(0xFF14141A),
  chromeAlt: Color(0xFF1D1D25),
  chromeActive: Color(0xFF8B7CFF),
  onChrome: Color(0xFFF1F1F5),
  onChromeMuted: Color(0xFF8E8E9E),
  floating: Color(0xFF22222B),
  radius: 14,
  headlineFont: 'Plus Jakarta Sans',
  bodyFont: 'Inter',
);

const _paperLight = AppPalette(
  look: AppLook.paper,
  brightness: Brightness.light,
  surface: Color(0xFFF7F2E8),
  surfaceAlt: Color(0xFFEDE6D8),
  surfaceRaised: Color(0xFFFFFCF5),
  ink: Color(0xFF1C1914),
  inkMuted: Color(0xFF4A453C),
  accent: Color(0xFF0F6E56),
  accentSoft: Color(0xFFD7E8E1),
  onAccent: Color(0xFFFFFFFF),
  danger: Color(0xFFB42318),
  outline: Color(0xFFDCD3C0),
  workspace: Color(0xFFE4D9C4),
  chrome: Color(0xFFF7F2E8),
  chromeAlt: Color(0xFFEDE6D8),
  chromeActive: Color(0xFF0F6E56),
  onChrome: Color(0xFF1C1914),
  onChromeMuted: Color(0xFF4A453C),
  floating: Color(0xFFFFFCF5),
  radius: 16,
  headlineFont: 'Fraunces',
  bodyFont: 'Source Sans 3',
);

const _paperDark = AppPalette(
  look: AppLook.paper,
  brightness: Brightness.dark,
  surface: Color(0xFF1D1A15),
  surfaceAlt: Color(0xFF262218),
  surfaceRaised: Color(0xFF2C2720),
  ink: Color(0xFFF2EADA),
  inkMuted: Color(0xFFB6AB95),
  accent: Color(0xFF56BFA0),
  accentSoft: Color(0xFF25382F),
  onAccent: Color(0xFF10201A),
  danger: Color(0xFFE8836F),
  outline: Color(0xFF3B3428),
  workspace: Color(0xFF120F0B),
  chrome: Color(0xFF1D1A15),
  chromeAlt: Color(0xFF262218),
  chromeActive: Color(0xFF56BFA0),
  onChrome: Color(0xFFF2EADA),
  onChromeMuted: Color(0xFFA79B85),
  floating: Color(0xFF2C2720),
  radius: 16,
  headlineFont: 'Fraunces',
  bodyFont: 'Source Sans 3',
);

const _freshLight = AppPalette(
  look: AppLook.fresh,
  brightness: Brightness.light,
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF1F5F7),
  surfaceRaised: Color(0xFFFFFFFF),
  ink: Color(0xFF10262C),
  inkMuted: Color(0xFF56737B),
  accent: Color(0xFF00A6A0),
  accentSoft: Color(0xFFD3F1EF),
  onAccent: Color(0xFFFFFFFF),
  danger: Color(0xFFE5484D),
  outline: Color(0xFFD9E4E7),
  workspace: Color(0xFFD5E3E6),
  chrome: Color(0xFFFFFFFF),
  chromeAlt: Color(0xFFF1F5F7),
  chromeActive: Color(0xFF00A6A0),
  onChrome: Color(0xFF10262C),
  onChromeMuted: Color(0xFF56737B),
  floating: Color(0xFFFFFFFF),
  radius: 22,
  headlineFont: 'Outfit',
  bodyFont: 'Inter',
);

const _freshDark = AppPalette(
  look: AppLook.fresh,
  brightness: Brightness.dark,
  surface: Color(0xFF0B1A1D),
  surfaceAlt: Color(0xFF122528),
  surfaceRaised: Color(0xFF162E31),
  ink: Color(0xFFEAF6F5),
  inkMuted: Color(0xFF93B0B0),
  accent: Color(0xFF2AD8CE),
  accentSoft: Color(0xFF10393A),
  onAccent: Color(0xFF04211F),
  danger: Color(0xFFFF7B7F),
  outline: Color(0xFF234446),
  workspace: Color(0xFF061114),
  chrome: Color(0xFF0B1A1D),
  chromeAlt: Color(0xFF122528),
  chromeActive: Color(0xFF2AD8CE),
  onChrome: Color(0xFFEAF6F5),
  onChromeMuted: Color(0xFF93B0B0),
  floating: Color(0xFF162E31),
  radius: 22,
  headlineFont: 'Outfit',
  bodyFont: 'Inter',
);

const _monoLight = AppPalette(
  look: AppLook.mono,
  brightness: Brightness.light,
  surface: Color(0xFFFAFAFA),
  surfaceAlt: Color(0xFFF0F0F0),
  surfaceRaised: Color(0xFFFFFFFF),
  ink: Color(0xFF111111),
  inkMuted: Color(0xFF5E5E5E),
  accent: Color(0xFF111111),
  accentSoft: Color(0xFFE2E2E2),
  onAccent: Color(0xFFFFFFFF),
  danger: Color(0xFF8C1D18),
  outline: Color(0xFFD4D4D4),
  workspace: Color(0xFFE6E6E6),
  chrome: Color(0xFFFAFAFA),
  chromeAlt: Color(0xFFF0F0F0),
  chromeActive: Color(0xFF111111),
  onChrome: Color(0xFF111111),
  onChromeMuted: Color(0xFF5E5E5E),
  floating: Color(0xFFFFFFFF),
  radius: 8,
  headlineFont: 'Space Grotesk',
  bodyFont: 'Inter',
);

const _monoDark = AppPalette(
  look: AppLook.mono,
  brightness: Brightness.dark,
  surface: Color(0xFF101010),
  surfaceAlt: Color(0xFF191919),
  surfaceRaised: Color(0xFF1F1F1F),
  ink: Color(0xFFF2F2F2),
  inkMuted: Color(0xFFA0A0A0),
  accent: Color(0xFFF2F2F2),
  accentSoft: Color(0xFF2A2A2A),
  onAccent: Color(0xFF101010),
  danger: Color(0xFFEB8A82),
  outline: Color(0xFF2E2E2E),
  workspace: Color(0xFF070707),
  chrome: Color(0xFF101010),
  chromeAlt: Color(0xFF191919),
  chromeActive: Color(0xFFFFFFFF),
  onChrome: Color(0xFFF2F2F2),
  onChromeMuted: Color(0xFFA0A0A0),
  floating: Color(0xFF1F1F1F),
  radius: 8,
  headlineFont: 'Space Grotesk',
  bodyFont: 'Inter',
);

AppPalette paletteFor(AppLook look, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (look) {
    AppLook.studio => dark ? _studioDark : _studioLight,
    AppLook.paper => dark ? _paperDark : _paperLight,
    AppLook.fresh => dark ? _freshDark : _freshLight,
    AppLook.mono => dark ? _monoDark : _monoLight,
  };
}
