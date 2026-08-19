import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../library/providers/library_providers.dart';
import 'lan_sync_controller.dart';
import 'lan_sync_discovery.dart';
import 'lan_sync_protocol.dart';
import 'nearby_link.dart';

/// Host or join a same-Wi‑Fi / hotspot notebook sync session.
class NearbySyncScreen extends ConsumerStatefulWidget {
  const NearbySyncScreen({super.key, this.notebookId});

  /// When set, this device can host [notebookId]. Join works without it.
  final String? notebookId;

  @override
  ConsumerState<NearbySyncScreen> createState() => _NearbySyncScreenState();
}

class _NearbySyncScreenState extends ConsumerState<NearbySyncScreen> {
  final _hostController = TextEditingController();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _busy = false;
  int _handledEventSeq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sync = ref.read(lanSyncProvider);
      await sync.refreshAddresses();
      await sync.startBrowsing();
    });
  }

  @override
  void dispose() {
    // Keep browsing alive for other screens; only dispose controllers.
    _hostController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _host() async {
    final notebookId = widget.notebookId;
    if (notebookId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(lanSyncProvider).startHost(
            notebookId: notebookId,
            displayName: _nameController.text,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final host = _hostController.text.trim();
    final code = _codeController.text.trim();
    if (host.isEmpty || code.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(lanSyncProvider).join(
            host: host,
            code: code,
            displayName: _nameController.text,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinDiscovered(NearbyDiscoveredHost host) async {
    setState(() => _busy = true);
    try {
      await ref.read(lanSyncProvider).joinDiscovered(
            host,
            displayName: _nameController.text,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    await ref.read(lanSyncProvider).stop();
  }

  Future<void> _scanJoin() async {
    final link = await Navigator.of(context).push<NearbyLink>(
      MaterialPageRoute(builder: (_) => const NearbyScanJoinPage()),
    );
    if (link == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(lanSyncProvider).joinFromLink(
            link,
            displayName: _nameController.text,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sync = ref.watch(lanSyncProvider);

    ref.listen<LanSyncController>(lanSyncProvider, (previous, next) {
      final event = next.lastEvent;
      if (event == null || next.eventSeq == _handledEventSeq) return;
      _handledEventSeq = next.eventSeq;
      if (event.kind == LanSyncEventKind.snapshotApplied &&
          event.notebookId != null &&
          mounted) {
        ref.invalidate(notebooksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.nearbySyncSnapshotReceived)),
        );
        context.go('/notebook/${event.notebookId}');
      }
      if (event.kind == LanSyncEventKind.error &&
          event.message != null &&
          mounted) {
        final text = event.message == 'web_unsupported'
            ? l10n.nearbySyncWebUnsupported
            : event.message == 'disconnected'
            ? l10n.nearbySyncDisconnected
            : event.message == 'invalid_code'
            ? l10n.nearbySyncInvalidCode
            : event.message == 'classroom_mismatch'
            ? l10n.classroomAutoConnectMismatch
            : '${l10n.nearbySyncError}: ${event.message}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nearbySyncTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.nearbySyncIntro,
            style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 14.5),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.park_outlined),
              title: Text(l10n.nearbySyncParkTitle),
              subtitle: Text(l10n.nearbySyncParkHint),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.nearbySyncDeviceName,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _StatusCard(sync: sync, l10n: l10n),
          const SizedBox(height: 20),
          Text(
            l10n.nearbySyncJoinSection,
            style: AppTheme.headline(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.nearbySyncDiscoverHint,
            style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy || (sync.isActive && sync.role != LanSyncRole.guest)
                ? null
                : _scanJoin,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(l10n.nearbySyncScanQr),
          ),
          const SizedBox(height: 16),
          if (sync.role == LanSyncRole.host && sync.sessionCode != null) ...[
            Text(
              l10n.nearbySyncHostSection,
              style: AppTheme.headline(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            _CodeBox(code: sync.sessionCode!, l10n: l10n),
            const SizedBox(height: 10),
            if (sync.waitingForPersonalHotspot)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  l10n.nearbySyncIosHotspotHint,
                  style: AppTheme.body(color: AppTheme.inkMuted),
                ),
              ),
            if (sync.hotspotSession != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.wifi_rounded),
                title: Text(l10n.nearbySyncWifiName),
                subtitle: Text(sync.hotspotSession!.ssid),
                trailing: IconButton(
                  tooltip: l10n.nearbySyncCopy,
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: sync.hotspotSession!.ssid),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.nearbySyncCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.password_rounded),
                title: Text(l10n.nearbySyncWifiPassword),
                subtitle: Text(sync.hotspotSession!.password),
                trailing: IconButton(
                  tooltip: l10n.nearbySyncCopy,
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: sync.hotspotSession!.password),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.nearbySyncCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
            ],
            if (sync.joinLink != null) ...[
              Center(
                child: QrImageView(
                  data: sync.joinLink!.toString(),
                  size: 196,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.nearbySyncQrHint,
                style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
            if (sync.localAddresses.isEmpty && !sync.waitingForPersonalHotspot)
              Text(
                l10n.nearbySyncNoAddress,
                style: AppTheme.body(color: AppTheme.inkMuted),
              )
            else
              for (final ip in sync.localAddresses)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.wifi_tethering_rounded),
                  title: Text(ip),
                  subtitle: Text(l10n.nearbySyncPort(sync.port)),
                  trailing: IconButton(
                    tooltip: l10n.nearbySyncCopy,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '$ip:${sync.port}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.nearbySyncCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _stop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.nearbySyncStop),
            ),
          ] else if (widget.notebookId != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.nearbySyncHostSection,
              style: AppTheme.headline(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.nearbySyncHostHint,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy || sync.isActive ? null : _host,
              icon: const Icon(Icons.cast_connected_rounded),
              label: Text(l10n.nearbySyncStartHost),
            ),
          ] else
            Text(
              l10n.nearbySyncHostNeedsNotebook,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13.5),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  sync.browsing
                      ? l10n.nearbySyncSearching
                      : l10n.nearbySyncSearchStopped,
                  style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: sync.browsing
                    ? () => ref.read(lanSyncProvider).stopBrowsing()
                    : () => ref.read(lanSyncProvider).startBrowsing(),
                icon: Icon(
                  sync.browsing ? Icons.stop_rounded : Icons.refresh_rounded,
                ),
                label: Text(
                  sync.browsing
                      ? l10n.nearbySyncStopSearch
                      : l10n.nearbySyncStartSearch,
                ),
              ),
            ],
          ),
          if (sync.discoveredHosts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.nearbySyncNoDevices,
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
            )
          else
            for (final host in sync.discoveredHosts)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.tablet_mac_rounded),
                  title: Text(host.name),
                  subtitle: Text(
                    [
                      if (host.notebookTitle != null) host.notebookTitle!,
                      '${host.host}:${host.port}',
                      host.sessionCode,
                    ].join(' · '),
                  ),
                  trailing: FilledButton(
                    onPressed: _busy || sync.isActive
                        ? null
                        : () => _joinDiscovered(host),
                    child: Text(l10n.nearbySyncJoin),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: Text(l10n.nearbySyncManualJoin),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              Text(
                l10n.nearbySyncJoinHint,
                style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hostController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.nearbySyncHostAddress,
                  hintText: '192.168.1.10',
                  prefixIcon: const Icon(Icons.lan_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.nearbySyncCode,
                  prefixIcon: const Icon(Icons.pin_outlined),
                ),
              ),
              const SizedBox(height: 12),
              if (sync.role == LanSyncRole.guest && sync.isActive)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _stop,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(l10n.nearbySyncStop),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: _busy || sync.isActive ? null : _join,
                  icon: const Icon(Icons.login_rounded),
                  label: Text(l10n.nearbySyncJoinManual),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.nearbySyncBinaryNote,
            style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.sync, required this.l10n});

  final LanSyncController sync;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final status = switch (sync.phase) {
      LanSyncPhase.idle => l10n.nearbySyncStatusIdle,
      LanSyncPhase.hosting => l10n.nearbySyncStatusHosting,
      LanSyncPhase.connecting => l10n.nearbySyncStatusConnecting,
      LanSyncPhase.syncing => l10n.nearbySyncStatusSyncing,
      LanSyncPhase.connected => l10n.nearbySyncStatusConnected,
      LanSyncPhase.error => l10n.nearbySyncStatusError,
    };
    return Card(
      child: ListTile(
        leading: Icon(
          sync.phase == LanSyncPhase.connected
              ? Icons.sync_rounded
              : Icons.wifi_find_rounded,
        ),
        title: Text(status),
        subtitle: Text(
          [
            if (sync.peerName != null) l10n.nearbySyncPeer(sync.peerName!),
            if (sync.peerCount > 0) l10n.nearbySyncPeers(sync.peerCount),
            if (sync.errorMessage != null && sync.phase == LanSyncPhase.error)
              sync.errorMessage!,
          ].where((e) => e.isNotEmpty).join(' · '),
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code, required this.l10n});

  final String code;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return             Material(
      color: AppTheme.paperDeep,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.nearbySyncCode,
                    style: AppTheme.body(
                      color: AppTheme.inkMuted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: AppTheme.headline(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.nearbySyncCopy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.nearbySyncCopied)),
                );
              },
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class NearbyScanJoinPage extends StatefulWidget {
  const NearbyScanJoinPage({super.key});

  @override
  State<NearbyScanJoinPage> createState() => _NearbyScanJoinPageState();
}

class _NearbyScanJoinPageState extends State<NearbyScanJoinPage> {
  var _done = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.nearbySyncScanQr)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          for (final barcode in capture.barcodes) {
            final link = NearbyLink.tryParse(barcode.rawValue ?? '');
            if (link == null) continue;
            _done = true;
            Navigator.of(context).pop(link);
            return;
          }
        },
      ),
    );
  }
}
