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
  importAnyFile,
  settings,
  collaborate,
  nearbySync,
  scrollDirection,
  addTag,
  studyMode,
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

/// Two-row editor header: document tabs on top, tools below.
class EditorTopBar extends StatelessWidget {
  const EditorTopBar({
    super.key,
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
    required this.onPresent,
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
  final VoidCallback onPresent;
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
    return Material(
      color: EditorChrome.topBar,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
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
              ],
            ),
          ),
          _ToolRow(
            engine: engine,
            locked: locked,
            studyMode: studyMode,
            browseMode: browseMode,
            canvasMode: canvasMode,
            pageTemplate: pageTemplate,
            defaultPaperFormat: defaultPaperFormat,
            defaultOrientation: defaultOrientation,
            onToggleSidebar: onToggleSidebar,
            onSearch: onSearch,
            onOutline: onOutline,
            onPickImage: onPickImage,
            onCalculator: onCalculator,
            onFormulaBook: onFormulaBook,
            calculatorOpen: calculatorOpen,
            formulaBookOpen: formulaBookOpen,
            assistantOpen: assistantOpen,
            onAssistant: onAssistant,
            onAddPage: onAddPage,
            onToggleLock: onToggleLock,
            onToggleStudy: onToggleStudy,
            studyModeUnlocked: studyModeUnlocked,
            onPresent: onPresent,
            onMenuAction: onMenuAction,
            onConfigureEraser: onConfigureEraser,
            onConfigureLasso: onConfigureLasso,
            rulerActive: rulerActive,
            compassActive: compassActive,
            onToggleRuler: onToggleRuler,
            onToggleCompass: onToggleCompass,
            onCreateDiagram: onCreateDiagram,
            onOpenPacks: onOpenPacks,
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.engine,
    required this.locked,
    required this.studyMode,
    required this.browseMode,
    required this.canvasMode,
    required this.pageTemplate,
    required this.defaultPaperFormat,
    required this.defaultOrientation,
    required this.onToggleSidebar,
    required this.onSearch,
    required this.onOutline,
    required this.onPickImage,
    required this.onCalculator,
    required this.onFormulaBook,
    required this.calculatorOpen,
    required this.formulaBookOpen,
    required this.assistantOpen,
    this.onAssistant,
    required this.onAddPage,
    required this.onToggleLock,
    required this.onToggleStudy,
    this.studyModeUnlocked = false,
    required this.onPresent,
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

  final InkEngine engine;
  final bool locked;
  final bool studyMode;
  final PageBrowseMode browseMode;
  final CanvasMode canvasMode;
  final PageTemplate pageTemplate;
  final PaperFormat defaultPaperFormat;
  final PageOrientation defaultOrientation;
  final VoidCallback onToggleSidebar;
  final VoidCallback onSearch;
  final VoidCallback onOutline;
  final VoidCallback onPickImage;
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
  final VoidCallback onPresent;
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
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        return Container(
          height: EditorChrome.toolRowHeight,
          color: EditorChrome.toolBar,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              _BarIcon(
                icon: Icons.view_sidebar_outlined,
                tooltip: l10n.pageSidebar,
                onTap: onToggleSidebar,
              ),
              _BarIcon(
                icon: Icons.search_rounded,
                tooltip: l10n.globalSearch,
                onTap: onSearch,
              ),
              _BarIcon(
                icon: Icons.list_alt_rounded,
                tooltip: l10n.outline,
                onTap: onOutline,
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ToolIcon(
                          engine: engine,
                          tool: InkTool.lasso,
                          icon: Icons.gesture_rounded,
                          label: l10n.lasso,
                          enabled: !locked && !studyMode,
                          onLongPress: onConfigureLasso,
                        ),
                        _ToolIcon(
                          engine: engine,
                          tool: InkTool.pen,
                          icon: Icons.edit_rounded,
                          label: l10n.pen,
                          enabled: !locked && !studyMode,
                          activeOverride: engine.tool == InkTool.pen ||
                              engine.tool == InkTool.fountain,
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
                          enabled: !locked && !studyMode,
                        ),
                        _ToolIcon(
                          engine: engine,
                          tool: InkTool.marker,
                          icon: Icons.highlight_rounded,
                          label: l10n.marker,
                          enabled: !locked && !studyMode,
                        ),
                        _ToolIcon(
                          engine: engine,
                          tool: InkTool.eraser,
                          icon: Icons.format_color_reset_rounded,
                          label: l10n.eraser,
                          enabled: !locked && !studyMode,
                          onLongPress: onConfigureEraser,
                        ),
                        _ToolIcon(
                          engine: engine,
                          tool: InkTool.text,
                          icon: Icons.title_rounded,
                          label: l10n.textTool,
                          enabled: !locked && !studyMode,
                        ),
                        _ToolIcon(
                          engine: engine,
                          tool: InkTool.shape,
                          icon: Icons.change_history_rounded,
                          label: l10n.shapes,
                          enabled: !locked && !studyMode,
                        ),
                        if (rulerActive)
                          _BarIcon(
                            icon: Icons.straighten_rounded,
                            tooltip: l10n.ruler,
                            label: l10n.ruler,
                            active: true,
                            enabled: !locked && !studyMode,
                            onTap: onToggleRuler,
                          ),
                        if (compassActive)
                          _BarIcon(
                            icon: Icons.architecture_rounded,
                            tooltip: l10n.compass,
                            label: l10n.compass,
                            active: true,
                            enabled: !locked && !studyMode,
                            onTap: onToggleCompass,
                          ),
                        _BarIcon(
                          icon: Icons.calculate_outlined,
                          tooltip: l10n.calculator,
                          label: l10n.calculator,
                          active: calculatorOpen,
                          enabled: !locked && !studyMode,
                          onTap: onCalculator,
                        ),
                        _BarIcon(
                          icon: Icons.menu_book_outlined,
                          tooltip: l10n.formulaBook,
                          label: l10n.formulaBook,
                          active: formulaBookOpen,
                          enabled: !locked && !studyMode,
                          onTap: onFormulaBook,
                        ),
                        if (onAssistant != null)
                          _BarIcon(
                            icon: Icons.auto_awesome_outlined,
                            tooltip: l10n.assistant,
                            label: l10n.assistant,
                            active: assistantOpen,
                            enabled: !locked && !studyMode,
                            onTap: onAssistant,
                          ),
                        if (onCreateDiagram != null)
                          _BarIcon(
                            icon: Icons.bar_chart_rounded,
                            tooltip: l10n.diagrams,
                            label: l10n.diagrams,
                            enabled: !locked && !studyMode,
                            onTap: onCreateDiagram,
                          ),
                        if (onOpenPacks != null)
                          _BarIcon(
                            icon: Icons.inventory_2_outlined,
                            tooltip: l10n.packsTitle,
                            label: l10n.packsTitle,
                            enabled: !locked && !studyMode,
                            onTap: onOpenPacks,
                          ),
                        _BarIcon(
                          icon: Icons.add_photo_alternate_outlined,
                          tooltip: l10n.insertImage,
                          label: l10n.insertImage,
                          active: engine.tool == InkTool.image,
                          enabled: !locked && !studyMode,
                          onTap: () {
                            engine.setTool(InkTool.image);
                            onPickImage();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _BarIcon(
                icon: Icons.post_add_rounded,
                tooltip: l10n.addPage,
                enabled: !locked && !studyMode,
                onTap: onAddPage,
              ),
              _BarIcon(
                icon: locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                tooltip: locked ? l10n.unlockPage : l10n.lockPage,
                active: locked,
                onTap: onToggleLock,
              ),
              if (studyModeUnlocked || studyMode)
                _BarIcon(
                  icon: Icons.school_outlined,
                  tooltip: l10n.studyMode,
                  label: studyMode ? l10n.studyMode : null,
                  active: studyMode,
                  onTap: onToggleStudy,
                ),
              _BarIcon(
                icon: Icons.visibility_outlined,
                tooltip: l10n.presentView,
                onTap: onPresent,
              ),
              _BarIcon(
                icon: Icons.ios_share_rounded,
                tooltip: l10n.shareExport,
                onTap: () => onMenuAction(EditorMenuAction.share),
              ),
              _BarIcon(
                icon: Icons.more_horiz_rounded,
                tooltip: l10n.moreOptions,
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
    this.activeOverride,
    this.onTapOverride,
    this.onLongPress,
  });

  final InkEngine engine;
  final InkTool tool;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool? activeOverride;
  final VoidCallback? onTapOverride;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final selected = activeOverride ?? engine.tool == tool;
    return _BarIcon(
      icon: icon,
      tooltip: selected ? AppLocalizations.of(context)!.deselectTool : label,
      label: label,
      active: selected,
      enabled: enabled,
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
    this.label,
    this.onTap,
    this.onLongPress,
    this.active = false,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final String? label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final showLabel = active && label != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            constraints: BoxConstraints(
              minWidth: showLabel ? 46 : 38,
              minHeight: 34,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 4 : 0,
              vertical: showLabel ? 2 : 0,
            ),
            decoration: BoxDecoration(
              color: active ? const Color(0x2EFFFFFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: showLabel ? 18 : 21,
                  color: enabled
                      ? (active ? EditorChrome.onDark : const Color(0xFFDCE4EE))
                      : EditorChrome.onDarkMuted.withValues(alpha: 0.45),
                ),
                if (showLabel) ...[
                  const SizedBox(height: 1),
                  Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: EditorChrome.onDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Document tabs that visually merge into the tool row below.
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
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              color: active ? EditorChrome.chip : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
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
