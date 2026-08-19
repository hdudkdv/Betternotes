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
    final liveNow = notebook.folderId == kLiveFolderId ||
        (lan.isActive && lan.notebookId == notebook.id);
    final paid = ref.watch(entitlementProvider).paidTier;
    final cloudOn = ref.watch(cloudSyncSelectionProvider).isSynced(
          notebook.id,
          paid,
        );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: lockedOut
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.accountNotebookLocked)),
                );
              }
            : onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Builder(
                      builder: (context) {
                        final preview = DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4EFE6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _FirstPagePreview(notebook: notebook),
                        );
                        if (!lockedOut) return preview;
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                          child: preview,
                        );
                      },
                    ),
                  ),
                  if (lockedOut)
                    const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 42,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(18),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.62),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (liveNow)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F6E56)
                                      .withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l10n.liveNow,
                                  style: AppTheme.body(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            if (notebook.canvasMode == CanvasMode.infinite)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.all_out,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.infiniteDocument,
                                      style: AppTheme.body(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              notebook.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.headline(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: lockedOut
                        ? const SizedBox.shrink()
                        : Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onFavorite,
                          icon: Icon(
                            notebook.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                          onSelected: (value) {
                            if (value == 'rename') onRename();
                            if (value == 'delete') onDelete();
                            if (value == 'link') onLink?.call();
                            if (value == 'cloud') onCloudSync?.call();
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text(l10n.rename),
                            ),
                            if (onLink != null)
                              PopupMenuItem(
                                value: 'link',
                                child: Text(l10n.crossLink),
                              ),
                            if (onCloudSync != null && paid == PaidTier.lite)
                              PopupMenuItem(
                                value: 'cloud',
                                child: Text(
                                  cloudOn
                                      ? l10n.cloudSyncThisNotebookOff
                                      : l10n.cloudSyncThisNotebook,
                                ),
                              ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.pageCount(notebook.pageCount),
              style: AppTheme.body(
                color: AppTheme.inkMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
