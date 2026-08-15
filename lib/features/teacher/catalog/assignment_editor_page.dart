import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../planner/education_settings.dart';
import '../teacher_models.dart';
import 'catalog_image.dart';
import 'catalog_models.dart';
import 'catalog_store.dart';

class AssignmentEditorPage extends ConsumerStatefulWidget {
  const AssignmentEditorPage({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<AssignmentEditorPage> createState() =>
      _AssignmentEditorPageState();
}

class _AssignmentEditorPageState extends ConsumerState<AssignmentEditorPage> {
  late CatalogItem _item;
  late final TextEditingController _title;
  late final TextEditingController _subject;
  late final TextEditingController _schoolClass;
  late final TextEditingController _tags;
  late final TextEditingController _duration;
  final _partControllers = <String, TextEditingController>{};
  final _optionControllers = <String, TextEditingController>{};
  final _matchControllers = <String, TextEditingController>{};
  var _missing = false;

  @override
  void initState() {
    super.initState();
    final item = ref.read(catalogProvider.notifier).byId(widget.itemId);
    if (item == null) {
      _missing = true;
      _item = CatalogItem.create(
        title: '',
        subject: '',
        schoolClass: '',
        germanState: GermanState.nw.name,
      );
      _title = TextEditingController();
      _subject = TextEditingController();
      _schoolClass = TextEditingController();
      _tags = TextEditingController();
      _duration = TextEditingController(text: '45');
      return;
    }
    _item = item;
    _title = TextEditingController(text: item.title);
    _subject = TextEditingController(text: item.subject);
    _schoolClass = TextEditingController(text: item.schoolClass);
    _tags = TextEditingController(text: item.tags.join(', '));
    _duration = TextEditingController(
      text: '${item.suggestedDurationMinutes}',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _schoolClass.dispose();
    _tags.dispose();
    _duration.dispose();
    for (final controller in _partControllers.values) {
      controller.dispose();
    }
    for (final controller in _optionControllers.values) {
      controller.dispose();
    }
    for (final controller in _matchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _textCtrl(
    Map<String, TextEditingController> map,
    String id,
    String text,
  ) {
    return map.putIfAbsent(id, () => TextEditingController(text: text));
  }

  CatalogItem _assembled() {
    return _item.copyWith(
      title: _title.text.trim(),
      subject: _subject.text.trim(),
      schoolClass: _schoolClass.text.trim(),
      tags: [
        for (final tag in _tags.text.split(','))
          if (tag.trim().isNotEmpty) tag.trim(),
      ],
      suggestedDurationMinutes: int.tryParse(_duration.text) ?? 45,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _save() async {
    final item = _assembled();
    _item = item;
    await ref.read(catalogProvider.notifier).upsert(item);
  }

  Future<void> _confirm() async {
    await _save();
    await ref.read(catalogProvider.notifier).confirm(_item.id);
    final next = ref.read(catalogProvider.notifier).byId(_item.id);
    if (next != null && mounted) setState(() => _item = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_missing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _save();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.teacherAssignments),
          actions: [
            TextButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (_item.needsReview) ...[
              Material(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.teacherReviewBanner,
                        style: AppTheme.body(),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _confirm,
                        child: Text(l10n.teacherConfirmDraft),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.title),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _subject,
              decoration: InputDecoration(labelText: l10n.subject),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _schoolClass,
              decoration: InputDecoration(labelText: l10n.schoolClass),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: GermanState.values.any(
                (s) => s.name == _item.germanState,
              )
                  ? _item.germanState
                  : GermanState.nw.name,
              decoration: InputDecoration(labelText: l10n.federalState),
              items: [
                for (final state in GermanState.values)
                  DropdownMenuItem(
                    value: state.name,
                    child: Text(state.label(l10n)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _item = _item.copyWith(germanState: value));
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<CatalogKind>(
              initialValue: _item.kind,
              decoration: InputDecoration(labelText: l10n.teacherCatalogKind),
              items: [
                DropdownMenuItem(
                  value: CatalogKind.task,
                  child: Text(l10n.teacherKindTask),
                ),
                DropdownMenuItem(
                  value: CatalogKind.test,
                  child: Text(l10n.teacherKindTest),
                ),
                DropdownMenuItem(
                  value: CatalogKind.exam,
                  child: Text(l10n.teacherKindExam),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _item = _item.copyWith(kind: value));
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<CatalogVisibility>(
              initialValue: _item.visibility,
              decoration: InputDecoration(
                labelText: l10n.teacherCatalogVisibility,
              ),
              items: [
                DropdownMenuItem(
                  value: CatalogVisibility.private,
                  child: Text(l10n.teacherVisibilityPrivate),
                ),
                DropdownMenuItem(
                  value: CatalogVisibility.school,
                  child: Text(l10n.teacherVisibilitySchool),
                ),
                DropdownMenuItem(
                  value: CatalogVisibility.public,
                  child: Text(l10n.teacherVisibilityPublic),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                final school = ref.read(teacherProvider).school;
                setState(() {
                  _item = _item.copyWith(
                    visibility: value,
                    schoolId: value == CatalogVisibility.school
                        ? school?.schoolId
                        : null,
                    clearSchoolId: value != CatalogVisibility.school,
                  );
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tags,
              decoration: InputDecoration(labelText: l10n.teacherTags),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.teacherSuggestedDuration,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.teacherTasksHeading,
              style: AppTheme.headline(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _item.tasks.length; i++) ...[
              _TaskCard(
                index: i,
                task: _item.tasks[i],
                partController: (id, text) =>
                    _textCtrl(_partControllers, id, text),
                optionController: (id, text) =>
                    _textCtrl(_optionControllers, id, text),
                matchController: (id, text) =>
                    _textCtrl(_matchControllers, id, text),
                onChanged: (task) {
                  setState(() {
                    final tasks = [..._item.tasks];
                    tasks[i] = task;
                    _item = _item.copyWith(tasks: tasks);
                  });
                },
                onDelete: _item.tasks.length <= 1
                    ? null
                    : () {
                        setState(() {
                          _item = _item.copyWith(
                            tasks: [
                              for (final task in _item.tasks)
                                if (task.id != _item.tasks[i].id) task,
                            ],
                          );
                        });
                      },
                onAddImage: () => _addImagePart(i),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _item = _item.copyWith(
                    tasks: [
                      ..._item.tasks,
                      CatalogTask.create(title: '${_item.tasks.length + 1}'),
                    ],
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.teacherAddTask),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addImagePart(int taskIndex) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    final path = await ref
        .read(catalogImportServiceProvider)
        .storePickedImage(
          itemId: _item.id,
          bytes: bytes,
          name: file.name,
        );
    setState(() {
      final tasks = [..._item.tasks];
      final task = tasks[taskIndex];
      tasks[taskIndex] = task.copyWith(
        parts: [...task.parts, TaskPart.image(path)],
      );
      _item = _item.copyWith(tasks: tasks);
    });
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.index,
    required this.task,
    required this.partController,
    required this.optionController,
    required this.matchController,
    required this.onChanged,
    required this.onDelete,
    required this.onAddImage,
  });

  final int index;
  final CatalogTask task;
  final TextEditingController Function(String id, String text) partController;
  final TextEditingController Function(String id, String text)
  optionController;
  final TextEditingController Function(String id, String text)
  matchController;
  final ValueChanged<CatalogTask> onChanged;
  final VoidCallback? onDelete;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: AppTheme.paperDeep,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.teacherTaskNumber(index + 1),
                    style: AppTheme.headline(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: l10n.teacherDeleteTask,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            TextFormField(
              initialValue: task.title,
              decoration: InputDecoration(labelText: l10n.title),
              onChanged: (value) => onChanged(task.copyWith(title: value)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: '${task.maxPoints}',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.teacherMaxPoints),
              onChanged: (value) => onChanged(
                task.copyWith(maxPoints: int.tryParse(value) ?? 1),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.teacherTaskParts, style: AppTheme.body()),
            const SizedBox(height: 8),
            for (var i = 0; i < task.parts.length; i++)
              _PartEditor(
                part: task.parts[i],
                controller: partController,
                onChanged: (part) {
                  final parts = [...task.parts];
                  parts[i] = part;
                  onChanged(task.copyWith(parts: parts));
                },
                onDelete: task.parts.length <= 1
                    ? null
                    : () {
                        onChanged(
                          task.copyWith(
                            parts: [
                              for (final part in task.parts)
                                if (part.id != task.parts[i].id) part,
                            ],
                          ),
                        );
                      },
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => onChanged(
                    task.copyWith(parts: [...task.parts, TaskPart.text('')]),
                  ),
                  icon: const Icon(Icons.notes_outlined),
                  label: Text(l10n.teacherAddPartText),
                ),
                TextButton.icon(
                  onPressed: onAddImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l10n.teacherAddPartImage),
                ),
                TextButton.icon(
                  onPressed: () => onChanged(
                    task.copyWith(parts: [...task.parts, TaskPart.link('')]),
                  ),
                  icon: const Icon(Icons.link),
                  label: Text(l10n.teacherAddPartLink),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AnswerKind>(
              initialValue: task.answerKind,
              decoration: InputDecoration(labelText: l10n.teacherAnswerKind),
              items: [
                DropdownMenuItem(
                  value: AnswerKind.text,
                  child: Text(l10n.teacherAnswerText),
                ),
                DropdownMenuItem(
                  value: AnswerKind.multipleChoice,
                  child: Text(l10n.teacherAnswerMc),
                ),
                DropdownMenuItem(
                  value: AnswerKind.calculation,
                  child: Text(l10n.teacherAnswerCalc),
                ),
                DropdownMenuItem(
                  value: AnswerKind.matching,
                  child: Text(l10n.teacherAnswerMatch),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                onChanged(
                  task.copyWith(
                    answerKind: value,
                    options: value == AnswerKind.multipleChoice &&
                            task.options.isEmpty
                        ? [McOption.create(), McOption.create()]
                        : task.options,
                    leftItems:
                        value == AnswerKind.matching && task.leftItems.isEmpty
                        ? [MatchItem.create(), MatchItem.create()]
                        : task.leftItems,
                    rightItems:
                        value == AnswerKind.matching && task.rightItems.isEmpty
                        ? [MatchItem.create(), MatchItem.create()]
                        : task.rightItems,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            if (task.answerKind == AnswerKind.text)
              TextFormField(
                initialValue: task.sampleAnswer,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(labelText: l10n.teacherSampleAnswer),
                onChanged: (value) =>
                    onChanged(task.copyWith(sampleAnswer: value)),
              ),
            if (task.answerKind == AnswerKind.calculation) ...[
              TextFormField(
                initialValue: task.calcResult,
                decoration: InputDecoration(labelText: l10n.teacherCalcResult),
                onChanged: (value) =>
                    onChanged(task.copyWith(calcResult: value)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: '${task.calcTolerance}',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.teacherCalcTolerance,
                ),
                onChanged: (value) => onChanged(
                  task.copyWith(
                    calcTolerance: double.tryParse(value.replaceAll(',', '.')) ??
                        0.01,
                  ),
                ),
              ),
            ],
            if (task.answerKind == AnswerKind.multipleChoice) ...[
              for (var i = 0; i < task.options.length; i++)
                Row(
                  children: [
                    Checkbox(
                      value: task.options[i].correct,
                      onChanged: (value) {
                        final options = [...task.options];
                        options[i] = options[i].copyWith(
                          correct: value ?? false,
                        );
                        onChanged(task.copyWith(options: options));
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: optionController(
                          task.options[i].id,
                          task.options[i].text,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.teacherCorrectOption,
                        ),
                        onChanged: (value) {
                          final options = [...task.options];
                          options[i] = options[i].copyWith(text: value);
                          onChanged(task.copyWith(options: options));
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: task.options.length <= 2
                          ? null
                          : () {
                              onChanged(
                                task.copyWith(
                                  options: [
                                    for (final option in task.options)
                                      if (option.id != task.options[i].id)
                                        option,
                                  ],
                                ),
                              );
                            },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              TextButton(
                onPressed: () => onChanged(
                  task.copyWith(options: [...task.options, McOption.create()]),
                ),
                child: Text(l10n.add),
              ),
            ],
            if (task.answerKind == AnswerKind.matching) ...[
              Text(l10n.teacherMatchLeft, style: AppTheme.body()),
              for (var i = 0; i < task.leftItems.length; i++)
                TextField(
                  controller: matchController(
                    'L${task.leftItems[i].id}',
                    task.leftItems[i].text,
                  ),
                  onChanged: (value) {
                    final items = [...task.leftItems];
                    items[i] = MatchItem(id: items[i].id, text: value);
                    onChanged(task.copyWith(leftItems: items));
                  },
                ),
              const SizedBox(height: 8),
              Text(l10n.teacherMatchRight, style: AppTheme.body()),
              for (var i = 0; i < task.rightItems.length; i++)
                TextField(
                  controller: matchController(
                    'R${task.rightItems[i].id}',
                    task.rightItems[i].text,
                  ),
                  onChanged: (value) {
                    final items = [...task.rightItems];
                    items[i] = MatchItem(id: items[i].id, text: value);
                    onChanged(task.copyWith(rightItems: items));
                  },
                ),
              const SizedBox(height: 8),
              for (var i = 0; i < task.leftItems.length; i++)
                DropdownButtonFormField<String>(
                  initialValue: () {
                    final left = task.leftItems[i].id;
                    String? rightId;
                    for (final pair in task.matchPairs) {
                      if (pair.$1 == left) rightId = pair.$2;
                    }
                    if (rightId == null) return null;
                    for (final right in task.rightItems) {
                      if (right.id == rightId) return rightId;
                    }
                    return null;
                  }(),
                  decoration: InputDecoration(
                    labelText: task.leftItems[i].text.trim().isEmpty
                        ? l10n.teacherMatchLeft
                        : task.leftItems[i].text,
                  ),
                  items: [
                    for (final right in task.rightItems)
                      DropdownMenuItem(
                        value: right.id,
                        child: Text(
                          right.text.trim().isEmpty
                              ? l10n.teacherMatchRight
                              : right.text,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    final left = task.leftItems[i].id;
                    final pairs = [
                      for (final pair in task.matchPairs)
                        if (pair.$1 != left) pair,
                      (left, value),
                    ];
                    onChanged(task.copyWith(matchPairs: pairs));
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PartEditor extends StatelessWidget {
  const _PartEditor({
    required this.part,
    required this.controller,
    required this.onChanged,
    required this.onDelete,
  });

  final TaskPart part;
  final TextEditingController Function(String id, String text) controller;
  final ValueChanged<TaskPart> onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _body(context)),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (part.kind) {
      case TaskPartKind.text:
        return TextField(
          controller: controller(part.id, part.text),
          minLines: 2,
          maxLines: 8,
          onChanged: (value) => onChanged(part.copyWith(text: value)),
        );
      case TaskPartKind.link:
        return TextField(
          controller: controller(part.id, part.url),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.link)),
          onChanged: (value) => onChanged(part.copyWith(url: value)),
        );
      case TaskPartKind.image:
        final path = part.imagePath;
        if (path == null || path.isEmpty) {
          return const SizedBox.shrink();
        }
        return CatalogImage(path: path);
    }
  }
}
