import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../data/models/content_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_size.dart';
import '../../../library/providers/library_providers.dart';
import '../../domain/ink_engine.dart';
import '../../domain/ink_models.dart';
import '../editor_chrome.dart';
import 'editor_more_sheet.dart';

/// Actions offered by the overflow menu of the editor top bar.
enum EditorMenuAction {
  share,
  outline,
  paperCreator,
  importPdf,
  scanPages,
  deletePage,
  importHtml,
  importAnyFile,
  settings,
  collaborate,
  nearbySync,
  scrollDirection,
  addTag,
  studyMode,
  presentView,
  makeFlashcard,
  saveSnapshot,
  restoreSnapshot,
  templateBlank,
  templateLined,
  templateGrid,
  paperA4,
  paperA2,
  paperA3,
  paperA5,
  paperA6,
  paperLetter,
  paperLegal,
  paperTabloid,
  orientationPortrait,
  orientationLandscape,
}

/// Thin editor rail plus a tool dock around [body].
///
/// Tools sit in a left dock on wide screens and a bottom dock on phones —
/// not in a second dark bar and not in a GoodNotes-style floating pill.
class EditorTopBar extends StatelessWidget {
  const EditorTopBar({
    super.key,
    required this.body,
    required this.notebookId,
    required this.tabIds,
    required this.engine,
    required this.locked,
    required this.studyMode,
    required this.browseMode,
    required this.canvasMode,
    required this.pageTemplate,
    required this.defaultPaperFormat,
    required this.defaultOrientation,
    required this.onSelectTab,
    required this.onCloseTab,
    required this.onHome,
    required this.onToggleSidebar,
    required this.onSearch,
    required this.onOutline,
    required this.onPickImage,
    this.onScanPages,
    this.onPickSticker,
    required this.onCalculator,
    required this.onFormulaBook,
    this.calculatorOpen = false,
    this.formulaBookOpen = false,
    this.assistantOpen = false,
    this.onAssistant,
    required this.onAddPage,
    required this.onToggleLock,
    required this.onToggleStudy,
    this.studyModeUnlocked = false,
    required this.onMenuAction,
    this.onConfigureEraser,
    this.onConfigureLasso,
    this.rulerActive = false,
    this.compassActive = false,
    this.onToggleRuler,
    this.onToggleCompass,
    this.onCreateDiagram,
    this.onOpenPacks,
  });

