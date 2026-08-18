import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import 'gemma_device_profile.dart';
import 'gemma_model_catalog.dart';
import 'gemma_runtime.dart';

Future<void> showGemmaSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GemmaSetupSheet(),
  );
}

class _GemmaSetupSheet extends ConsumerStatefulWidget {
  const _GemmaSetupSheet();

  @override
  ConsumerState<_GemmaSetupSheet> createState() => _GemmaSetupSheetState();
}

class _GemmaSetupSheetState extends ConsumerState<_GemmaSetupSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final runtime = ref.read(gemmaRuntimeProvider);
      if (runtime.isReady) return;
      runtime.runCheck();
    });
  }

  String _tierLabel(AppLocalizations l10n, GemmaModelTier tier) =>
      switch (tier) {
        GemmaModelTier.lite => l10n.gemmaTierLite,
        GemmaModelTier.balanced => l10n.gemmaTierBalanced,
        GemmaModelTier.full => l10n.gemmaTierFull,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppTheme.palette;
    final runtime = ref.watch(gemmaRuntimeProvider);
    final profile = runtime.lastProfile;
    final spec =
        runtime.spec ??
        (profile == null
            ? null
            : GemmaModelCatalog.byTier(profile.recommended));

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: BorderRadius.circular(palette.radius + 8),
            border: Border.all(color: palette.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.gemmaSetupTitle,
                style: AppTheme.headline(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.gemmaSetupBody,
                style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 14),
              if (runtime.phase == GemmaPhase.checking)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (profile != null) ...[
                _Stat(l10n.gemmaRam, '${profile.ramMb} MB'),
                _Stat(l10n.gemmaCores, '${profile.cpuCores}'),
                _Stat(l10n.gemmaBench, '${profile.benchMs} ms'),
                if (profile.deviceLabel.isNotEmpty)
                  _Stat(l10n.gemmaDevice, profile.deviceLabel),
                const SizedBox(height: 8),
                Text(
                  l10n.gemmaPicked(_tierLabel(l10n, spec!.tier), spec.sizeMb),
                  style: AppTheme.body(fontWeight: FontWeight.w700),
                ),
              ],
              if (runtime.phase == GemmaPhase.downloading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: runtime.progress),
                const SizedBox(height: 6),
                Text(
                  l10n.gemmaDownloading(((runtime.progress * 100).round())),
                  style: AppTheme.body(fontSize: 13),
                ),
              ],
              if (runtime.phase == GemmaPhase.ready)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    l10n.gemmaModelReady,
                    style: AppTheme.body(
                      fontWeight: FontWeight.w700,
                      color: palette.accent,
                    ),
                  ),
                ),
              if (runtime.error != null && runtime.phase == GemmaPhase.failed)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    l10n.gemmaDownloadFailed,
                    style: AppTheme.body(color: const Color(0xFFB42318)),
                  ),
                ),
              const SizedBox(height: 14),
              if (runtime.phase != GemmaPhase.ready)
                FilledButton(
                  onPressed:
                      runtime.phase == GemmaPhase.downloading ||
                          runtime.phase == GemmaPhase.checking ||
                          spec == null
                      ? null
                      : () => runtime.installTier(spec.tier),
                  child: Text(l10n.gemmaDownload),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  runtime.phase == GemmaPhase.ready ? l10n.close : l10n.cancel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTheme.body(color: AppTheme.inkMuted)),
          ),
          Text(value, style: AppTheme.body(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
