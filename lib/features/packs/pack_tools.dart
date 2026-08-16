import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/models/content_models.dart';
import '../entitlements/entitlement_model.dart';
import '../library/providers/library_providers.dart';
import '../tools/charts/chart_builder.dart';
import 'pack_render.dart';
import 'pack_store.dart';

class PackToolHost extends StatelessWidget {
  const PackToolHost({
    super.key,
    required this.packKey,
    required this.toolIndex,
    required this.notebookId,
    required this.store,
    required this.german,
    required this.onInsert,
  });

  final String packKey;
  final int toolIndex;
  final String notebookId;
  final PackStore store;
  final bool german;
  final ValueChanged<Uint8List> onInsert;

  @override
  Widget build(BuildContext context) {
    return switch (packKey) {
      FeatureKeys.packDev => _DevTools(
        index: toolIndex,
        notebookId: notebookId,
        store: store,
        german: german,
        onInsert: onInsert,
      ),
      FeatureKeys.packEdu => _EduTools(
        index: toolIndex,
        notebookId: notebookId,
        german: german,
        onInsert: onInsert,
      ),
      FeatureKeys.packRpg => _RpgTools(
        index: toolIndex,
        german: german,
        onInsert: onInsert,
      ),
      FeatureKeys.packCulinary => _CulinaryTools(
        index: toolIndex,
        german: german,
        onInsert: onInsert,
      ),
      FeatureKeys.packAgile => _AgileTools(
        index: toolIndex,
        notebookId: notebookId,
        store: store,
        german: german,
        onInsert: onInsert,
      ),
      FeatureKeys.packMusic => _MusicTools(
        index: toolIndex,
        german: german,
        onInsert: onInsert,
      ),
      FeatureKeys.packAcademic => _AcademicTools(
        index: toolIndex,
        german: german,
        onInsert: onInsert,
      ),
      FeatureKeys.packFitness => _FitnessTools(
        index: toolIndex,
        german: german,
        onInsert: onInsert,
      ),
      FeatureKeys.packTravel => _TravelTools(
        index: toolIndex,
        german: german,
        onInsert: onInsert,
      ),
      FeatureKeys.packFreelance => _FreelanceTools(
        index: toolIndex,
        notebookId: notebookId,
        store: store,
        german: german,
        onInsert: onInsert,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Pad extends StatelessWidget {
  const _Pad({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [child],
    );
  }
}

class _DevTools extends StatefulWidget {
  const _DevTools({
    required this.index,
    required this.notebookId,
    required this.store,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final String notebookId;
  final PackStore store;
  final bool german;
  final ValueChanged<Uint8List> onInsert;

  @override
  State<_DevTools> createState() => _DevToolsState();
}

class _DevToolsState extends State<_DevTools> {
  final _code = TextEditingController(
    text: 'void main() {\n  print("hello");\n}',
  );
  String _lang = 'dart';
  late List<String> _snippets;

  @override
  void initState() {
    super.initState();
    _snippets = widget.store.snippets(widget.notebookId);
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _insertCode({required bool terminal}) async {
    final bytes = await PackRender.card(
      title: terminal ? 'terminal · $_lang' : _lang,
      body: _code.text,
      background: terminal ? const Color(0xFF04160A) : const Color(0xFF1E1E1E),
      foreground: terminal ? const Color(0xFF39FF14) : const Color(0xFFD4D4D4),
    );
    if (bytes != null) widget.onInsert(bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 1) {
      return _Pad(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _code,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Snippet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final text = _code.text.trim();
                if (text.isEmpty) return;
                setState(() => _snippets = [..._snippets, text]);
                await widget.store.saveSnippets(widget.notebookId, _snippets);
              },
              child: Text(widget.german ? 'Speichern' : 'Save'),
            ),
            for (final snippet in _snippets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(snippet, maxLines: 2),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => Clipboard.setData(ClipboardData(text: snippet)),
                ),
              ),
          ],
        ),
      );
    }
    return _Pad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _lang,
            items: [
              for (final lang in const [
                'dart',
                'python',
                'javascript',
                'html',
                'css',
                'java',
                'sql',
                'c',
                'go',
                'rust',
              ])
                DropdownMenuItem(value: lang, child: Text(lang)),
            ],
            onChanged: (v) => setState(() => _lang = v ?? 'dart'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _insertCode(terminal: widget.index == 2),
            child: Text(widget.german ? 'Auf die Seite' : 'Insert on page'),
          ),
        ],
      ),
    );
  }
}

