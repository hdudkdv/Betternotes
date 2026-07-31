import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../data/models/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../lan_sync/lan_sync_controller.dart';
import '../lan_sync/lan_sync_protocol.dart';
import '../library/providers/library_providers.dart';
import '../timetable/timetable_model.dart';
import 'lesson_calendar_page.dart';
import 'oer_material_repository.dart';
import 'teacher_models.dart';

Future<void> saveWhiteboardToCurrentLesson(
  BuildContext context,
  WidgetRef ref, {
  String? label,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final session = ref.read(teacherProvider).session;
  final notebookId = session?.notebookId;
  if (notebookId == null || notebookId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.teacherNoWhiteboardToSave)),
    );
    return;
  }
  final repo = ref.read(notebookRepositoryProvider);
  final pages = await repo.getPages(notebookId);
  if (pages.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherNoWhiteboardToSave)),
      );
    }
    return;
  }
  final now = DateTime.now();
  final stamp =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  final baseLabel = label ?? l10n.teacherSavedMaterialsLabel(stamp);
  final notifier = ref.read(teacherProvider.notifier);
  final timetable = ref.read(timetableProvider);
  for (final page in pages) {
    final snapshot = PageLocalSnapshot(
      id: const Uuid().v4(),
      pageId: page.id,
      notebookId: notebookId,
      label: '$baseLabel · ${page.index + 1}',
      createdAt: now,
      pageJson: jsonEncode(page.toJson()),
    );
    await repo.savePageSnapshot(snapshot);
    await notifier.attachToCurrentLesson(
      timetable: timetable,
      subject: session?.subject,
      room: session?.room,
      notebookId: notebookId,
      attachment: LessonAttachment(
        id: const Uuid().v4(),
        kind: LessonAttachmentKind.whiteboard,
        title: snapshot.label,
        createdAt: now,
        notebookId: notebookId,
        pageId: page.id,
        snapshotId: snapshot.id,
      ),
    );
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.teacherMaterialsSavedToLesson)),
    );
  }
}

class TeacherScreen extends ConsumerStatefulWidget {
  const TeacherScreen({super.key});

