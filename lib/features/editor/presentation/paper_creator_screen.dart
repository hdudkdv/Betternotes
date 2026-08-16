import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../data/models/content_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../entitlements/entitlement_model.dart';
import '../../entitlements/rewarded_ad_mock.dart';
import '../../../shared/widgets/color_picker_sheet.dart';
import '../../library/providers/library_providers.dart';
import '../domain/ink_models.dart';
import 'editor_chrome.dart';
import 'widgets/page_background_painter.dart';

/// Paper studio: live preview + contextual controls (GoodNotes-like).
class PaperCreatorScreen extends ConsumerStatefulWidget {
  const PaperCreatorScreen({super.key, this.initial});

  final PaperTemplate? initial;

  @override
  ConsumerState<PaperCreatorScreen> createState() => _PaperCreatorScreenState();
}

class _PaperCreatorScreenState extends ConsumerState<PaperCreatorScreen> {
  late String _name;
  late String _style;
  late double _lineSpacing;
  late double _gridSize;
  late double _marginLeft;
  late double _marginTop;
  late int _bg;
  late int _line;
  late TextEditingController _nameController;
  String? _editingId;
  bool _isBuiltin = false;

  static const _paperColors = <int>[
    0xFFFFFBF5,
    0xFFFFFFF8,
    0xFFF7F2E8,
    0xFFF3F7FF,
    0xFFF4FFF7,
    0xFFFFF5F5,
    0xFFF5F0FF,
    0xFFECEFF1,
    0xFFFFFFFF,
    0xFF1C1C1E,
    0xFF243028,
    0xFF1E2430,
    0xFF2A2420,
  ];