class _EduTools extends ConsumerStatefulWidget {
  const _EduTools({
    required this.index,
    required this.notebookId,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final String notebookId;
  final bool german;
  final ValueChanged<Uint8List> onInsert;

  @override
  ConsumerState<_EduTools> createState() => _EduToolsState();
}

class _EduToolsState extends ConsumerState<_EduTools> {
  final _qa = TextEditingController(text: 'Q: Was ist 2+2?\nA: 4');
  final _points = TextEditingController(text: '17');
  final _max = TextEditingController(text: '20');
  final _marks = <String>[];
  final _watch = Stopwatch();
  Timer? _tick;

  @override
  void dispose() {
    _qa.dispose();
    _points.dispose();
    _max.dispose();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _makeCards() async {
    final pairs = <(String, String)>[];
    final lines = _qa.text.split(RegExp(r'\n+'));
    String? q;
    for (final line in lines) {
      final t = line.trim();
      if (t.toLowerCase().startsWith('q:')) {
        q = t.substring(2).trim();
      } else if (t.toLowerCase().startsWith('a:') && q != null) {
        pairs.add((q, t.substring(2).trim()));
        q = null;
      }
    }
    if (pairs.isEmpty) return;
    final repo = ref.read(notebookRepositoryProvider);
    final deck = await repo.createFlashcardDeck(
      title: widget.german ? 'Aus der Notiz' : 'From the note',
    );
    for (final pair in pairs) {
      await repo.saveFlashcard(
        Flashcard.create(deckId: deck.id, front: pair.$1, back: pair.$2),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.german
              ? '${pairs.length} Karten angelegt (Spaced Repetition).'
              : '${pairs.length} cards created (spaced repetition).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return _Pad(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _qa,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: widget.german
                    ? 'Eine Zeile Q:, eine Zeile A:'
                    : 'One Q: line, one A: line',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _makeCards,
              child: Text(widget.german ? 'Karten erzeugen' : 'Create cards'),
            ),
          ],
        ),
      );
    }
    if (widget.index == 1) {
      final elapsed = _watch.elapsed;
      return _Pad(
        child: Column(
          children: [
            Text(
              '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
              style: AppTheme.headline(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: () {
                    _watch.start();
                    _tick?.cancel();
                    _tick = Timer.periodic(
                      const Duration(seconds: 1),
                      (_) => setState(() {}),
                    );
                  },
                  child: Text(widget.german ? 'Start' : 'Start'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _marks.add(
                        '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}  ${widget.german ? 'Marke' : 'Mark'}',
                      );
                    });
                  },
                  child: Text(widget.german ? 'Marke' : 'Mark'),
                ),
              ],
            ),
            for (final mark in _marks) ListTile(title: Text(mark)),
            FilledButton.tonal(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: widget.german ? 'Vorlesungs-Marken' : 'Lecture marks',
                  body: _marks.join('\n'),
                  background: const Color(0xFF1A2744),
                  foreground: const Color(0xFFE8EEF8),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Marken einfügen' : 'Insert marks'),
            ),
          ],
        ),
      );
    }
    final p = double.tryParse(_points.text.replaceAll(',', '.')) ?? 0;
    final m = double.tryParse(_max.text.replaceAll(',', '.')) ?? 1;
    final percent = m == 0 ? 0 : (p / m) * 100;
    return _Pad(
      child: Column(
        children: [
          TextField(
            controller: _points,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: widget.german ? 'Punkte' : 'Points',
            ),
          ),
          TextField(
            controller: _max,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: widget.german ? 'Maximal' : 'Maximum',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            '${percent.toStringAsFixed(1)} %',
            style: AppTheme.headline(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          FilledButton(
            onPressed: () async {
              final bytes = await PackRender.card(
                title: widget.german ? 'Notenrechner' : 'Grade calculator',
                body: '$p / $m  →  ${percent.toStringAsFixed(1)} %',
                background: const Color(0xFF14332B),
                foreground: const Color(0xFFE7F6F0),
              );
              if (bytes != null) widget.onInsert(bytes);
            },
            child: Text(widget.german ? 'Einfügen' : 'Insert'),
          ),
        ],
      ),
    );
  }
}