  @override
  ConsumerState<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends ConsumerState<TeacherScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard_rounded),
        label: l10n.teacherOverview,
      ),
      NavigationDestination(
        icon: const Icon(Icons.cast_for_education_outlined),
        selectedIcon: const Icon(Icons.cast_for_education_rounded),
        label: l10n.teacherLiveClass,
      ),
      NavigationDestination(
        icon: const Icon(Icons.calendar_month_outlined),
        selectedIcon: const Icon(Icons.calendar_month_rounded),
        label: l10n.teacherLessonCalendar,
      ),
      NavigationDestination(
        icon: const Icon(Icons.inventory_2_outlined),
        selectedIcon: const Icon(Icons.inventory_2_rounded),
        label: l10n.teacherMaterials,
      ),
      NavigationDestination(
        icon: const Icon(Icons.badge_outlined),
        selectedIcon: const Icon(Icons.badge_rounded),
        label: l10n.teacherProfile,
      ),
    ];
    final pages = [
      _Overview(onNavigate: (index) => setState(() => _index = index)),
      const _ClassroomPage(),
      const LessonCalendarPage(),
      const _MaterialsPage(),
      const _TeacherProfilePage(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 920;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teacherWorkspace),
        actions: [
          IconButton(
            tooltip: l10n.teacherAudio,
            onPressed: () => context.push('/teacher/audio'),
            icon: const Icon(Icons.mic_none_rounded),
          ),
          IconButton(
            tooltip: l10n.libraryHome,
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.auto_stories_outlined),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: Text(item.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[_index]),
              ],
            )
          : pages[_index],
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) =>
                  setState(() => _index = value),
              destinations: destinations,
            ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final teacher = ref.watch(teacherProvider);
    final active = teacher.session?.active == true;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.teacherOverviewTitle,
          style: AppTheme.headline(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.teacherOverviewHint,
          style: AppTheme.body(color: AppTheme.inkMuted),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _FeatureCard(
              icon: Icons.cast_for_education_rounded,
              title: l10n.teacherLiveClass,
              subtitle: active
                  ? l10n.teacherSessionActive(teacher.session!.code)
                  : l10n.teacherLiveClassHint,
              onTap: () => onNavigate(1),
            ),
            _FeatureCard(
              icon: Icons.calendar_month_rounded,
              title: l10n.teacherLessonCalendar,
              subtitle: l10n.teacherLessonCount(teacher.lessons.length),
              onTap: () => onNavigate(2),
            ),
            _FeatureCard(
              icon: Icons.inventory_2_rounded,
              title: l10n.teacherMaterials,
              subtitle: l10n.teacherMaterialCount(teacher.materials.length),
              onTap: () => onNavigate(3),
            ),
            _FeatureCard(
              icon: Icons.mic_rounded,
              title: l10n.teacherAudio,
              subtitle: l10n.teacherAudioHint,
              onTap: () => context.push('/teacher/audio'),
            ),
            _FeatureCard(
              icon: Icons.badge_rounded,
              title: l10n.teacherTrainee,
              subtitle: l10n.teacherTraineeHint,
              onTap: () => onNavigate(4),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 160,
      child: Card(
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppTheme.accent, size: 30),
                const Spacer(),
                Text(
                  title,
                  style: AppTheme.headline(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(
                    color: AppTheme.inkMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassroomPage extends ConsumerWidget {
  const _ClassroomPage();

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final title = TextEditingController(text: l10n.teacherNewLesson);
    final subject = TextEditingController();
    final room = TextEditingController();
    final notebooks = await ref.read(notebookRepositoryProvider).getNotebooks();
    if (!context.mounted) return;
    String? notebookId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.teacherStartSession),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: InputDecoration(labelText: l10n.title),
              ),
              TextField(
                controller: subject,
                decoration: InputDecoration(labelText: l10n.subject),
              ),
              TextField(
                controller: room,
                decoration: InputDecoration(labelText: l10n.room),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: notebookId,
                decoration: InputDecoration(
                  labelText: l10n.teacherWhiteboardNotebook,
                ),
                items: [
                  for (final notebook in notebooks)
                    DropdownMenuItem(
                      value: notebook.id,
                      child: Text(notebook.title),
                    ),
                ],
                onChanged: (value) => setState(() => notebookId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.start),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (subject.text.trim().isEmpty && room.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherSubjectOrRoomRequired)),
        );
      }
      return;
    }
    if (notebookId == null) {
      final notebook = await ref.read(notebookRepositoryProvider).createNotebook(
        title: title.text.trim().isEmpty
            ? l10n.teacherNewLesson
            : title.text.trim(),
        coverColor: 0xFF1D4E89,
      );
      notebookId = notebook.id;
    }
    final lan = ref.read(lanSyncProvider);
    await lan.startHost(
      notebookId: notebookId!,
      displayName: l10n.roleTeacher,
      classroomMode: true,
      classroomSubject: subject.text.trim(),
      classroomRoom: room.text.trim(),
    );
    await ref.read(teacherProvider.notifier).startSession(
      title: title.text.trim().isEmpty ? l10n.teacherNewLesson : title.text,
      notebookId: notebookId,
      code: lan.sessionCode,
      subject: subject.text.trim(),
      room: room.text.trim(),
    );
  }

  Future<void> _addParticipant(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.teacherAddParticipant),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(teacherProvider.notifier)
          .addDemoParticipant(controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lan = ref.watch(lanSyncProvider);
    ref.listen<int>(
      lanSyncProvider.select((controller) => controller.classroomSignalSeq),
      (previous, next) {
        final signal = ref.read(lanSyncProvider).lastClassroomSignal;
        if (signal == null) return;
        ref.read(teacherProvider.notifier).applyNetworkSignal(
          deviceId: signal.deviceId,
          deviceName: signal.deviceName,
          kind: signal.kind,
          value: signal.value,
        );
      },
    );
    final session = ref.watch(teacherProvider).session;
    if (session == null || !session.active) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cast_for_education_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                l10n.teacherNoActiveSession,
                style: AppTheme.headline(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.teacherLiveClassHint,
                textAlign: TextAlign.center,
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _start(context, ref),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.teacherStartSession),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: AppTheme.accentSoft,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 20,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: AppTheme.headline(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.teacherJoinCode(session.code),
                      style: AppTheme.body(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      [session.subject, session.room]
                          .where((value) => value.isNotEmpty)
                          .join(' · '),
                      style: AppTheme.body(color: AppTheme.inkMuted),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (session.notebookId != null)
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            context.push('/notebook/${session.notebookId}'),
                        icon: const Icon(Icons.draw_outlined),
                        label: Text(l10n.teacherOpenWhiteboard),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          saveWhiteboardToCurrentLesson(context, ref),
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: Text(l10n.teacherSaveLessonMaterials),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await saveWhiteboardToCurrentLesson(
                          context,
                          ref,
                          label: l10n.teacherWhiteboardFinal,
                        );
                        await ref.read(lanSyncProvider).stop();
                        await ref.read(teacherProvider.notifier).endSession();
                      },
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(l10n.teacherEndSession),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: l10n.teacherParticipants,
                value: '${session.participants.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: l10n.teacherAverageProgress,
                value: '${session.averageProgress.round()} %',
              ),
            ),
          ],
        ),
        SwitchListTile(
          value: session.focusCheckEnabled,
          onChanged: (value) async {
            await ref.read(teacherProvider.notifier).setFocusCheck(value);
            await ref.read(lanSyncProvider).setClassroomFocusCheck(value);
          },
          title: Text(l10n.teacherFocusCheck),
          subtitle: Text(l10n.teacherFocusCheckPrivacy),
          secondary: const Icon(Icons.visibility_outlined),
        ),
        Row(
          children: [
            Text(
              l10n.teacherParticipants,
              style: AppTheme.headline(fontSize: 19),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addParticipant(context, ref),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.teacherAddParticipant),
            ),
          ],
        ),
        if (session.participants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(
              l10n.teacherWaitingParticipants,
              textAlign: TextAlign.center,
              style: AppTheme.body(color: AppTheme.inkMuted),
            ),
          )
        else
          for (final participant in session.participants)
            _ParticipantTile(participant: participant, lan: lan),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              value,
              style: AppTheme.headline(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends ConsumerWidget {
  const _ParticipantTile({required this.participant, required this.lan});
  final ClassroomParticipant participant;
  final LanSyncController lan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(teacherProvider.notifier);
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(child: Text(participant.name.characters.first)),
            if (!participant.focused)
              const Positioned(
                right: -4,
                bottom: -4,
                child: Icon(Icons.warning_amber_rounded, size: 18),
              ),
          ],
        ),
        title: Text(participant.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: participant.progress / 100),
            const SizedBox(height: 3),
            Text(
              participant.focused
                  ? l10n.teacherFocused
                  : l10n.teacherLeftApp,
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: l10n.teacherAllowWriting,
              onPressed: () => notifier.updateParticipant(
                    participant.id,
                    canWrite: !participant.canWrite,
                  )
                  .then(
                    (_) => lan.setPeerClassroomPermissions(
                      deviceId: participant.id,
                      canWrite: !participant.canWrite,
                    ),
                  ),
              icon: Icon(
                participant.canWrite ? Icons.edit : Icons.edit_off_outlined,
              ),
            ),
            IconButton(
              tooltip: l10n.teacherMute,
              onPressed: () => notifier.updateParticipant(
                    participant.id,
                    muted: !participant.muted,
                  )
                  .then(
                    (_) => lan.setPeerClassroomPermissions(
                      deviceId: participant.id,
                      muted: !participant.muted,
                    ),
                  ),
              icon: Icon(
                participant.muted
                    ? Icons.volume_off_outlined
                    : Icons.volume_up_outlined,
              ),
            ),
            SizedBox(
              width: 90,
              child: Slider(
                value: participant.progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 10,
                onChanged: (value) => notifier.updateParticipant(
                  participant.id,
                  progress: value.round(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialsPage extends ConsumerStatefulWidget {
  const _MaterialsPage();

  @override
  ConsumerState<_MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends ConsumerState<_MaterialsPage> {
  String _query = '';

  Future<void> _distribute(TeacherMaterial material) async {
    final l10n = AppLocalizations.of(context)!;
    final lan = ref.read(lanSyncProvider);
    if (!lan.classroomMode || lan.role != LanSyncRole.host || !lan.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherStartClassBeforeDistribute)),
      );
      return;
    }
    try {
      var url = material.cloudUrl;
      if (url == null || url.isEmpty) {
        final path = material.localPath;
        if (path == null || path.isEmpty || kIsWeb) {
          throw StateError('missing_file');
        }
        final bytes = await File(path).readAsBytes();
        url = await ref.read(oerMaterialRepositoryProvider).uploadPrivate(
          bytes: bytes,
          fileName: material.title,
        );
      }
      await lan.distributeClassroomMaterial(
        url: url,
        title: material.title,
      );
      final session = ref.read(teacherProvider).session;
      await ref.read(teacherProvider.notifier).attachToCurrentLesson(
        timetable: ref.read(timetableProvider),
        subject: session?.subject,
        room: session?.room,
        notebookId: session?.notebookId,
        attachment: LessonAttachment(
          id: const Uuid().v4(),
          kind: LessonAttachmentKind.material,
          title: material.title,
          createdAt: DateTime.now(),
          materialId: material.id,
          url: url,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherDistributionSent)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherOerSignInRequired)),
        );
      }
    }
  }

  Future<void> _add() async {
    final result = await FilePicker.pickFiles(withData: true);
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.first;
    final l10n = AppLocalizations.of(context)!;
    final subject = TextEditingController();
    final grade = TextEditingController();
    final duration = TextEditingController(text: '45');
    var submitToCommunity = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.teacherAddMaterial),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(file.name),
              TextField(
                controller: subject,
                decoration: InputDecoration(labelText: l10n.subject),
              ),
              TextField(
                controller: grade,
                decoration: InputDecoration(labelText: l10n.schoolClass),
              ),
              TextField(
                controller: duration,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.teacherDurationMinutes,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: submitToCommunity,
                onChanged: (value) => setDialogState(
                  () => submitToCommunity = value ?? false,
                ),
                title: Text(l10n.teacherSubmitOer),
                subtitle: Text(l10n.teacherSubmitOerHint),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(teacherProvider.notifier).addMaterial(
      TeacherMaterial(
        id: const Uuid().v4(),
        title: file.name,
        subject: subject.text.trim(),
        grade: grade.text.trim(),
        durationMinutes: int.tryParse(duration.text) ?? 45,
        localPath: file.path,
      ),
    );
    if (submitToCommunity) {
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.teacherOerUploadUnavailable)),
          );
        }
        return;
      }
      try {
        await ref.read(oerMaterialRepositoryProvider).submit(
          bytes: bytes,
          fileName: file.name,
          title: file.name,
          subject: subject.text.trim(),
          grade: grade.text.trim(),
          germanState: 'Alle',
          durationMinutes: int.tryParse(duration.text) ?? 45,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.teacherOerSubmitted)),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.teacherOerSignInRequired)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localMaterials = ref.watch(teacherProvider).materials;
    final cloudMaterials =
        ref.watch(approvedOerMaterialsProvider).valueOrNull ?? const [];
    final materials = [...localMaterials, ...cloudMaterials]
        .where(
          (item) =>
              _query.isEmpty ||
              item.title.toLowerCase().contains(_query.toLowerCase()) ||
              item.subject.toLowerCase().contains(_query.toLowerCase()) ||
              item.grade.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.teacherMaterialSearch,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: AppTheme.accentSoft,
            child: ListTile(
              leading: const Icon(Icons.cloud_sync_outlined),
              title: Text(l10n.teacherHybridDistribution),
              subtitle: Text(l10n.teacherHybridDistributionHint),
            ),
          ),
          if (materials.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                l10n.teacherNoMaterials,
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final material in materials)
              Card(
                elevation: 0,
                child: ListTile(
                  leading: Icon(
                    material.isOer
                        ? Icons.public_outlined
                        : Icons.description_outlined,
                  ),
                  title: Text(material.title),
                  subtitle: Text(
                    '${material.subject} · ${material.grade} · '
                    '${material.durationMinutes} min · ${material.germanState}',
                  ),
                  trailing: IconButton(
                    tooltip: l10n.teacherDistribute,
                    onPressed: () => _distribute(material),
                    icon: const Icon(Icons.send_outlined),
                  ),
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.upload_file_outlined),
        label: Text(l10n.teacherAddMaterial),
      ),
    );
  }
}

class _TeacherProfilePage extends ConsumerWidget {
  const _TeacherProfilePage();

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null) return;
    await ref
        .read(teacherProvider.notifier)
        .setTraineeVerification(TraineeVerification.pending);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(teacherProvider).traineeVerification;
    final label = switch (status) {
      TraineeVerification.none => l10n.teacherVerificationNone,
      TraineeVerification.pending => l10n.teacherVerificationPending,
      TraineeVerification.verified => l10n.teacherVerificationVerified,
      TraineeVerification.rejected => l10n.teacherVerificationRejected,
    };
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.teacherProfile,
          style: AppTheme.headline(fontSize: 26),
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(l10n.teacherTrainee),
            subtitle: Text('${l10n.teacherVerificationStatus}: $label'),
            trailing: status == TraineeVerification.pending
                ? const CircularProgressIndicator()
                : FilledButton.tonal(
                    onPressed: () => _submit(context, ref),
                    child: Text(l10n.teacherSubmitProof),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.teacherVerificationPrivacy,
          style: AppTheme.body(color: AppTheme.inkMuted),
        ),
      ],
    );
  }
}
