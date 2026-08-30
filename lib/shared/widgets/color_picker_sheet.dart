import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// Ready-made ink colours offered above the free picker.
const kColorPresets = <int>[
  0xFF1A1A1A,
  0xFF5B5B69,
  0xFFB0B0BC,
  0xFFFFFFFF,
  0xFF1D4E89,
  0xFF0A84FF,
  0xFF35C2F5,
  0xFF0F766E,
  0xFF157347,
  0xFF7CC334,
  0xFFD4A017,
  0xFFF08C00,
  0xFFE5484D,
  0xFFB42318,
  0xFFD6336C,
  0xFF7C3AED,
  0xFF5B4BE0,
  0xFF8B5E3C,
];

/// Dense hue × brightness raster for one-tap colour picks.
final kColorGrid = <int>[
  for (final value in const [0.12, 0.28, 0.45, 0.62, 0.78, 0.92, 1.0])
    HSVColor.fromAHSV(1, 0, 0, value).toColor().toARGB32(),
  for (final value in const [0.35, 0.55, 0.75, 0.95])
    for (final hue in const [
      0.0,
      20.0,
      40.0,
      60.0,
      90.0,
      140.0,
      180.0,
      200.0,
      230.0,
      260.0,
      290.0,
      330.0,
    ])
      HSVColor.fromAHSV(1, hue, 0.85, value).toColor().toARGB32(),
];

/// Opens the colour picker and resolves to the chosen ARGB value.
///
/// Returns `null` when the sheet is dismissed without applying. Pass [onDelete]
/// to offer removing the colour that is being edited.
Future<int?> showColorPickerSheet(
  BuildContext context, {
  required int initialValue,
  String? title,
  bool allowOpacity = true,
  List<int> recents = const [],
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ColorPickerSheet(
      initialValue: initialValue,
      title: title,
      allowOpacity: allowOpacity,
      recents: recents,
      onDelete: onDelete,
    ),
  );
}

class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet({
    required this.initialValue,
    required this.title,
    required this.allowOpacity,
    required this.recents,
    required this.onDelete,
  });

  final int initialValue;
  final String? title;
  final bool allowOpacity;
  final List<int> recents;
  final VoidCallback? onDelete;

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSVColor _hsv;
  late final TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(Color(widget.initialValue));
    if (!widget.allowOpacity) _hsv = _hsv.withAlpha(1);
    _hex = TextEditingController(text: _hexOf(_color));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  Color get _color => _hsv.toColor();

  String _hexOf(Color color) =>
      color.toARGB32().toRadixString(16).substring(2).toUpperCase();

  /// HSV is kept as the source of truth: black and greys have no hue of their
  /// own, so round-tripping through [Color] would jump the hue back to red.
  void _set(HSVColor value, {bool syncHex = true}) {
    setState(() {
      _hsv = value;
      if (syncHex) _hex.text = _hexOf(_color);
    });
  }

  void _applyHex(String raw) {
    final cleaned = raw.replaceAll(RegExp('[^0-9a-fA-F]'), '');
    if (cleaned.length != 6) return;
    final rgb = int.parse(cleaned, radix: 16);
    final next = HSVColor.fromColor(Color(0xFF000000 | rgb));
    _set(next.withAlpha(_hsv.alpha), syncHex: false);
  }

  void _pickPreset(int value) {
    final next = HSVColor.fromColor(Color(value));
    _set(next.withAlpha(_hsv.alpha));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppTheme.palette;
    final recents = widget.recents
        .where((value) => !kColorPresets.contains(value))
        .take(6)
        .toList();

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: BorderRadius.circular(palette.radius + 8),
          border: Border.all(color: palette.outline),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title ?? l10n.colorPickerTitle,
                      style: AppTheme.headline(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  _Preview(color: _color),
                ],
              ),
              const SizedBox(height: 14),
              _SectionLabel(l10n.colorGrid),
              _ColorGrid(
                values: kColorGrid,
                selected: _color.toARGB32(),
                onPick: _pickPreset,
              ),
              const SizedBox(height: 14),
              _SaturationValueField(
                hsv: _hsv,
                onChanged: (value) => _set(value),
              ),
              const SizedBox(height: 14),
              _GradientSlider(
                label: l10n.hue,
                value: _hsv.hue / 360,
                thumbColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
                onChanged: (t) => _set(_hsv.withHue(t * 360)),
              ),
              if (widget.allowOpacity) ...[
                const SizedBox(height: 12),
                _GradientSlider(
                  label: l10n.opacity,
                  value: _hsv.alpha,
                  thumbColor: _color,
                  checkered: true,
                  gradient: LinearGradient(
                    colors: [
                      _hsv.withAlpha(0).toColor(),
                      _hsv.withAlpha(1).toColor(),
                    ],
                  ),
                  onChanged: (t) => _set(_hsv.withAlpha(t)),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'HEX',
                    style: AppTheme.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.inkMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _hex,
                      onChanged: _applyHex,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(6),
                        FilteringTextInputFormatter.allow(
                          RegExp('[0-9a-fA-F]'),
                        ),
                      ],
                      style: AppTheme.body(
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                        letterSpacing: 1.2,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '#',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recents.isNotEmpty) ...[
                _SectionLabel(l10n.recentColors),
                _Swatches(
                  values: recents,
                  selected: _color.toARGB32(),
                  onPick: _pickPreset,
                ),
                const SizedBox(height: 12),
              ],
              _SectionLabel(l10n.presetColors),
              _Swatches(
                values: kColorPresets,
                selected: _color.toARGB32(),
                onPick: _pickPreset,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (widget.onDelete != null)
                    IconButton(
                      tooltip: l10n.removeColor,
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDelete!();
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: palette.danger,
                      ),
                    ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, _color.toARGB32()),
                      child: Text(l10n.apply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.body(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.inkMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _CheckerPainter(),
        child: Container(color: color),
      ),
    );
  }
}