class _RpgTools extends StatefulWidget {
  const _RpgTools({
    required this.index,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final bool german;
  final ValueChanged<Uint8List> onInsert;
  @override
  State<_RpgTools> createState() => _RpgToolsState();
}

class _RpgToolsState extends State<_RpgTools> {
  final _text = TextEditingController(
    text: 'Anfang\nMitte\nEnde',
  );
  final _name = TextEditingController(text: 'Aria');
  double _str = 3, _int = 4, _dex = 2;
  final _tree = TextEditingController(
    text: 'Start: Willst du helfen?\n- Ja -> Kampf\n- Nein -> Flucht',
  );

  @override
  void dispose() {
    _text.dispose();
    _name.dispose();
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return _Pad(
        child: Column(
          children: [
            TextField(
              controller: _text,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: widget.german ? 'Ereignisse, eine je Zeile' : 'Events, one per line',
              ),
            ),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: widget.german ? 'Zeitstrahl' : 'Timeline',
                  body: [
                    for (final (i, line) in _text.text.split('\n').indexed)
                      if (line.trim().isNotEmpty) '${i + 1}. ${line.trim()}',
                  ].join('\n'),
                  background: const Color(0xFF2B1B12),
                  foreground: const Color(0xFFF4E4C8),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Zeitstrahl einfügen' : 'Insert timeline'),
            ),
          ],
        ),
      );
    }
    if (widget.index == 1) {
      return _Pad(
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            Text('STR ${_str.round()}'),
            Slider(value: _str, min: 1, max: 10, onChanged: (v) => setState(() => _str = v)),
            Text('INT ${_int.round()}'),
            Slider(value: _int, min: 1, max: 10, onChanged: (v) => setState(() => _int = v)),
            Text('DEX ${_dex.round()}'),
            Slider(value: _dex, min: 1, max: 10, onChanged: (v) => setState(() => _dex = v)),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: _name.text,
                  body: 'STR ${_str.round()}   INT ${_int.round()}   DEX ${_dex.round()}',
                  background: const Color(0xFF3A1020),
                  foreground: const Color(0xFFFFE4EC),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Steckbrief einfügen' : 'Insert sheet'),
            ),
          ],
        ),
      );
    }
    return _Pad(
      child: Column(
        children: [
          TextField(controller: _tree, maxLines: 7),
          FilledButton(
            onPressed: () async {
              final bytes = await PackRender.card(
                title: widget.german ? 'Dialogbaum' : 'Dialogue tree',
                body: _tree.text,
                background: const Color(0xFF1B2033),
                foreground: const Color(0xFFE4E8FF),
              );
              if (bytes != null) widget.onInsert(bytes);
            },
            child: Text(widget.german ? 'Einfügen' : 'Insert'),
          ),
        ],
      ),
    );
  }
}