  static const _lineColors = <int>[
    0xFFD7D2C8,
    0xFFC5CCD6,
    0xFFB8C9B5,
    0xFFD4B8B8,
    0xFFB0B0B5,
    0xFF9AA4B2,
    0xFF8B7355,
    0xFF6B8CAE,
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _editingId = i?.isBuiltin == true ? null : i?.id;
    _isBuiltin = i?.isBuiltin ?? false;
    _name = i?.name ?? 'My paper';
    _style = i?.style ?? 'lined';
    _lineSpacing = i?.lineSpacing ?? 28;
    _gridSize = i?.gridSize ?? 24;
    _marginLeft = i?.marginLeft ?? 72;
    _marginTop = i?.marginTop ?? 48;
    _bg = i?.backgroundColor ?? 0xFFFFFBF5;
    _line = i?.lineColor ?? 0xFFD7D2C8;
    _nameController = TextEditingController(text: _name);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initial == null &&
        (_name == 'My paper' || _name == 'Mein Papier')) {
      final localized = AppLocalizations.of(context)!.myPaper;
      if (_name != localized) {
        _name = localized;
        _nameController.text = localized;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  PaperTemplate get _draft => PaperTemplate(
    id: _editingId ?? 'draft',
    name: _name.trim().isEmpty
        ? AppLocalizations.of(context)!.myPaper
        : _name.trim(),
    lineSpacing: _lineSpacing,
    gridSize: _gridSize,
    marginLeft: _marginLeft,
    marginTop: _marginTop,
    backgroundColor: _bg,
    lineColor: _line,
    style: _style,
    isBuiltin: false,
  );

  PageTemplate get _pageTemplate => PageTemplate.values.firstWhere(
    (t) => t.name == _style,
    orElse: () => PageTemplate.blank,
  );

  void _applyPreset(PaperTemplate t) {
    setState(() {
      _editingId = t.isBuiltin ? null : t.id;
      _isBuiltin = t.isBuiltin;
      _name = t.isBuiltin ? AppLocalizations.of(context)!.myPaper : t.name;
      _nameController.text = _name;
      _style = t.style;
      _lineSpacing = t.lineSpacing;
      _gridSize = t.gridSize;
      _marginLeft = t.marginLeft;
      _marginTop = t.marginTop;
      _bg = t.backgroundColor;
      _line = t.lineColor;
    });
  }

  Future<void> _saveAsPreset() async {
    final saved = PaperTemplate.create(
      name: _draft.name,
      lineSpacing: _lineSpacing,
      gridSize: _gridSize,
      marginLeft: _marginLeft,
      marginTop: _marginTop,
      backgroundColor: _bg,
      lineColor: _line,
      style: _style,
    );
    await ref.read(notebookRepositoryProvider).savePaperTemplate(saved);
    ref.invalidate(_paperTemplatesProvider);
    if (!mounted) return;
    setState(() {
      _editingId = saved.id;
      _isBuiltin = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.save)),
    );
  }

  void _resetSpacing() {
    setState(() {
      if (_style == 'grid') {
        _gridSize = 24;
        _marginLeft = 36;
        _marginTop = 36;
      } else if (_style == 'lined') {
        _lineSpacing = 28;
        _marginLeft = 72;
        _marginTop = 48;
      } else {
        _marginLeft = 72;
        _marginTop = 48;
      }
    });
  }

  Future<void> _pickCustomColor({required bool background}) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showColorPickerSheet(
      context,
      initialValue: background ? _bg : _line,
      title: background ? l10n.paperColor : l10n.lineColor,
      allowOpacity: false,
      recents: background ? _paperColors : _lineColors,
    );
    if (picked == null) return;
    setState(() {
      if (background) {
        _bg = picked;
      } else {
        _line = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(_paperTemplatesProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: EditorChrome.workspace,
      appBar: AppBar(
        backgroundColor: EditorChrome.topBar,
        foregroundColor: EditorChrome.onDark,
        iconTheme: IconThemeData(color: EditorChrome.onDark),
        title: Text(
          l10n.paperCreator,
          style: AppTheme.headline(
            color: EditorChrome.onDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetSpacing,
            child: Text(
              l10n.resetDefaults,
              style: TextStyle(color: EditorChrome.onDarkMuted),
            ),
          ),
          TextButton(
            onPressed: _saveAsPreset,
            child: Text(
              l10n.save,
              style: TextStyle(color: EditorChrome.onDark),
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: EditorChrome.toolbarSelected,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!ref
                    .read(entitlementProvider)
                    .hasAccess(FeatureKeys.premiumPaper)) {
                  await runRewardedUnlock(
                    context: context,
                    ref: ref,
                    featureKey: FeatureKeys.premiumPaper,
                  );
                  return;
                }
                if (context.mounted) Navigator.pop(context, _draft);
              },
              child: Text(l10n.applyPaper),
            ),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                Expanded(child: _previewPane(l10n)),
                SizedBox(
                  width: 400,
                  child: _controlsPane(l10n, templatesAsync),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 5, child: _previewPane(l10n)),
                Expanded(flex: 6, child: _controlsPane(l10n, templatesAsync)),
              ],
            ),
    );
  }

  Widget _previewPane(AppLocalizations l10n) {
    return Container(
      color: EditorChrome.workspace,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Text(
            l10n.paperPreview,
            style: AppTheme.body(
              color: EditorChrome.onDarkMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 595 / 842,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: 595,
                        height: 842,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              size: const Size(595, 842),
                              painter: PageBackgroundPainter(
                                template: _pageTemplate,
                                paper: _draft,
                              ),
                            ),
                            if (_style == 'lined')
                              CustomPaint(
                                size: const Size(595, 842),
                                painter: _MarginGuidePainter(
                                  marginLeft: _marginLeft,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _styleLabel(l10n),
            style: AppTheme.body(
              color: EditorChrome.onDarkMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _styleLabel(AppLocalizations l10n) {
    switch (_style) {
      case 'blank':
        return l10n.blank;
      case 'grid':
        return '${l10n.grid} · ${_gridSize.toStringAsFixed(0)} pt';
      case 'dotted':
        return '${l10n.dotGrid} · ${_gridSize.toStringAsFixed(0)} pt';
      default:
        return '${l10n.lined} · ${_lineSpacing.toStringAsFixed(0)} pt';
    }
  }

  Widget _controlsPane(
    AppLocalizations l10n,
    AsyncValue<List<PaperTemplate>> templatesAsync,
  ) {
    return Material(
      color: AppTheme.paper,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            l10n.paperPresets,
            style: AppTheme.headline(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.paperPresetsHint,
            style: AppTheme.body(
              fontSize: 13,
              color: AppTheme.ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          templatesAsync.when(
            data: (templates) => SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final t = templates[i];
                  final selected = _matchesPreset(t);
                  return _PresetThumb(
                    template: t,
                    selected: selected,
                    label: _presetLabel(l10n, t),
                    onTap: () => _applyPreset(t),
                    onDelete: t.isBuiltin
                        ? null
                        : () async {
                            await ref
                                .read(notebookRepositoryProvider)
                                .deletePaperTemplate(t.id);
                            ref.invalidate(_paperTemplatesProvider);
                            if (_editingId == t.id) {
                              setState(() => _editingId = null);
                            }
                          },
                  );
                },
              ),
            ),
            loading: () => const SizedBox(
              height: 118,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.title,
              hintText: l10n.myPaper,
            ),
            onChanged: (v) => setState(() {
              _name = v;
              _isBuiltin = false;
              if (_editingId == null ||
                  PaperTemplate.builtins().any((b) => b.id == _editingId)) {
                _editingId = null;
              }
            }),
          ),
          if (_isBuiltin) ...[
            const SizedBox(height: 8),
            Text(
              l10n.editingBuiltinHint,
              style: AppTheme.body(
                fontSize: 12,
                color: AppTheme.ink.withValues(alpha: 0.5),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            l10n.style,
            style: AppTheme.body(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: MediaQuery.sizeOf(context).width >= 700
                ? 0.5
                : 0.85,
            children: [
              for (final style in const ['blank', 'lined', 'grid', 'dotted'])
                _StyleCard(
                  style: style,
                  selected: _style == style,
                  label: switch (style) {
                    'blank' => l10n.blank,
                    'grid' => l10n.grid,
                    'dotted' => l10n.dotGrid,
                    _ => l10n.lined,
                  },
                  bg: _bg,
                  line: _line,
                  onTap: () => setState(() {
                    _style = style;
                    if ((style == 'grid' || style == 'dotted') &&
                        _marginLeft > 60) {
                      _marginLeft = 36;
                      _marginTop = 36;
                    } else if (style == 'lined' && _marginLeft < 48) {
                      _marginLeft = 72;
                      _marginTop = 48;
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 22),
          if (_style == 'lined') ...[
            _sectionTitle(l10n.lineSpacing),
            _sliderRow(
              value: _lineSpacing,
              min: 16,
              max: 52,
              onChanged: (v) => setState(() => _lineSpacing = v),
            ),
            _sectionTitle(l10n.leftMargin),
            _sliderRow(
              value: _marginLeft,
              min: 24,
              max: 140,
              onChanged: (v) => setState(() => _marginLeft = v),
            ),
            _sectionTitle(l10n.topMargin),
            _sliderRow(
              value: _marginTop,
              min: 16,
              max: 140,
              onChanged: (v) => setState(() => _marginTop = v),
            ),
          ],
          if (_style == 'grid' || _style == 'dotted') ...[
            _sectionTitle(
              _style == 'dotted' ? l10n.dotGrid : l10n.gridSize,
            ),
            _sliderRow(
              value: _gridSize,
              min: 10,
              max: 48,
              onChanged: (v) => setState(() => _gridSize = v),
            ),
            if (_style == 'grid') ...[
              _sectionTitle(l10n.topMargin),
              _sliderRow(
                value: _marginTop,
                min: 8,
                max: 80,
                onChanged: (v) => setState(() {
                  _marginTop = v;
                  _marginLeft = v;
                }),
              ),
            ],
          ],
          if (_style == 'blank') ...[
            Text(
              l10n.blankPaperHint,
              style: AppTheme.body(
                fontSize: 13,
                color: AppTheme.ink.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          _sectionTitle(l10n.paperColor),
          const SizedBox(height: 8),
          _colorRow(
            colors: _paperColors,
            selected: _bg,
            onSelect: (c) => setState(() => _bg = c),
            onCustom: () => _pickCustomColor(background: true),
          ),
          if (_style != 'blank') ...[
            const SizedBox(height: 16),
            _sectionTitle(l10n.lineColor),
            const SizedBox(height: 8),
            _colorRow(
              colors: _lineColors,
              selected: _line,
              onSelect: (c) => setState(() => _line = c),
              onCustom: () => _pickCustomColor(background: false),
            ),
          ],
        ],
      ),
    );
  }

  bool _matchesPreset(PaperTemplate t) {
    if (_editingId != null && _editingId == t.id) return true;
    if (_editingId != null) return false;
    return t.style == _style &&
        t.backgroundColor == _bg &&
        t.lineColor == _line &&
        (t.lineSpacing - _lineSpacing).abs() < 0.5 &&
        (t.gridSize - _gridSize).abs() < 0.5 &&
        (t.marginLeft - _marginLeft).abs() < 0.5 &&
        (t.marginTop - _marginTop).abs() < 0.5;
  }

  String _presetLabel(AppLocalizations l10n, PaperTemplate t) {
    if (!t.isBuiltin) return t.name;
    switch (t.id) {
      case 'builtin_blank':
        return l10n.blank;
      case 'builtin_lined':
        return l10n.lined;
      case 'builtin_grid':
        return l10n.grid;
      case 'builtin_college':
        return l10n.collegeRuled;
      case 'builtin_narrow':
        return l10n.narrowRuled;
      case 'builtin_dots':
        return l10n.dotGrid;
      default:
        return t.name;
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTheme.body(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.ink.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accent,
              thumbColor: AppTheme.accent,
              inactiveTrackColor: AppTheme.accentSoft,
              overlayColor: AppTheme.accent.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(0),
            textAlign: TextAlign.end,
            style: AppTheme.body(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppTheme.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorRow({
    required List<int> colors,
    required int selected,
    required ValueChanged<int> onSelect,
    required VoidCallback onCustom,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in colors)
          GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c ? AppTheme.accent : AppTheme.outline,
                  width: selected == c ? 2.5 : 1,
                ),
                boxShadow: [
                  if (selected == c)
                    BoxShadow(
                      color: AppTheme.ink.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
            ),
          ),
        GestureDetector(
          onTap: onCustom,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.ink.withValues(alpha: 0.35)),
              color: Colors.white,
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 16,
              color: AppTheme.ink.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

final _paperTemplatesProvider = FutureProvider.autoDispose<List<PaperTemplate>>(
  (ref) {
    return ref.watch(notebookRepositoryProvider).getPaperTemplates();
  },
);

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.label,
    required this.bg,
    required this.line,
    required this.onTap,
  });

  final String style;
  final bool selected;
  final String label;
  final int bg;
  final int line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentSoft : AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.accent : AppTheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 0.72,
                child: CustomPaint(
                  painter: _MiniPaperPainter(style: style, bg: bg, line: line),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetThumb extends StatelessWidget {
  const _PresetThumb({
    required this.template,
    required this.selected,
    required this.label,
    required this.onTap,
    this.onDelete,
  });

  final PaperTemplate template;
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      onLongPress: onDelete,
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppTheme.accent : Colors.black12,
                            width: selected ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: 595,
                            height: 842,
                            child: CustomPaint(
                              size: const Size(595, 842),
                              painter: PageBackgroundPainter(
                                template: PageTemplate.values.firstWhere(
                                  (t) => t.name == template.style,
                                  orElse: () => PageTemplate.blank,
                                ),
                                paper: template,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (onDelete != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPaperPainter extends CustomPainter {
  _MiniPaperPainter({
    required this.style,
    required this.bg,
    required this.line,
  });

  final String style;
  final int bg;
  final int line;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = Color(bg),
    );
    final paint = Paint()
      ..color = Color(line)
      ..strokeWidth = 1;
    switch (style) {
      case 'lined':
        for (var y = size.height * 0.22; y < size.height - 4; y += 7) {
          canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
        }
        canvas.drawLine(
          Offset(size.width * 0.22, 4),
          Offset(size.width * 0.22, size.height - 4),
          Paint()
            ..color = const Color(0xFFE8A0A0)
            ..strokeWidth = 1,
        );
        break;
      case 'grid':
        for (var x = 6.0; x < size.width - 2; x += 7) {
          canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), paint);
        }
        for (var y = 6.0; y < size.height - 2; y += 7) {
          canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
        }
        break;
      case 'dotted':
        for (var x = 6.0; x < size.width - 2; x += 7) {
          for (var y = 6.0; y < size.height - 2; y += 7) {
            canvas.drawCircle(Offset(x, y), 0.9, paint);
          }
        }
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPaperPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.bg != bg ||
        oldDelegate.line != line;
  }
}

class _MarginGuidePainter extends CustomPainter {
  _MarginGuidePainter({required this.marginLeft});

  final double marginLeft;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft highlight of the writing margin — visual only.
    canvas.drawLine(
      Offset(marginLeft, 0),
      Offset(marginLeft, size.height),
      Paint()
        ..color = const Color(0x55E8A0A0)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _MarginGuidePainter oldDelegate) {
    return oldDelegate.marginLeft != marginLeft;
  }
}
