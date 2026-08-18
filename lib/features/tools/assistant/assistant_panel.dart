import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../search/recognition/recognition_service.dart';
import 'gemma_runtime.dart';
import 'gemma_setup.dart';
import 'gemma_tutor.dart';

class AssistantMessage {
  const AssistantMessage({
    required this.fromUser,
    required this.text,
    this.imagePath,
  });

  final bool fromUser;
  final String text;
  final String? imagePath;
}

/// Marketplace Gemma coach: guides like a teacher, explains connections.
class AssistantPanel extends ConsumerStatefulWidget {
  const AssistantPanel({
    super.key,
    required this.unlocked,
    this.pageImagePaths = const [],
  });

  final bool unlocked;
  final List<String> pageImagePaths;

  @override
  ConsumerState<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends ConsumerState<AssistantPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  GemmaTutor? _tutor;
  final _messages = <AssistantMessage>[];
  List<String> _chips = const [];
  bool _readingImage = false;
  bool _thinking = false;

  GemmaTutor get _coach {
    return _tutor ??= GemmaTutor(
      german: Localizations.localeOf(context).languageCode == 'de',
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gemmaRuntimeProvider).restore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.unlocked && _messages.isEmpty) {
      final hello = _coach.welcome();
      _messages.add(AssistantMessage(fromUser: false, text: hello.text));
      _chips = hello.chips;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    if (preset == null) _input.clear();
    final runtime = ref.read(gemmaRuntimeProvider);
    if (runtime.isReady) {
      setState(() {
        _messages.add(AssistantMessage(fromUser: true, text: text));
        _thinking = true;
        _chips = const [];
      });
      _scrollToEnd();
      final reply = await runtime.complete(
        text,
        german: Localizations.localeOf(context).languageCode == 'de',
      );
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _messages.add(
          AssistantMessage(
            fromUser: false,
            text: (reply == null || reply.isEmpty)
                ? _coach.respond(text).text
                : reply,
          ),
        );
      });
      _scrollToEnd();
      return;
    }
    _push(text, _coach.respond(text));
  }

  void _push(String userText, GemmaReply reply, {String? imagePath}) {
    setState(() {
      _messages.add(
        AssistantMessage(fromUser: true, text: userText, imagePath: imagePath),
      );
      _messages.add(AssistantMessage(fromUser: false, text: reply.text));
      _chips = reply.chips;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _attachImage() async {
    final l10n = AppLocalizations.of(context)!;
    final path = await _chooseImage(l10n);
    if (path == null || !mounted) return;
    setState(() => _readingImage = true);
    var ocr = '';
    try {
      ocr = await RecognitionService.instance.recognizeImagePath(path);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _readingImage = false);
    final runtime = ref.read(gemmaRuntimeProvider);
    if (runtime.isReady) {
      setState(() {
        _messages.add(
          AssistantMessage(
            fromUser: true,
            text: l10n.assistantImageAttached,
            imagePath: path,
          ),
        );
        _thinking = true;
      });
      _scrollToEnd();
      final reply = await runtime.complete(
        l10n.assistantImageAttached,
        german: Localizations.localeOf(context).languageCode == 'de',
        extra: ocr,
      );
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _messages.add(
          AssistantMessage(
            fromUser: false,
            text: (reply == null || reply.isEmpty)
                ? _coach
                      .respondImage(
                        ocrText: ocr,
                        label: l10n.assistantImageAttached,
                      )
                      .text
                : reply,
          ),
        );
      });
      _scrollToEnd();
      return;
    }
    final reply = _coach.respondImage(
      ocrText: ocr,
      label: l10n.assistantImageAttached,
    );
    _push(l10n.assistantImageAttached, reply, imagePath: path);
  }

  Future<String?> _chooseImage(AppLocalizations l10n) async {
    final pagePaths = [
      for (final path in widget.pageImagePaths)
        if (path.isNotEmpty) path,
    ];
    if (pagePaths.isEmpty) return _pickFromGallery();

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.card,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.assistantImageGallery),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              for (var i = 0; i < pagePaths.length; i++)
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: Text('${l10n.assistantImageFromPage} ${i + 1}'),
                  onTap: () => Navigator.pop(context, pagePaths[i]),
                ),
            ],
          ),
        );
      },
    );
    if (choice == null) return null;
    if (choice == 'gallery') return _pickFromGallery();
    return choice;
  }

  Future<String?> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    return file?.path;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.unlocked) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.assistantLocked, style: AppTheme.body()),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/marketplace'),
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: Text(l10n.marketplace),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            l10n.assistantHint,
            style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
          ),
        ),
        if (!ref.watch(gemmaRuntimeProvider).isReady)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: OutlinedButton.icon(
              onPressed: () => showGemmaSetupSheet(context),
              icon: const Icon(Icons.memory_outlined, size: 18),
              label: Text(l10n.gemmaNeedsSetup),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _messages.length + (_thinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _messages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                  ),
                );
              }
              final msg = _messages[index];
              return Align(
                alignment: msg.fromUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: msg.fromUser
                        ? AppTheme.accentSoft
                        : AppTheme.paperDeep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.imagePath != null) ...[
                        const Icon(Icons.image_outlined, size: 18),
                        const SizedBox(height: 6),
                      ],
                      Text(msg.text, style: AppTheme.body(fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final chip in _chips)
                  ActionChip(
                    label: Text(chip, style: AppTheme.body(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _send(chip),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.assistantAttachImage,
                onPressed: _readingImage || _thinking ? null : _attachImage,
                icon: _readingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
              ),
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: InputDecoration(
                    hintText: l10n.assistantInputHint,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(
                onPressed: _thinking ? null : _send,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