class _CulinaryTools extends StatefulWidget {
  const _CulinaryTools({
    required this.index,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final bool german;
  final ValueChanged<Uint8List> onInsert;
  @override
  State<_CulinaryTools> createState() => _CulinaryToolsState();
}

class _CulinaryToolsState extends State<_CulinaryTools> {
  final _recipe = TextEditingController(text: '200g Mehl\n2 Eier\n100ml Milch');
  double _factor = 1;
  final _unit = TextEditingController(text: '1 cup');
  int _minutes = 30;
  Timer? _timer;
  int _left = 0;

  @override
  void dispose() {
    _recipe.dispose();
    _unit.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _scale(String raw, double factor) {
    return raw.replaceAllMapped(RegExp(r'(\d+(?:[.,]\d+)?)'), (m) {
      final n = double.parse(m[1]!.replaceAll(',', '.'));
      final v = n * factor;
      return v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
    });
  }

  String _convert(String raw) {
    final s = raw.toLowerCase();
    final n = double.tryParse(
          RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(s)?.group(1)?.replaceAll(',', '.') ?? '',
        ) ??
        0;
    if (s.contains('cup')) return '${(n * 240).round()} ml';
    if (s.contains('fahrenheit') || s.contains('°f') || s.contains('f')) {
      return '${((n - 32) * 5 / 9).round()} °C';
    }
    if (s.contains('oz')) return '${(n * 28.35).round()} g';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return _Pad(
        child: Column(
          children: [
            TextField(controller: _recipe, maxLines: 6),
            Text('× ${_factor.toStringAsFixed(1)}'),
            Slider(
              value: _factor,
              min: 0.5,
              max: 4,
              onChanged: (v) => setState(() => _factor = v),
            ),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: widget.german ? 'Rezept skaliert' : 'Scaled recipe',
                  body: _scale(_recipe.text, _factor),
                  background: const Color(0xFF3D2412),
                  foreground: const Color(0xFFFFF1DE),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Einfügen' : 'Insert'),
            ),
          ],
        ),
      );
    }
    if (widget.index == 1) {
      return _Pad(
        child: Column(
          children: [
            TextField(controller: _unit),
            const SizedBox(height: 8),
            Text(_convert(_unit.text), style: AppTheme.headline(fontSize: 22)),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: widget.german ? 'Umrechnung' : 'Conversion',
                  body: '${_unit.text}  →  ${_convert(_unit.text)}',
                  background: const Color(0xFF2A3318),
                  foreground: const Color(0xFFF3F6E4),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Einfügen' : 'Insert'),
            ),
          ],
        ),
      );
    }
    return _Pad(
      child: Column(
        children: [
          Slider(
            value: _minutes.toDouble(),
            min: 1,
            max: 90,
            onChanged: (v) => setState(() => _minutes = v.round()),
          ),
          Text(
            _left > 0
                ? '${(_left ~/ 60).toString().padLeft(2, '0')}:${(_left % 60).toString().padLeft(2, '0')}'
                : '$_minutes min',
            style: AppTheme.headline(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          FilledButton(
            onPressed: () {
              _left = _minutes * 60;
              _timer?.cancel();
              _timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (_left <= 1) {
                  t.cancel();
                  setState(() => _left = 0);
                  return;
                }
                setState(() => _left -= 1);
              });
            },
            child: Text(widget.german ? 'Timer starten' : 'Start timer'),
          ),
        ],
      ),
    );
  }
}

