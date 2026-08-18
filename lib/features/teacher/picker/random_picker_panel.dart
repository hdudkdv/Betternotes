import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../lan_sync/lan_sync_controller.dart';
import '../../lan_sync/lan_sync_protocol.dart';
import '../gradebook/gradebook_models.dart';
import '../gradebook/gradebook_store.dart';
import '../teacher_models.dart';
import 'random_pick.dart';

class RandomPickerPanel extends ConsumerStatefulWidget {
  const RandomPickerPanel({
    super.key,
    this.initialClassName,
  });

  final String? initialClassName;

  @override
  ConsumerState<RandomPickerPanel> createState() => _RandomPickerPanelState();
}

class _RandomPickerPanelState extends ConsumerState<RandomPickerPanel> {
  Timer? _flashTimer;
  String? _flashName;
  String? _flashDetail;
  bool _flashConnected = false;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  List<({String id, String name})> _peers() {
    final session = ref.read(teacherProvider).session;
    return [
      for (final p in session?.participants ?? const <ClassroomParticipant>[])
        (id: p.id, name: p.name),
    ];
  }

  List<RosterStudent> _pool(SavedPicker picker, TeacherClassRoster? roster) {
    if (picker.connectedOnly) {
      return [
        for (final peer in _peers())
          roster?.students.firstWhereOrNull(
                (s) => classroomNamesMatch(s.name, peer.name),
              ) ??
              RosterStudent(id: 'peer:${peer.id}', name: peer.name),
      ];
    }
    if (roster == null) return const [];
    if (picker.groupId != null) {
      final group = roster.groups.where((g) => g.id == picker.groupId).firstOrNull;
      if (group != null) return roster.studentsInGroup(group);
    }
    return roster.students;
  }

