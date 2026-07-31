import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'teacher_models.dart';

class TeacherAudioScreen extends ConsumerStatefulWidget {
  const TeacherAudioScreen({super.key});

  @override
  ConsumerState<TeacherAudioScreen> createState() =>
      _TeacherAudioScreenState();
}

class _TeacherAudioScreenState extends ConsumerState<TeacherAudioScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  int _seconds = 0;
  bool _recording = false;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherMicrophonePermission)),
        );
      }
      return;
    }
    final fileName =
        'explanation_${DateTime.now().millisecondsSinceEpoch}.m4a';
    late final String path;
    if (kIsWeb) {
      path = fileName;
    } else {
      final root = await getApplicationDocumentsDirectory();
      final directory = p.join(root.path, 'betternotes_files', 'audio');
      await Directory(directory).create(recursive: true);
      path = p.join(directory, fileName);
    }
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _seconds++),
    );
    setState(() {
      _seconds = 0;
      _recording = true;
    });
  }

  Future<void> _stop() async {
    final path = await _recorder.stop();
    _timer?.cancel();
    setState(() => _recording = false);
    if (path == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final title = TextEditingController(text: l10n.teacherNewExplanation);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.teacherSaveRecording),
        content: TextField(
          controller: title,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.title),
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
    if (ok != true) return;
    await ref.read(teacherProvider.notifier).addAudioExplanation(
      AudioExplanation(
        id: const Uuid().v4(),
        title: title.text.trim(),
        localPath: path,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _editTranscript(AudioExplanation explanation) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: explanation.transcript);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.teacherTranscript),
        content: TextField(
          controller: controller,
          minLines: 8,
          maxLines: 16,
          decoration: InputDecoration(
            hintText: l10n.teacherTranscriptHint,
          ),
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
    if (ok == true) {
      await ref
          .read(teacherProvider.notifier)
          .updateTranscript(explanation.id, controller.text.trim());
    }
  }

  String get _duration {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final explanations = ref.watch(teacherProvider).audioExplanations;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.teacherAudio)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: _recording ? const Color(0xFFFFE8E8) : AppTheme.accentSoft,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    _recording ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 52,
                    color: _recording ? Colors.red : AppTheme.accent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _recording ? _duration : l10n.teacherAudioPrivacy,
                    textAlign: TextAlign.center,
                    style: AppTheme.headline(fontSize: _recording ? 28 : 18),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: _recording
                        ? FilledButton.styleFrom(backgroundColor: Colors.red)
                        : null,
                    onPressed: _recording ? _stop : _start,
                    icon: Icon(
                      _recording
                          ? Icons.stop_rounded
                          : Icons.fiber_manual_record_rounded,
                    ),
                    label: Text(
                      _recording
                          ? l10n.teacherStopRecording
                          : l10n.teacherStartRecording,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.teacherRecordings,
            style: AppTheme.headline(fontSize: 20),
          ),
          if (explanations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                l10n.teacherNoRecordings,
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final explanation in explanations.reversed)
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.audio_file_outlined),
                  title: Text(explanation.title),
                  subtitle: Text(
                    explanation.transcriptPending
                        ? l10n.teacherTranscriptPending
                        : explanation.transcript,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _editTranscript(explanation),
                  trailing: IconButton(
                    tooltip: l10n.share,
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        files: [
                          XFile(
                            explanation.localPath,
                            mimeType: 'audio/mp4',
                            name: '${explanation.title}.m4a',
                          ),
                        ],
                        text: explanation.transcript.isEmpty
                            ? null
                            : explanation.transcript,
                      ),
                    ),
                    icon: const Icon(Icons.ios_share_outlined),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