class _AgileTools extends StatefulWidget {
  const _AgileTools({
    required this.index,
    required this.notebookId,
    required this.store,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final String notebookId;
  final PackStore store;
  final bool german;
  final ValueChanged<Uint8List> onInsert;
  @override
  State<_AgileTools> createState() => _AgileToolsState();
}

class _AgileToolsState extends State<_AgileTools> {
  late Map<String, List<String>> _board;
  late Map<String, bool> _habits;
  final _item = TextEditingController();
  int _pomo = 25 * 60;
  Timer? _pomoTimer;
  bool _pomoWork = true;

  @override
  void initState() {
    super.initState();
    _board = widget.store.kanban(widget.notebookId);
    if (_board['todo']!.isEmpty &&
        _board['doing']!.isEmpty &&
        _board['done']!.isEmpty) {
      _board = {
        'todo': ['Aufgabe'],
        'doing': <String>[],
        'done': <String>[],
      };
    }
    _habits = widget.store.habits(widget.notebookId);
    if (_habits.isEmpty) {
      _habits = {
        widget.german ? '10 Seiten lesen' : 'Read 10 pages': false,
      };
    }
  }

  @override
  void dispose() {
    _item.dispose();
    _pomoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _item)),
                IconButton(
                  onPressed: () async {
                    final t = _item.text.trim();
                    if (t.isEmpty) return;
                    setState(() => _board['todo'] = [..._board['todo']!, t]);
                    await widget.store.saveKanban(widget.notebookId, _board);
                    _item.clear();
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  for (final col in ['todo', 'doing', 'done'])
                    Expanded(
                      child: _kanbanCol(col),
                    ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: 'Kanban',
                  body: [
                    'To do: ${_board['todo']!.join(', ')}',
                    'Doing: ${_board['doing']!.join(', ')}',
                    'Done: ${_board['done']!.join(', ')}',
                  ].join('\n'),
                  background: const Color(0xFF12202C),
                  foreground: const Color(0xFFE6F0F8),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Stand einfügen' : 'Insert board'),
            ),
          ],
        ),
      );
    }
    if (widget.index == 1) {
      return _Pad(
        child: Column(
          children: [
            Text(
              '${(_pomo ~/ 60).toString().padLeft(2, '0')}:${(_pomo % 60).toString().padLeft(2, '0')}',
              style: AppTheme.headline(fontSize: 36, fontWeight: FontWeight.w800),
            ),
            Text(_pomoWork ? 'Focus' : 'Break'),
            FilledButton(
              onPressed: () {
                _pomoTimer?.cancel();
                _pomoTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                  if (_pomo <= 1) {
                    setState(() {
                      _pomoWork = !_pomoWork;
                      _pomo = _pomoWork ? 25 * 60 : 5 * 60;
                    });
                    return;
                  }
                  setState(() => _pomo -= 1);
                });
              },
              child: Text(widget.german ? 'Start' : 'Start'),
            ),
          ],
        ),
      );
    }
    return _Pad(
      child: Column(
        children: [
          for (final e in _habits.entries)
            CheckboxListTile(
              value: e.value,
              title: Text(e.key),
              onChanged: (v) async {
                setState(() => _habits[e.key] = v ?? false);
                await widget.store.saveHabits(widget.notebookId, _habits);
              },
            ),
        ],
      ),
    );
  }

  Widget _kanbanCol(String key) {
    final items = _board[key]!;
    return Card(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(key, style: AppTheme.body(fontWeight: FontWeight.w800)),
          ),
          for (final item in items)
            ListTile(
              dense: true,
              title: Text(item, maxLines: 2),
              onTap: () async {
                setState(() {
                  _board[key] = [for (final i in items) if (i != item) i];
                  final next = key == 'todo'
                      ? 'doing'
                      : key == 'doing'
                          ? 'done'
                          : 'todo';
                  _board[next] = [..._board[next]!, item];
                });
                await widget.store.saveKanban(widget.notebookId, _board);
              },
            ),
        ],
      ),
    );
  }
}