  Future<void> _drawPerson(SavedPicker picker) async {
    final l10n = AppLocalizations.of(context)!;
    final roster = ref.read(gradebookProvider).classById(picker.classId);
    final pool = _pool(picker, roster);
    final remaining = picker.isDatacheck
        ? poolWithoutRepeat(
            pool: pool,
            drawnIds: picker.drawnIds.toSet(),
            resetWhenEmpty: false,
          )
        : pool;
    final picked = pickRandomItem(remaining);
    if (picked == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              picker.isDatacheck && pool.isNotEmpty
                  ? l10n.teacherPickerRoundDone
                  : l10n.teacherPickerEmpty,
            ),
          ),
        );
      }
      return;
    }
    final groupName = roster?.groups
        .where((g) => g.id == picker.groupId)
        .map((g) => g.name)
        .firstOrNull;
    final payload = pickToClassroomPick(
      kind: 'student',
      name: picked.name,
      groupName: groupName,
      peers: _peers(),
      sticky: picker.isDatacheck,
    );
    await ref.read(lanSyncProvider).broadcastClassroomPick(payload);
    if (picker.isDatacheck) {
      await ref.read(gradebookProvider.notifier).recordPickerDraw(
        pickerId: picker.id,
        drawnId: picked.id,
        lastName: picked.name,
        lastDetail: groupName,
      );
    } else {
      _startFlash(picked.name, groupName, payload.deviceId != null);
    }
  }

  Future<void> _drawGroup(SavedPicker picker) async {
    final l10n = AppLocalizations.of(context)!;
    final roster = ref.read(gradebookProvider).classById(picker.classId);
    if (roster == null || roster.groups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherPickerNoGroups)),
        );
      }
      return;
    }
    final group = pickRandomItem(roster.groups);
    if (group == null) return;
    final members = roster.studentsInGroup(group);
    final payload = pickToClassroomPick(
      kind: 'group',
      name: group.name,
      groupName: group.name,
      members: members,
      peers: _peers(),
      sticky: picker.isDatacheck,
    );
    await ref.read(lanSyncProvider).broadcastClassroomPick(payload);
    final detail = members.map((s) => s.name).join(' · ');
    if (picker.isDatacheck) {
      await ref.read(gradebookProvider.notifier).recordPickerDraw(
        pickerId: picker.id,
        drawnId: 'group:${group.id}',
        lastName: group.name,
        lastDetail: detail,
      );
    } else {
      _startFlash(group.name, detail, payload.memberDeviceIds.isNotEmpty);
    }
  }

  void _startFlash(String name, String? detail, bool connected) {
    _flashTimer?.cancel();
    setState(() {
      _flashName = name;
      _flashDetail = detail;
      _flashConnected = connected;
    });
    _flashTimer = Timer(const Duration(seconds: 3), () async {
      await ref.read(lanSyncProvider).clearClassroomPick();
      if (mounted) {
        setState(() {
          _flashName = null;
          _flashDetail = null;
        });
      }
    });
  }

  Future<void> _createPicker() async {
    final book = ref.read(gradebookProvider);
    var classId = book.activePicker?.classId ??
        book.classByName(widget.initialClassName ?? '')?.id ??
        (book.classes.isNotEmpty ? book.classes.first.id : null);
    if (classId == null) {
      final created = await _promptNewClass();
      classId = created?.id;
      if (classId == null) return;
    }
    if (!mounted) return;
    final result = await showDialog<_NewPicker>(
      context: context,
      builder: (context) => _NewPickerDialog(
        classes: ref.read(gradebookProvider).classes,
        initialClassId: classId!,
      ),
    );
    if (result == null) return;
    await ref.read(gradebookProvider.notifier).addPicker(
      name: result.name,
      classId: result.classId,
      kind: result.kind,
    );
  }

  Future<TeacherClassRoster?> _promptNewClass() async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _prompt(
      context,
      title: l10n.timetableNewClass,
      hint: l10n.timetableClassHint,
    );
    if (name == null) return null;
    return ref.read(gradebookProvider.notifier).ensureClass(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final book = ref.watch(gradebookProvider);
    final lan = ref.watch(lanSyncProvider);
    final session = ref.watch(teacherProvider).session;
    final live =
        lan.classroomMode && lan.role == LanSyncRole.host && lan.peerCount > 0;
    final picker = book.activePicker;
    final roster = picker == null ? null : book.classById(picker.classId);
    final pool = picker == null ? const <RosterStudent>[] : _pool(picker, roster);
    final remaining = picker == null
        ? 0
        : poolWithoutRepeat(
            pool: pool,
            drawnIds: picker.drawnIds.toSet(),
            resetWhenEmpty: false,
          ).length;
    final connected = session?.participants.length ?? 0;
    final resultName = picker?.isDatacheck == true
        ? picker!.lastName
        : _flashName;
    final resultDetail = picker?.isDatacheck == true
        ? picker!.lastDetail
        : _flashDetail;
    final resultConnected = picker?.isFlash == true && _flashConnected;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teacherPickerTitle,
              style: AppTheme.headline(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.teacherPickerSavedHint,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in book.pickers)
                  InputChip(
                    selected: item.id == picker?.id,
                    label: Text(item.name),
                    avatar: Icon(
                      item.isDatacheck
                          ? Icons.checklist_outlined
                          : Icons.flash_on_outlined,
                      size: 18,
                    ),
                    onPressed: () =>
                        ref.read(gradebookProvider.notifier).selectPicker(item.id),
                    onDeleted: () =>
                        ref.read(gradebookProvider.notifier).deletePicker(item.id),
                    tooltip: l10n.teacherPickerDelete,
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(l10n.teacherPickerNew),
                  onPressed: _createPicker,
                ),
              ],
            ),
            if (picker == null) ...[
              const SizedBox(height: 16),
              Text(
                l10n.teacherPickerNone,
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                picker.isDatacheck
                    ? l10n.teacherPickerKindDatacheckHint
                    : l10n.teacherPickerKindFlashHint,
                style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (book.classes.isNotEmpty)
                    DropdownButton<String>(
                      value: book.classById(picker.classId)?.id ??
                          book.classes.first.id,
                      borderRadius: BorderRadius.circular(12),
                      items: [
                        for (final item in book.classes)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        ref.read(gradebookProvider.notifier).updatePicker(
                          picker.copyWith(classId: value, clearGroup: true),
                        );
                      },
                    ),
                  DropdownButton<String?>(
                    value: roster?.groups.any((g) => g.id == picker.groupId) == true
                        ? picker.groupId
                        : null,
                    hint: Text(l10n.teacherPickerWholeClass),
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.teacherPickerWholeClass),
                      ),
                      for (final group in roster?.groups ?? const <ClassGroup>[])
                        DropdownMenuItem<String?>(
                          value: group.id,
                          child: Text(group.name),
                        ),
                    ],
                    onChanged: (value) =>
                        ref.read(gradebookProvider.notifier).updatePicker(
                          picker.copyWith(
                            groupId: value,
                            clearGroup: value == null,
                            drawnIds: const [],
                            clearLast: true,
                          ),
                        ),
                  ),
                  FilterChip(
                    selected: picker.connectedOnly,
                    label: Text(l10n.teacherPickerConnectedOnly),
                    onSelected: (on) =>
                        ref.read(gradebookProvider.notifier).updatePicker(
                          picker.copyWith(connectedOnly: on),
                        ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.groups_outlined, size: 18),
                    label: Text(l10n.teacherPickerGroups),
                    onPressed: () async {
                      var current = roster;
                      current ??= await _promptNewClass();
                      if (current == null || !context.mounted) return;
                      await showClassGroupsSheet(context, ref, current);
                    },
                  ),
                ],
              ),
              if (live || connected > 0) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.teacherPickerConnectedCount(connected, pool.length),
                  style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
                ),
              ],
              if (picker.isDatacheck && pool.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  remaining == 0
                      ? l10n.teacherPickerRoundDone
                      : l10n.teacherPickerProgress(
                          pool.length - remaining,
                          pool.length,
                        ),
                  style: AppTheme.body(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: pool.isEmpty ? 0 : (pool.length - remaining) / pool.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: remaining == 0 && picker.isDatacheck
                        ? null
                        : () => _drawPerson(picker),
                    icon: Icon(
                      picker.isDatacheck
                          ? Icons.skip_next_rounded
                          : Icons.casino_outlined,
                    ),
                    label: Text(
                      picker.isDatacheck
                          ? l10n.teacherPickerNext
                          : l10n.teacherPickerDrawPerson,
                    ),
                  ),
                  if (picker.isFlash)
                    FilledButton.tonalIcon(
                      onPressed: () => _drawGroup(picker),
                      icon: const Icon(Icons.group_outlined),
                      label: Text(l10n.teacherPickerDrawGroup),
                    ),
                  if (picker.isDatacheck)
                    TextButton(
                      onPressed: () => ref
                          .read(gradebookProvider.notifier)
                          .resetPickerRound(picker.id),
                      child: Text(l10n.teacherPickerResetRound),
                    ),
                  if (resultName != null || lan.classroomPick != null)
                    TextButton(
                      onPressed: () async {
                        _flashTimer?.cancel();
                        await ref.read(lanSyncProvider).clearClassroomPick();
                        if (mounted) {
                          setState(() {
                            _flashName = null;
                            _flashDetail = null;
                          });
                        }
                      },
                      child: Text(l10n.teacherPickerClear),
                    ),
                ],
              ),
              if (resultName != null) ...[
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.accentSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text(
                          resultName,
                          textAlign: TextAlign.center,
                          style: AppTheme.headline(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (resultDetail != null && resultDetail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            resultDetail,
                            textAlign: TextAlign.center,
                            style: AppTheme.body(color: AppTheme.inkMuted),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          resultConnected && live
                              ? l10n.teacherPickerShownOnDevice
                              : picker.isDatacheck
                                  ? l10n.teacherPickerDatacheckStay
                                  : l10n.teacherPickerNotConnected,
                          textAlign: TextAlign.center,
                          style: AppTheme.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _NewPicker {
  const _NewPicker({
    required this.name,
    required this.classId,
    required this.kind,
  });

  final String name;
  final String classId;
  final SavedPickerKind kind;
}

class _NewPickerDialog extends StatefulWidget {
  const _NewPickerDialog({
    required this.classes,
    required this.initialClassId,
  });

  final List<TeacherClassRoster> classes;
  final String initialClassId;

  @override
  State<_NewPickerDialog> createState() => _NewPickerDialogState();
}

class _NewPickerDialogState extends State<_NewPickerDialog> {
  late final TextEditingController _name;
  late String _classId;
  var _kind = SavedPickerKind.datacheck;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _classId = widget.initialClassId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.teacherPickerNew),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.teacherPickerName,
              hintText: l10n.teacherPickerNameHint,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _classId,
            decoration: InputDecoration(labelText: l10n.schoolClass),
            items: [
              for (final item in widget.classes)
                DropdownMenuItem(value: item.id, child: Text(item.name)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _classId = value);
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<SavedPickerKind>(
            segments: [
              ButtonSegment(
                value: SavedPickerKind.datacheck,
                label: Text(l10n.teacherPickerKindDatacheck),
                icon: const Icon(Icons.checklist_outlined),
              ),
              ButtonSegment(
                value: SavedPickerKind.flash,
                label: Text(l10n.teacherPickerKindFlash),
                icon: const Icon(Icons.flash_on_outlined),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (value) => setState(() => _kind = value.first),
          ),
          const SizedBox(height: 8),
          Text(
            _kind == SavedPickerKind.datacheck
                ? l10n.teacherPickerKindDatacheckHint
                : l10n.teacherPickerKindFlashHint,
            style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              _NewPicker(name: name, classId: _classId, kind: _kind),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

Future<void> showClassGroupsSheet(
  BuildContext context,
  WidgetRef ref,
  TeacherClassRoster roster,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _GroupsSheet(classId: roster.id),
  );
}

class _GroupsSheet extends ConsumerWidget {
  const _GroupsSheet({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roster = ref.watch(gradebookProvider).classById(classId);
    if (roster == null) return const SizedBox.shrink();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teacherPickerGroups,
              style: AppTheme.headline(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () async {
                final name = await _prompt(
                  context,
                  title: l10n.teacherPickerNewGroup,
                  hint: l10n.teacherPickerGroupName,
                );
                if (name == null) return;
                await ref.read(gradebookProvider.notifier).addGroup(classId, name);
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.teacherPickerNewGroup),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: roster.groups.isEmpty
                  ? Center(
                      child: Text(
                        l10n.teacherPickerNoGroups,
                        style: AppTheme.body(color: AppTheme.inkMuted),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final group in roster.groups)
                          ExpansionTile(
                            title: Text(group.name),
                            subtitle: Text(
                              l10n.teacherPickerGroupCount(group.studentIds.length),
                            ),
                            trailing: IconButton(
                              tooltip: l10n.delete,
                              onPressed: () => ref
                                  .read(gradebookProvider.notifier)
                                  .deleteGroup(classId, group.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                            children: [
                              for (final student in roster.students)
                                CheckboxListTile(
                                  value: group.studentIds.contains(student.id),
                                  title: Text(student.name),
                                  onChanged: (on) {
                                    final next = [
                                      for (final id in group.studentIds)
                                        if (id != student.id) id,
                                      if (on == true) student.id,
                                    ];
                                    ref.read(gradebookProvider.notifier).setGroupMembers(
                                      classId: classId,
                                      groupId: group.id,
                                      studentIds: next,
                                    );
                                  },
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _prompt(
  BuildContext context, {
  required String title,
  required String hint,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  final value = controller.text.trim();
  controller.dispose();
  if (ok == true && value.isNotEmpty) return value;
  return null;
}