/// Saturation on the x axis, value on the y axis — the familiar colour square.
class _SaturationValueField extends StatelessWidget {
  const _SaturationValueField({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 172);

        void handle(Offset local) {
          final saturation = (local.dx / size.width).clamp(0.0, 1.0);
          final value = 1 - (local.dy / size.height).clamp(0.0, 1.0);
          onChanged(hsv.withSaturation(saturation).withValue(value));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: hsv.saturation * size.width - 11,
                    top: (1 - hsv.value) * size.height - 11,
                    child: const _Thumb(size: 22),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Slider with a gradient track, used for hue and opacity.
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.label,
    required this.value,
    required this.gradient,
    required this.thumbColor,
    required this.onChanged,
    this.checkered = false,
  });

  final String label;
  final double value;
  final Gradient gradient;
  final Color thumbColor;
  final ValueChanged<double> onChanged;
  final bool checkered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const track = 22.0;
            void handle(Offset local) =>
                onChanged((local.dx / width).clamp(0.0, 1.0));

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => handle(d.localPosition),
              onPanUpdate: (d) => handle(d.localPosition),
              child: SizedBox(
                height: 30,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(track / 2),
                      child: SizedBox(
                        height: track,
                        width: width,
                        child: CustomPaint(
                          painter: checkered ? _CheckerPainter() : null,
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: gradient),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: math.max(0, value * width - 13),
                      child: _Thumb(size: 26, fill: thumbColor),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.size, this.fill});

  final double size;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 5, spreadRadius: 1),
        ],
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({
    required this.values,
    required this.selected,
    required this.onPick,
  });

  final List<int> values;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final value = values[index];
        final active = (value & 0x00FFFFFF) == (selected & 0x00FFFFFF);
        return GestureDetector(
          onTap: () => onPick(value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(value),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: active ? AppTheme.accent : AppTheme.outline,
                width: active ? 2 : 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({
    required this.values,
    required this.selected,
    required this.onPick,
  });

  final List<int> values;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final value in values)
          GestureDetector(
            onTap: () => onPick(value),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (value & 0x00FFFFFF) == (selected & 0x00FFFFFF)
                      ? AppTheme.accent
                      : AppTheme.outline,
                  width: (value & 0x00FFFFFF) == (selected & 0x00FFFFFF)
                      ? 3
                      : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Grey chequerboard that makes partial opacity visible.
class _CheckerPainter extends CustomPainter {
  static const _cell = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFD9D9DE);
    canvas.drawRect(Offset.zero & size, light);
    for (var y = 0.0; y < size.height; y += _cell) {
      for (var x = 0.0; x < size.width; x += _cell) {
        final odd = ((x / _cell).floor() + (y / _cell).floor()).isOdd;
        if (odd) canvas.drawRect(Rect.fromLTWH(x, y, _cell, _cell), dark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerPainter oldDelegate) => false;
}
