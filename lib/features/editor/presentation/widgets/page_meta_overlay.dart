import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/notebook.dart';
import '../../../../l10n/app_localizations.dart';

/// Title plus created / last-edited stamps drawn on the paper itself.
class PageMetaOverlay extends StatelessWidget {
  const PageMetaOverlay({
    super.key,
    required this.page,
    required this.pageNumber,
  });

  final NotePage page;
  final int pageNumber;

  static String formatStamp(DateTime? value, Locale locale) {
    if (value == null) return '';
    return DateFormat.yMMMd(locale.toString()).add_Hm().format(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final title = page.title?.trim();
    final created = formatStamp(page.createdStamp, locale);
    final edited = formatStamp(page.updatedAt, locale);
    final dates = <String>[
      if (created.isNotEmpty) l10n.pageCreatedOn(created),
      if (edited.isNotEmpty) l10n.pageEditedOn(edited),
    ].join('  ·  ');

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null && title.isNotEmpty)
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF5C564E),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              )
            else
              Text(
                l10n.pageNumberLabel(pageNumber),
                style: const TextStyle(
                  color: Color(0xFF8A847C),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const Spacer(),
            if (dates.isNotEmpty)
              Text(
                dates,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8A847C),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
