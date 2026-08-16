import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

class TeacherAudioScreen extends ConsumerWidget {
  const TeacherAudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.teacherRecordings)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            l10n.webAudioUnavailable,
            textAlign: TextAlign.center,
            style: AppTheme.body(color: AppTheme.inkMuted),
          ),
        ),
      ),
    );
  }
}
