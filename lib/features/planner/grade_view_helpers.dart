import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/local_file_image.dart';
import 'school_year.dart';

/// WiSe / SoSe options for a school year, plus any extras already used.
List<String> semesterChoicesFor(
  SchoolYear year, {
  Iterable<String> extras = const [],
}) {
  final a = year.startYear % 100;
  final b = (year.startYear + 1) % 100;
  String two(int n) => n.toString().padLeft(2, '0');
  final base = <String>['WiSe ${two(a)}/${two(b)}', 'SoSe ${two(b)}'];
  final out = [...base];
  for (final e in extras) {
    final t = e.trim();
    if (t.isEmpty) continue;
    if (!out.contains(t)) out.add(t);
  }
  return out;
}

const ectsChoices = <int>[1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 20];

Widget gradeScanThumbnail(String path, {double size = 88}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: LocalFileImage(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        color: AppTheme.paperDeep,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    ),
  );
}

class GradeDetailRow extends StatelessWidget {
  const GradeDetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.body(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.body(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
