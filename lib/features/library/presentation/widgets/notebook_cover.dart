import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/content_models.dart';
import '../../../../data/models/notebook.dart';
import '../../../../l10n/app_localizations.dart';

class NotebookCover extends StatelessWidget {
  const NotebookCover({
    super.key,
    required this.notebook,
    required this.onOpen,
    required this.onFavorite,
    required this.onRename,
    required this.onDelete,
    this.onLink,
  });

  final Notebook notebook;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(notebook.coverColor),
                          Color(notebook.coverColor).withValues(alpha: 0.75),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(
                            notebook.coverColor,
                          ).withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (notebook.canvasMode == CanvasMode.infinite)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
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
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onFavorite,
                          icon: Icon(
                            notebook.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.white,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                          ),
                          onSelected: (value) {
                            if (value == 'rename') onRename();
                            if (value == 'delete') onDelete();
                            if (value == 'link') onLink?.call();
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
