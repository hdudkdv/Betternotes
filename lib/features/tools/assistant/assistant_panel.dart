import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../calculator/calculator_engine.dart';

class AssistantMessage {
  const AssistantMessage({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

/// On-device helper: evaluates and solves expressions. Marketplace unlock
/// gates the panel; a later Gemma build can replace [_reply].
class AssistantPanel extends StatefulWidget {
  const AssistantPanel({super.key, required this.unlocked});

  final bool unlocked;

  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> {
  final _engine = CalculatorEngine();
  final _input = TextEditingController();
  final _messages = <AssistantMessage>[];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    setState(() {
      _messages.add(AssistantMessage(fromUser: true, text: text));
      _messages.add(AssistantMessage(fromUser: false, text: _reply(text)));
    });
  }

  String _reply(String text) {
    final l10n = AppLocalizations.of(context)!;
    final expr = text
        .replaceAll(RegExp(r'^(löse|solve|berechne|rechne)\s+', caseSensitive: false), '')
        .trim();
    final result = _engine.evaluateOrSolve(expr);
    if (result.ok) {
      if (expr.contains('=') && expr.toLowerCase().contains('x')) {
        return 'x = ${result.display}';
      }
      return '${l10n.calculatorEquals} ${result.display}';
    }
    return l10n.assistantMathHint;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.unlocked) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.assistantLocked, style: AppTheme.body()),
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
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment:
                    msg.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: msg.fromUser ? AppTheme.accentSoft : AppTheme.paperDeep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(msg.text, style: AppTheme.body(fontSize: 13)),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            children: [
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
              IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded)),
            ],
          ),
        ),
      ],
    );
  }
}
