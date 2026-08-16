import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../entitlements/entitlement_model.dart';
import '../library/providers/library_providers.dart';
import 'pack_catalog.dart';
import 'pack_store.dart';
import 'pack_tools.dart';

Future<Uint8List?> showPackStudioSheet(
  BuildContext context, {
  required String notebookId,
}) {
  return showModalBottomSheet<Uint8List>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PackStudioSheet(notebookId: notebookId),
  );
}

class PackStudioSheet extends ConsumerWidget {
  const PackStudioSheet({super.key, required this.notebookId});

  final String notebookId;

  Widget _packTile(
    BuildContext context, {
    required AppLocalizations l10n,
    required bool german,
    required AppPalette palette,
    required PackDef pack,
    required bool unlocked,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(pack.icon, color: palette.accent),
      title: Text(
        pack.title(german),
        style: AppTheme.body(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        unlocked
            ? pack.tools(german).join(' · ')
            : l10n.unlockWithCoins(FeatureKeys.coinCost(pack.key)),
        style: AppTheme.body(fontSize: 12, color: palette.inkMuted),
      ),
      trailing: Icon(
        unlocked ? Icons.chevron_right : Icons.lock_outline,
      ),
      onTap: () async {
        if (!unlocked) {
          context.push('/marketplace');
          return;
        }
        final bytes = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(
            builder: (_) => PackWorkbench(
              pack: pack,
              notebookId: notebookId,
            ),
          ),
        );
        if (bytes != null && context.mounted) {
          Navigator.pop(context, bytes);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final german = Localizations.localeOf(context).languageCode == 'de';
    final entitlements = ref.watch(entitlementProvider);
    final palette = AppTheme.palette;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxHeight: 640),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: BorderRadius.circular(palette.radius + 8),
            border: Border.all(color: palette.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.packsTitle,
                style: AppTheme.headline(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.packsHint,
                style: AppTheme.body(fontSize: 13, color: palette.inkMuted),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    for (final group in PackCatalog.groups)
                      if (group.keys.any((key) => PackCatalog.byKey(key) != null)) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: Text(
                            switch (group.id) {
                              'study' => l10n.marketplaceGroupStudy,
                              'work' => l10n.marketplaceGroupWork,
                              _ => l10n.marketplaceGroupLife,
                            },
                            style: AppTheme.body(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: palette.inkMuted,
                            ),
                          ),
                        ),
                        for (final key in group.keys)
                          if (PackCatalog.byKey(key) != null)
                            _packTile(
                              context,
                              l10n: l10n,
                              german: german,
                              palette: palette,
                              pack: PackCatalog.byKey(key)!,
                              unlocked: entitlements.hasAccess(key),
                            ),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PackWorkbench extends ConsumerStatefulWidget {
  const PackWorkbench({
    super.key,
    required this.pack,
    required this.notebookId,
  });

  final PackDef pack;
  final String notebookId;

  @override
  ConsumerState<PackWorkbench> createState() => _PackWorkbenchState();
}

class _PackWorkbenchState extends ConsumerState<PackWorkbench> {
  int _tool = 0;

  @override
  Widget build(BuildContext context) {
    final german = Localizations.localeOf(context).languageCode == 'de';
    final tools = widget.pack.tools(german);
    final store = PackStore(ref.read(sharedPreferencesProvider));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pack.title(german), style: AppTheme.headline()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 6,
              children: [
                for (var i = 0; i < tools.length; i++)
                  ChoiceChip(
                    label: Text(tools[i]),
                    selected: _tool == i,
                    onSelected: (_) => setState(() => _tool = i),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PackToolHost(
              packKey: widget.pack.key,
              toolIndex: _tool,
              notebookId: widget.notebookId,
              store: store,
              german: german,
              onInsert: (bytes) => Navigator.pop(context, bytes),
            ),
          ),
        ],
      ),
    );
  }
}
