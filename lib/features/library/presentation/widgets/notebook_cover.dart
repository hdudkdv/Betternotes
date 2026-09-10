import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/content_models.dart';
import '../../../../data/models/notebook.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../editor/presentation/page_preview_cache.dart';
import '../../../auth/auth_repository.dart';
import '../../../entitlements/entitlement_model.dart';
import '../../../lan_sync/lan_sync_controller.dart';
import '../../../sync/cloud_sync_selection.dart';
import '../../live_folder.dart';
import '../../providers/library_providers.dart';

class NotebookCover extends ConsumerWidget {
  const NotebookCover({
    super.key,
    required this.notebook,
    required this.onOpen,
    required this.onFavorite,
    required this.onRename,
    required this.onDelete,
    this.onLink,
    this.onCloudSync,
  });

  final Notebook notebook;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onLink;
  final VoidCallback? onCloudSync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.watch(authProvider).user?.uid;
    final lockedOut = notebook.isLockedFor(uid);
    final lan = ref.watch(lanSyncProvider);
    final grant = lan.guestGrantFor(notebook.id);
    final sharedBy = grant?.hostLabel;
    final liveNow =
        notebook.folderId == kLiveFolderId ||
        (lan.isActive && lan.notebookId == notebook.id);
    final paid = ref.watch(entitlementProvider).paidTier;
    final cloudOn = ref
        .watch(cloudSyncSelectionProvider)
        .isSynced(notebook.id, paid);
    final radius = BorderRadius.circular(18);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: lockedOut
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.accountNotebookLocked)),
                      );
                    }
                  : onOpen,
              borderRadius: radius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppTheme.isDark ? 0.45 : 0.16,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Builder(
                        builder: (context) {
                          final preview = ColoredBox(
                            color: const Color(0xFFF4EFE6),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _FirstPagePreview(notebook: notebook),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 8,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(notebook.coverColor),
                                            Color(
                                              notebook.coverColor,
                                            ).withValues(alpha: 0.28),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (!lockedOut) return preview;
                          return ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ]),
                            child: preview,
                          );
                        },
                      ),
                      if (lockedOut)
                        const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 40,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                      if (liveNow || notebook.canvasMode == CanvasMode.infinite)
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Row(
                            children: [
                              if (liveNow)
                                _CoverBadge(
                                  label: l10n.liveNow,
                                  color: const Color(0xFF0F6E56),
                                ),
                              if (liveNow &&
                                  notebook.canvasMode == CanvasMode.infinite)
                                const SizedBox(width: 6),
                              if (notebook.canvasMode == CanvasMode.infinite)
                                _CoverBadge(
                                  label: l10n.infiniteDocument,
                                  icon: Icons.all_out,
                                  color: Colors.black.withValues(alpha: 0.55),
                                ),
                            ],
                          ),
                        ),
                      if (!lockedOut)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _CoverIconButton(
                            onPressed: onFavorite,
                            icon: Icon(
                              notebook.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: notebook.isFavorite
                                  ? const Color(0xFFF5C518)
                                  : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: lockedOut
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.accountNotebookLocked)),
                        );
                      }
                    : onOpen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notebook.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headline(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        l10n.pageCount(notebook.pageCount),
                        if (sharedBy != null && sharedBy.isNotEmpty)
                          l10n.sharedByHost(sharedBy),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                        color: AppTheme.inkMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!lockedOut)
              PopupMenuButton<String>(
                tooltip: l10n.moreOptions,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_horiz_rounded, color: AppTheme.inkMuted),
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                  if (value == 'link') onLink?.call();
                  if (value == 'cloud') onCloudSync?.call();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                  if (onLink != null)
                    PopupMenuItem(value: 'link', child: Text(l10n.crossLink)),
                  if (onCloudSync != null && paid == PaidTier.lite)
                    PopupMenuItem(
                      value: 'cloud',
                      child: Text(
                        cloudOn
                            ? l10n.cloudSyncThisNotebookOff
                            : l10n.cloudSyncThisNotebook,
                      ),
                    ),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTheme.body(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverIconButton extends StatelessWidget {
  const _CoverIconButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 36, height: 36, child: Center(child: icon)),
      ),
    );
  }
}

class _FirstPagePreview extends ConsumerWidget {
  const _FirstPagePreview({required this.notebook});

  final Notebook notebook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(firstPageProvider(notebook.id));
    return pageAsync.when(
      data: (page) {
        if (page == null) return const SizedBox.expand();
        return _CachedPageImage(page: page);
      },
      loading: () => const SizedBox.expand(),
      error: (_, _) => const SizedBox.expand(),
    );
  }
}

class _CachedPageImage extends StatefulWidget {
  const _CachedPageImage({required this.page});

  final NotePage page;

  @override
  State<_CachedPageImage> createState() => _CachedPageImageState();
}

class _CachedPageImageState extends State<_CachedPageImage> {
  late ValueNotifier<ui.Image?> _listenable;

  @override
  void initState() {
    super.initState();
    _listenable = PagePreviewCache.instance.listenableFor(widget.page.id);
    _warm();
  }

  @override
  void didUpdateWidget(covariant _CachedPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id ||
        PagePreviewCache.revisionOf(oldWidget.page) !=
            PagePreviewCache.revisionOf(widget.page)) {
      _listenable = PagePreviewCache.instance.listenableFor(widget.page.id);
      _warm();
    }
  }

  void _warm() {
    final cached = PagePreviewCache.instance.get(widget.page);
    if (cached != null) {
      _listenable.value = cached;
      return;
    }
    PagePreviewCache.instance.ensure(widget.page);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ui.Image?>(
      valueListenable: _listenable,
      builder: (context, image, _) {
        if (image == null) return const SizedBox.expand();
        return RawImage(
          image: image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}