class _MusicTools extends StatefulWidget {
  const _MusicTools({
    required this.index,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final bool german;
  final ValueChanged<Uint8List> onInsert;
  @override
  State<_MusicTools> createState() => _MusicToolsState();
}

class _MusicToolsState extends State<_MusicTools> {
  final _lyrics = TextEditingController(text: 'G     D\nHallo Welt');
  final _line = TextEditingController(text: 'Die Nacht ist still und weit');
  int _bpm = 100;
  Timer? _metro;
  bool _tickOn = false;

  @override
  void dispose() {
    _lyrics.dispose();
    _line.dispose();
    _metro?.cancel();
    super.dispose();
  }

  int _syllables(String text) {
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß ]'), '');
    var n = 0;
    for (final word in clean.split(RegExp(r'\s+'))) {
      n += math.max(1, RegExp(r'[aeiouyäöü]+').allMatches(word).length);
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return _Pad(
        child: Column(
          children: [
            TextField(controller: _lyrics, maxLines: 6),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: widget.german ? 'Akkorde' : 'Chords',
                  body: _lyrics.text,
                  background: const Color(0xFF201428),
                  foreground: const Color(0xFFF6E9FF),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Einfügen' : 'Insert'),
            ),
          ],
        ),
      );
    }
    if (widget.index == 1) {
      return _Pad(
        child: Column(
          children: [
            Text('$_bpm BPM', style: AppTheme.headline(fontSize: 24)),
            Slider(
              value: _bpm.toDouble(),
              min: 40,
              max: 200,
              onChanged: (v) => setState(() => _bpm = v.round()),
            ),
            FilledButton(
              onPressed: () {
                _metro?.cancel();
                _metro = Timer.periodic(
                  Duration(milliseconds: (60000 / _bpm).round()),
                  (_) => setState(() => _tickOn = !_tickOn),
                );
              },
              child: Text(widget.german ? 'Metronom' : 'Metronome'),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _tickOn ? AppTheme.accent : AppTheme.paperDeep,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    }
    return _Pad(
      child: Column(
        children: [
          TextField(controller: _line, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          Text(
            widget.german
                ? '${_syllables(_line.text)} Silben · Reim auf …eit / …eit'
                : '${_syllables(_line.text)} syllables',
          ),
        ],
      ),
    );
  }
}

class _AcademicTools extends StatefulWidget {
  const _AcademicTools({
    required this.index,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final bool german;
  final ValueChanged<Uint8List> onInsert;
  @override
  State<_AcademicTools> createState() => _AcademicToolsState();
}

class _AcademicToolsState extends State<_AcademicTools> {
  final _author = TextEditingController(text: 'Müller, A.');
  final _year = TextEditingController(text: '2022');
  final _title = TextEditingController(text: 'Notizen lernen');
  final _quote = TextEditingController();
  final _tex = TextEditingController(text: r'E = mc^2');
  String _style = 'apa';

  @override
  void dispose() {
    _author.dispose();
    _year.dispose();
    _title.dispose();
    _quote.dispose();
    _tex.dispose();
    super.dispose();
  }

  String get _cite {
    if (_style == 'harvard') {
      return '${_author.text} (${_year.text}) ${_title.text}.';
    }
    return '${_author.text} (${_year.text}). ${_title.text}.';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return _Pad(
        child: Column(
          children: [
            DropdownButton<String>(
              value: _style,
              items: const [
                DropdownMenuItem(value: 'apa', child: Text('APA')),
                DropdownMenuItem(value: 'harvard', child: Text('Harvard')),
              ],
              onChanged: (v) => setState(() => _style = v ?? 'apa'),
            ),
            TextField(controller: _author, decoration: const InputDecoration(labelText: 'Author')),
            TextField(controller: _year, decoration: const InputDecoration(labelText: 'Year')),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: _style.toUpperCase(),
                  body: _cite,
                  background: const Color(0xFF1C2430),
                  foreground: const Color(0xFFE8EDF4),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Zitation einfügen' : 'Insert citation'),
            ),
          ],
        ),
      );
    }
    if (widget.index == 1) {
      return _Pad(
        child: Column(
          children: [
            TextField(controller: _quote, maxLines: 5),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: widget.german ? 'Zitat' : 'Quote',
                  body: '„${_quote.text}“\n$_cite',
                  background: const Color(0xFF2A2230),
                  foreground: const Color(0xFFF4ECF8),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Einfügen' : 'Insert'),
            ),
          ],
        ),
      );
    }
    return _Pad(
      child: Column(
        children: [
          TextField(controller: _tex),
          FilledButton(
            onPressed: () async {
              final bytes = await PackRender.card(
                title: 'LaTeX',
                body: _tex.text,
                background: const Color(0xFF101820),
                foreground: const Color(0xFFB8E0D2),
              );
              if (bytes != null) widget.onInsert(bytes);
            },
            child: Text(widget.german ? 'Formel einfügen' : 'Insert formula'),
          ),
        ],
      ),
    );
  }
}

class _FitnessTools extends StatefulWidget {
  const _FitnessTools({
    required this.index,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final bool german;
  final ValueChanged<Uint8List> onInsert;
  @override
  State<_FitnessTools> createState() => _FitnessToolsState();
}

class _FitnessToolsState extends State<_FitnessTools> {
  final _log = TextEditingController(text: 'Kniebeuge 3x8 60kg');
  final _series = TextEditingController(text: '70,72,71,73');
  int _rest = 60;
  Timer? _restT;

  @override
  void dispose() {
    _log.dispose();
    _series.dispose();
    _restT?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return _Pad(
        child: Column(
          children: [
            TextField(controller: _log, maxLines: 5),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: 'Workout',
                  body: _log.text,
                  background: const Color(0xFF1A1A1A),
                  foreground: const Color(0xFFFFE08A),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Log einfügen' : 'Insert log'),
            ),
          ],
        ),
      );
    }
    if (widget.index == 1) {
      return _Pad(
        child: Column(
          children: [
            Text('$_rest s'),
            Slider(
              value: _rest.toDouble(),
              min: 15,
              max: 180,
              onChanged: (v) => setState(() => _rest = v.round()),
            ),
            FilledButton(
              onPressed: () {
                var left = _rest;
                _restT?.cancel();
                _restT = Timer.periodic(const Duration(seconds: 1), (t) {
                  if (left <= 1) {
                    t.cancel();
                    setState(() {});
                    return;
                  }
                  setState(() => left -= 1);
                  _rest = left;
                });
              },
              child: Text(widget.german ? 'Pause' : 'Rest'),
            ),
          ],
        ),
      );
    }
    return _Pad(
      child: Column(
        children: [
          TextField(
            controller: _series,
            decoration: InputDecoration(
              labelText: widget.german ? 'Werte, Komma getrennt' : 'Values, comma separated',
            ),
          ),
          FilledButton(
            onPressed: () async {
              final rows = [
                for (final (i, part) in _series.text.split(',').indexed)
                  ChartSeriesRow(
                    label: '${i + 1}',
                    value: part.trim(),
                  ),
              ];
              final bytes = await ChartRenderer.renderPng(
                kind: ChartKind.line,
                title: widget.german ? 'Fortschritt' : 'Progress',
                rows: rows,
              );
              if (bytes != null) widget.onInsert(bytes);
            },
            child: Text(widget.german ? 'Graph einfügen' : 'Insert graph'),
          ),
        ],
      ),
    );
  }
}

class _TravelTools extends StatefulWidget {
  const _TravelTools({
    required this.index,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final bool german;
  final ValueChanged<Uint8List> onInsert;
  @override
  State<_TravelTools> createState() => _TravelToolsState();
}

class _TravelToolsState extends State<_TravelTools> {
  final _place = TextEditingController(text: 'Lissabon');
  final _money = TextEditingController(text: '20');
  String _climate = 'rain';

  @override
  void dispose() {
    _place.dispose();
    _money.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return _Pad(
        child: Column(
          children: [
            TextField(controller: _place),
            FilledButton(
              onPressed: () async {
                final bytes = await PackRender.card(
                  title: widget.german ? 'Ort' : 'Place',
                  body: '📌 ${_place.text}',
                  background: const Color(0xFF12303A),
                  foreground: const Color(0xFFE4F6FA),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Pin einfügen' : 'Insert pin'),
            ),
          ],
        ),
      );
    }
    if (widget.index == 1) {
      final eur = double.tryParse(_money.text.replaceAll(',', '.')) ?? 0;
      return _Pad(
        child: Column(
          children: [
            TextField(
              controller: _money,
              decoration: const InputDecoration(labelText: 'EUR'),
              onChanged: (_) => setState(() {}),
            ),
            Text('USD ${(eur * 1.08).toStringAsFixed(2)} · GBP ${(eur * 0.85).toStringAsFixed(2)}'),
            Text(widget.german ? 'CET → EST  −6 h' : 'CET → EST  −6 h'),
          ],
        ),
      );
    }
    final items = switch (_climate) {
      'cold' => ['Jacke', 'Mütze', 'Handschuhe'],
      'hot' => ['Sonnencreme', 'Hut', 'Wasserflasche'],
      _ => ['Regenschirm', 'Jacke', 'feste Schuhe'],
    };
    return _Pad(
      child: Column(
        children: [
          DropdownButton<String>(
            value: _climate,
            items: [
              DropdownMenuItem(value: 'rain', child: Text(widget.german ? 'Regen' : 'Rain')),
              DropdownMenuItem(value: 'cold', child: Text(widget.german ? 'Kalt' : 'Cold')),
              DropdownMenuItem(value: 'hot', child: Text(widget.german ? 'Heiß' : 'Hot')),
            ],
            onChanged: (v) => setState(() => _climate = v ?? 'rain'),
          ),
          FilledButton(
            onPressed: () async {
              final bytes = await PackRender.card(
                title: widget.german ? 'Packliste' : 'Packing list',
                body: items.map((e) => '☐ $e').join('\n'),
                background: const Color(0xFF243018),
                foreground: const Color(0xFFEFF6E4),
              );
              if (bytes != null) widget.onInsert(bytes);
            },
            child: Text(widget.german ? 'Liste einfügen' : 'Insert list'),
          ),
        ],
      ),
    );
  }
}

class _FreelanceTools extends StatefulWidget {
  const _FreelanceTools({
    required this.index,
    required this.notebookId,
    required this.store,
    required this.german,
    required this.onInsert,
  });
  final int index;
  final String notebookId;
  final PackStore store;
  final bool german;
  final ValueChanged<Uint8List> onInsert;
  @override
  State<_FreelanceTools> createState() => _FreelanceToolsState();
}

class _FreelanceToolsState extends State<_FreelanceTools> {
  late double _seconds;
  Timer? _clock;
  bool _running = false;
  final _client = TextEditingController();
  final _rate = TextEditingController(text: '45');

  @override
  void initState() {
    super.initState();
    _seconds = widget.store.timeSeconds(widget.notebookId);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _client.dispose();
    _rate.dispose();
    super.dispose();
  }

  String _fmt(double s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return _Pad(
        child: Column(
          children: [
            Text(_fmt(_seconds), style: AppTheme.headline(fontSize: 32)),
            FilledButton(
              onPressed: () {
                if (_running) {
                  _clock?.cancel();
                  setState(() => _running = false);
                  widget.store.saveTimeSeconds(widget.notebookId, _seconds);
                  return;
                }
                setState(() => _running = true);
                _clock = Timer.periodic(const Duration(seconds: 1), (_) {
                  setState(() => _seconds += 1);
                });
              },
              child: Text(_running ? 'Stop' : 'Start'),
            ),
          ],
        ),
      );
    }
    if (widget.index == 1) {
      return _Pad(
        child: Column(
          children: [
            TextField(
              controller: _client,
              decoration: InputDecoration(
                labelText: widget.german ? 'Kunde' : 'Client',
              ),
            ),
            FilledButton(
              onPressed: () async {
                final name = _client.text.trim();
                if (name.isEmpty) return;
                final list = [
                  ...widget.store.clients(widget.notebookId),
                  {
                    'name': name,
                    'at': DateTime.now().toIso8601String(),
                  },
                ];
                await widget.store.saveClients(widget.notebookId, list);
                final bytes = await PackRender.card(
                  title: widget.german ? 'Kunde' : 'Client',
                  body: name,
                  background: const Color(0xFF1E2A24),
                  foreground: const Color(0xFFE8F5EE),
                );
                if (bytes != null) widget.onInsert(bytes);
              },
              child: Text(widget.german ? 'Karte einfügen' : 'Insert card'),
            ),
          ],
        ),
      );
    }
    final hours = _seconds / 3600;
    final rate = double.tryParse(_rate.text.replaceAll(',', '.')) ?? 0;
    final sum = hours * rate;
    return _Pad(
      child: Column(
        children: [
          TextField(
            controller: _rate,
            decoration: InputDecoration(
              labelText: widget.german ? 'Stundensatz €' : 'Hourly rate €',
            ),
          ),
          Text('${_fmt(_seconds)} × $rate € = ${sum.toStringAsFixed(2)} €'),
          FilledButton(
            onPressed: () async {
              final bytes = await PackRender.card(
                title: widget.german ? 'Rechnung' : 'Invoice',
                body: '${_fmt(_seconds)}\n${sum.toStringAsFixed(2)} €',
                background: const Color(0xFF222222),
                foreground: const Color(0xFFF5F5F5),
              );
              if (bytes != null) widget.onInsert(bytes);
            },
            child: Text(widget.german ? 'Rechnung einfügen' : 'Insert invoice'),
          ),
        ],
      ),
    );
  }
}