  final Widget body;
  final String notebookId;
  final List<String> tabIds;
  final InkEngine engine;
  final bool locked;
  final bool studyMode;
  final PageBrowseMode browseMode;
  final CanvasMode canvasMode;
  final PageTemplate pageTemplate;
  final PaperFormat defaultPaperFormat;
  final PageOrientation defaultOrientation;
  final ValueChanged<String> onSelectTab;
  final ValueChanged<String> onCloseTab;
  final VoidCallback onHome;
  final VoidCallback onToggleSidebar;
  final VoidCallback onSearch;
  final VoidCallback onOutline;
  final VoidCallback onPickImage;
  final VoidCallback? onScanPages;
  final VoidCallback? onPickSticker;
  final VoidCallback onCalculator;
  final VoidCallback onFormulaBook;
  final bool calculatorOpen;
  final bool formulaBookOpen;
  final bool assistantOpen;
  final VoidCallback? onAssistant;
  final VoidCallback onAddPage;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleStudy;
  final bool studyModeUnlocked;
  final ValueChanged<EditorMenuAction> onMenuAction;
  final VoidCallback? onConfigureEraser;
  final VoidCallback? onConfigureLasso;
  final bool rulerActive;
  final bool compassActive;
  final VoidCallback? onToggleRuler;
  final VoidCallback? onToggleCompass;
  final VoidCallback? onCreateDiagram;
  final VoidCallback? onOpenPacks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: EditorChrome.topBar,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: EditorChrome.divider)),
            ),
            child: SizedBox(
              height: EditorChrome.tabRowHeight,
              child: Row(
                children: [
                  _BarIcon(
                    icon: Icons.home_outlined,
                    tooltip: AppLocalizations.of(context)!.libraryHome,
                    onTap: onHome,
                  ),
                  Expanded(
                    child: _DocumentTabs(
                      tabIds: tabIds,
                      activeId: notebookId,
                      onSelect: onSelectTab,
                      onClose: onCloseTab,
                    ),
                  ),
                  _BarIcon(
                    icon: Icons.view_sidebar_outlined,
                    tooltip: AppLocalizations.of(context)!.pageSidebar,
                    onTap: onToggleSidebar,
                  ),
                  _BarIcon(
                    icon: Icons.search_rounded,
                    tooltip: AppLocalizations.of(context)!.globalSearch,
                    onTap: onSearch,
                  ),
                  _BarIcon(
                    icon: Icons.list_alt_rounded,
                    tooltip: AppLocalizations.of(context)!.outline,
                    onTap: onOutline,
                  ),
                  _BarIcon(
                    icon: Icons.post_add_rounded,
                    tooltip: AppLocalizations.of(context)!.addPage,
                    enabled: !locked && !studyMode,
                    onTap: onAddPage,
                  ),
                  _BarIcon(
                    icon: locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    tooltip: locked
                        ? AppLocalizations.of(context)!.unlockPage
                        : AppLocalizations.of(context)!.lockPage,
                    active: locked,
                    onTap: onToggleLock,
                  ),
                  if (studyModeUnlocked || studyMode)
                    _BarIcon(
                      icon: Icons.school_outlined,
                      tooltip: AppLocalizations.of(context)!.studyMode,
                      active: studyMode,
                      onTap: onToggleStudy,
                    ),
                  _BarIcon(
                    icon: Icons.ios_share_rounded,
                    tooltip: AppLocalizations.of(context)!.shareExport,
                    onTap: () => onMenuAction(EditorMenuAction.share),
                  ),
                  _BarIcon(
                    icon: Icons.more_horiz_rounded,
                    tooltip: AppLocalizations.of(context)!.moreOptions,
                    onTap: () => showEditorMoreSheet(
                      context,
                      template: pageTemplate,
                      browseMode: browseMode,
                      canvasMode: canvasMode,
                      defaultPaperFormat: defaultPaperFormat,
                      defaultOrientation: defaultOrientation,
                      studyModeUnlocked: studyModeUnlocked,
                      onAction: onMenuAction,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final vertical =
                  constraints.maxWidth >= EditorChrome.dockBreakpoint;
              final dock = _ToolDock(
                axis: vertical ? Axis.vertical : Axis.horizontal,
                engine: engine,
                locked: locked,
                studyMode: studyMode,
                onPickImage: onPickImage,
                onScanPages: onScanPages,
                onPickSticker: onPickSticker,
                onCalculator: onCalculator,
                onFormulaBook: onFormulaBook,
                calculatorOpen: calculatorOpen,
                formulaBookOpen: formulaBookOpen,
                assistantOpen: assistantOpen,
                onAssistant: onAssistant,
                onConfigureEraser: onConfigureEraser,
                onConfigureLasso: onConfigureLasso,
                rulerActive: rulerActive,
                compassActive: compassActive,
                onToggleRuler: onToggleRuler,
                onToggleCompass: onToggleCompass,
                onCreateDiagram: onCreateDiagram,
                onOpenPacks: onOpenPacks,
              );
              if (vertical) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    dock,
                    Expanded(child: body),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(child: body),
                  dock,
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ToolDock extends StatelessWidget {
  const _ToolDock({
    required this.axis,
    required this.engine,
    required this.locked,
    required this.studyMode,
    required this.onPickImage,
    this.onScanPages,
    this.onPickSticker,
    required this.onCalculator,
    required this.onFormulaBook,
    required this.calculatorOpen,
    required this.formulaBookOpen,
    required this.assistantOpen,
    this.onAssistant,
    this.onConfigureEraser,
    this.onConfigureLasso,
    this.rulerActive = false,
    this.compassActive = false,
    this.onToggleRuler,
    this.onToggleCompass,
    this.onCreateDiagram,
    this.onOpenPacks,
  });

  final Axis axis;
  final InkEngine engine;
  final bool locked;
  final bool studyMode;
  final VoidCallback onPickImage;
  final VoidCallback? onScanPages;
  final VoidCallback? onPickSticker;
  final VoidCallback onCalculator;
  final VoidCallback onFormulaBook;
  final bool calculatorOpen;
  final bool formulaBookOpen;
  final bool assistantOpen;
  final VoidCallback? onAssistant;
  final VoidCallback? onConfigureEraser;
  final VoidCallback? onConfigureLasso;
  final bool rulerActive;
  final bool compassActive;
  final VoidCallback? onToggleRuler;
  final VoidCallback? onToggleCompass;
  final VoidCallback? onCreateDiagram;
  final VoidCallback? onOpenPacks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vertical = axis == Axis.vertical;
    final enabled = !locked && !studyMode;

    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final tools = <Widget>[
          _ToolIcon(
            engine: engine,
            tool: InkTool.lasso,
            icon: Icons.gesture_rounded,
            label: l10n.lasso,
            enabled: enabled,
            compact: vertical,
            onLongPress: onConfigureLasso,
          ),
          _ToolIcon(
            engine: engine,
            tool: InkTool.pen,
            icon: Icons.edit_rounded,
            label: l10n.pen,
            enabled: enabled,
            compact: vertical,
            activeOverride:
                engine.tool == InkTool.pen || engine.tool == InkTool.fountain,
            onTapOverride: () {
              if (engine.tool == InkTool.pen ||
                  engine.tool == InkTool.fountain) {
                engine.setTool(InkTool.none);
              } else {
                engine.setPenSubtype(fountain: false);
              }
            },
          ),
          _ToolIcon(
            engine: engine,
            tool: InkTool.pencil,
            icon: Icons.create_rounded,
            label: l10n.pencil,
            enabled: enabled,
            compact: vertical,
          ),
          _ToolIcon(
            engine: engine,
            tool: InkTool.marker,
            icon: Icons.highlight_rounded,
            label: l10n.marker,
            enabled: enabled,
            compact: vertical,
          ),
          _ToolIcon(
            engine: engine,
            tool: InkTool.eraser,
            icon: Icons.format_color_reset_rounded,
            label: l10n.eraser,
            enabled: enabled,
            compact: vertical,
            onLongPress: onConfigureEraser,
          ),
          _ToolIcon(
            engine: engine,
            tool: InkTool.text,
            icon: Icons.title_rounded,
            label: l10n.textTool,
            enabled: enabled,
            compact: vertical,
          ),
          _ToolIcon(
            engine: engine,
            tool: InkTool.shape,
            icon: Icons.change_history_rounded,
            label: l10n.shapes,
            enabled: enabled,
            compact: vertical,
          ),
          if (rulerActive)
            _BarIcon(
              icon: Icons.straighten_rounded,
              tooltip: l10n.ruler,
              active: true,
              enabled: enabled,
              compact: vertical,
              onTap: onToggleRuler,
            ),
          if (compassActive)
            _BarIcon(
              icon: Icons.architecture_rounded,
              tooltip: l10n.compass,
              active: true,
              enabled: enabled,
              compact: vertical,
              onTap: onToggleCompass,
            ),
          _BarIcon(
            icon: Icons.calculate_outlined,
            tooltip: l10n.calculator,
            active: calculatorOpen,
            enabled: enabled,
            compact: vertical,
            onTap: onCalculator,
          ),
          _BarIcon(
            icon: Icons.menu_book_outlined,
            tooltip: l10n.formulaBook,
            active: formulaBookOpen,
            enabled: enabled,
            compact: vertical,
            onTap: onFormulaBook,
          ),
          if (onAssistant != null)
            _BarIcon(
              icon: Icons.auto_awesome_outlined,
              tooltip: l10n.assistant,
              active: assistantOpen,
              enabled: enabled,
              compact: vertical,
              onTap: onAssistant,
            ),
          if (onCreateDiagram != null)
            _BarIcon(
              icon: Icons.bar_chart_rounded,
              tooltip: l10n.diagrams,
              enabled: enabled,
              compact: vertical,
              onTap: onCreateDiagram,
            ),
          if (onOpenPacks != null)
            _BarIcon(
              icon: Icons.inventory_2_outlined,
              tooltip: l10n.packsTitle,
              enabled: enabled,
              compact: vertical,
              onTap: onOpenPacks,
            ),
          if (onScanPages != null)
            _BarIcon(
              icon: Icons.document_scanner_outlined,
              tooltip: l10n.scanPages,
              enabled: enabled,
              compact: vertical,
              onTap: onScanPages,
            ),
          _BarIcon(
            icon: Icons.add_photo_alternate_outlined,
            tooltip: l10n.insertImage,
            active: engine.tool == InkTool.image,
            enabled: enabled,
            compact: vertical,
            onTap: () {
              engine.setTool(InkTool.image);
              onPickImage();
            },
          ),
          if (onPickSticker != null)
            _BarIcon(
              icon: Icons.emoji_emotions_outlined,
              tooltip: l10n.stickers,
              active: engine.tool == InkTool.sticker,
              enabled: enabled,
              compact: vertical,
              onTap: onPickSticker,
            ),
        ];

        final scroll = SingleChildScrollView(
          scrollDirection: axis,
          padding: EdgeInsets.symmetric(
            horizontal: vertical ? 4 : 8,
            vertical: vertical ? 8 : 4,
          ),
          child: vertical
              ? Column(children: tools)
              : Row(mainAxisSize: MainAxisSize.min, children: tools),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.toolBar,
            border: Border(
              right: vertical
                  ? BorderSide(color: EditorChrome.divider)
                  : BorderSide.none,
              top: vertical
                  ? BorderSide.none
                  : BorderSide(color: EditorChrome.divider),
            ),
          ),
          child: SizedBox(
            width: vertical ? EditorChrome.dockWidth : null,
            height: vertical ? null : EditorChrome.toolRowHeight,
            child: vertical ? scroll : Center(child: scroll),
          ),
        );
      },
    );
  }
}

/// Tool button that toggles itself off when tapped while already active.
class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.engine,
    required this.tool,
    required this.icon,
    required this.label,
    required this.enabled,
    this.compact = false,
    this.activeOverride,
    this.onTapOverride,
    this.onLongPress,
  });

  final InkEngine engine;
  final InkTool tool;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool compact;
  final bool? activeOverride;
  final VoidCallback? onTapOverride;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final selected = activeOverride ?? engine.tool == tool;
    return _BarIcon(
      icon: icon,
      tooltip: selected ? AppLocalizations.of(context)!.deselectTool : label,
      active: selected,
      enabled: enabled,
      compact: compact,
      onTap: onTapOverride ??
          () => engine.setTool(selected ? InkTool.none : tool),
      onLongPress: onLongPress == null
          ? null
          : () {
              if (!selected) engine.setTool(tool);
              onLongPress!();
            },
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.onLongPress,
    this.active = false,
    this.enabled = true,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool active;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : 1.5,
        vertical: compact ? 2 : 0,
      ),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: compact ? 44 : null,
            height: compact ? 44 : 34,
            constraints: BoxConstraints(
              minWidth: compact ? 44 : 38,
              minHeight: compact ? 44 : 34,
            ),
            decoration: BoxDecoration(
              color: active ? EditorChrome.selectedSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 21,
              color: enabled
                  ? (active ? EditorChrome.selected : EditorChrome.onDarkMuted)
                  : EditorChrome.onDarkMuted.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

/// Open notebooks as chips on the rail — a shelf, not browser tabs.
class _DocumentTabs extends ConsumerWidget {
  const _DocumentTabs({
    required this.tabIds,
    required this.activeId,
    required this.onSelect,
    required this.onClose,
  });

  final List<String> tabIds;
  final String activeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notebooks = ref.watch(notebooksProvider).valueOrNull ?? const [];
    String titleFor(String id) {
      for (final notebook in notebooks) {
        if (notebook.id == id) return notebook.title;
      }
      return id.length > 8 ? id.substring(0, 8) : id;
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      itemCount: tabIds.length,
      separatorBuilder: (context, index) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final id = tabIds[index];
        final active = id == activeId;
        return GestureDetector(
          onTap: () => onSelect(id),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 190),
            padding: const EdgeInsets.only(left: 10, right: 2),
            decoration: BoxDecoration(
              color: active ? EditorChrome.chip : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? EditorChrome.selected.withValues(alpha: 0.35) : EditorChrome.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? EditorChrome.selected : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    titleFor(id),
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                      color: active
                          ? EditorChrome.onDark
                          : EditorChrome.onDarkMuted,
                      fontSize: 14.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onClose(id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: EditorChrome.onDarkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
