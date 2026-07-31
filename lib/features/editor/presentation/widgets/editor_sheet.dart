import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../editor_chrome.dart';

/// Opens a floating editor sheet with the shared modal configuration.
Future<T?> showEditorSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// Card-style container shared by the editor sheets.
///
/// The header stays put while the content scrolls, and the card never grows
/// past the screen, so long lists cannot overflow on small devices.
class EditorSheet extends StatelessWidget {
  const EditorSheet({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: BoxDecoration(
          color: EditorChrome.floating,
          borderRadius: BorderRadius.circular(AppTheme.radius + 10),
          border: Border.all(color: EditorChrome.floatingBorder),
          boxShadow: EditorChrome.pillShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EditorChrome.onDarkMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 2),
                child: Text(
                  title,
                  style: AppTheme.headline(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: EditorChrome.onDark,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditorSheetGroup extends StatelessWidget {
  const EditorSheetGroup(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.body(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: EditorChrome.onDarkMuted,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class EditorSheetTile extends StatelessWidget {
  const EditorSheetTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.chevron = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;

  /// Chevron marker for tiles that open another surface.
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 21, color: EditorChrome.onDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: EditorChrome.onDark,
                    ),
                  ),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sub,
                        style: AppTheme.body(
                          fontSize: 12,
                          color: EditorChrome.onDarkMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (chevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: EditorChrome.onDarkMuted,
              ),
          ],
        ),
      ),
    );
  }
}

/// Row that only reports a state the user cannot change here.
class EditorSheetInfoRow extends StatelessWidget {
  const EditorSheetInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return _SheetRow(
      icon: icon,
      label: label,
      hint: hint,
      mutedIcon: true,
      trailingBuilder: (stacked) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: EditorChrome.chip,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            value,
            style: AppTheme.body(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: EditorChrome.onDarkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class EditorSheetSegments extends StatelessWidget {
  const EditorSheetSegments({
    super.key,
    required this.icon,
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  final IconData icon;
  final String label;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _SheetRow(
      icon: icon,
      label: label,
      // Narrow screens get a full-width control instead of a cramped one.
      trailingBuilder: (stacked) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: EditorChrome.chip,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: stacked ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (var i = 0; i < options.length; i++)
              if (stacked) Expanded(child: _segment(i)) else _segment(i),
          ],
        ),
      ),
    );
  }

  Widget _segment(int index) {
    return GestureDetector(
      onTap: () => onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: index == selectedIndex
              ? EditorChrome.selected
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          options[index],
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: EditorChrome.onDark,
          ),
        ),
      ),
    );
  }
}

/// Label plus a control that moves onto its own line on narrow screens.
class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.trailingBuilder,
    this.hint,
    this.mutedIcon = false,
  });

  final IconData icon;
  final String label;

  /// Receives whether the control sits below the label.
  final Widget Function(bool stacked) trailingBuilder;
  final String? hint;
  final bool mutedIcon;

  @override
  Widget build(BuildContext context) {
    final hintText = hint;
    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: EditorChrome.onDark,
          ),
        ),
        if (hintText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Text(
              hintText,
              style: AppTheme.body(
                fontSize: 12,
                color: EditorChrome.onDarkMuted,
              ),
            ),
          ),
      ],
    );
    final leading = Icon(
      icon,
      size: 21,
      color: mutedIcon ? EditorChrome.onDarkMuted : EditorChrome.onDark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 390) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: 14),
                Expanded(child: texts),
                trailingBuilder(false),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: 14),
                  Expanded(child: texts),
                ],
              ),
              const SizedBox(height: 10),
              trailingBuilder(true),
            ],
          );
        },
      ),
    );
  }
}
