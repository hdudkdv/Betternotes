import 'package:flutter/foundation.dart';
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
import 'nearby_share.dart';

Future<String?> promptNearbyAccessCode(BuildContext context, String shareName) {
  final controller = TextEditingController();
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.nearbyShareEnterCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.nearbyShareEnterCodeBody(shareName)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: l10n.nearbySyncCode),
              onSubmitted: (value) => Navigator.pop(context, value.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.nearbySyncJoin),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

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
  final _shareNameController = TextEditingController();
  NearbyHostedShare? _savedShare;
  bool _busy = false;
  int _handledEventSeq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sync = ref.read(lanSyncProvider);
      await sync.refreshAddresses();
      await sync.startBrowsing();
      final notebookId = widget.notebookId;
      if (notebookId != null) {
        final share = await sync.loadHostedShare(notebookId);
        if (share != null && mounted) {
          _shareNameController.text = share.displayName;
          setState(() => _savedShare = share);
        }
      }
    });
  }

  @override
  void dispose() {
    // Keep browsing alive for other screens; only dispose controllers.
    _hostController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _shareNameController.dispose();
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
            shareName: _shareNameController.text,
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
    final lan = ref.read(lanSyncProvider);
    String? code;
    if (!await lan.hasAccessTo(host) && host.sessionCode.isEmpty) {
      if (!mounted) return;
      code = await promptNearbyAccessCode(context, host.publicName);
      if (code == null || code.isEmpty || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await lan.joinDiscovered(
            host,
            displayName: _nameController.text,
            code: code,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    await ref.read(lanSyncProvider).stop();
  }

  Future<void> _scanJoin() async {
    final link = await showNearbyScanJoinSheet(context);
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
            : event.message == 'revoked'
            ? l10n.nearbyShareRevoked
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
          if (widget.notebookId != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _shareNameController,
              decoration: InputDecoration(
                labelText: l10n.nearbyShareDisplayName,
                hintText: l10n.nearbyShareDisplayNameHint,
                prefixIcon: const Icon(Icons.menu_book_outlined),
              ),
            ),
          ],
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
          if ((sync.hostedShare ?? _savedShare) != null) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.nearbyShareAutoHost),
              subtitle: Text(l10n.nearbyShareAutoHostHint),
              value: (sync.hostedShare ?? _savedShare)!.autoHost,
              onChanged: (value) async {
                await ref.read(lanSyncProvider).setShareAutoHost(value);
                final updated = await ref
                    .read(lanSyncProvider)
                    .loadHostedShare(widget.notebookId ?? '');
                if (mounted) setState(() => _savedShare = updated);
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.nearbyShareGranted,
              style: AppTheme.body(fontWeight: FontWeight.w700),
            ),
            if ((sync.hostedShare ?? _savedShare)!.granted.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.nearbyShareNoPeers,
                  style: AppTheme.body(color: AppTheme.inkMuted),
                ),
              )
            else
              for (final peer in (sync.hostedShare ?? _savedShare)!.granted)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tablet_mac_rounded),
                  title: Text(peer.name.isEmpty ? peer.deviceId : peer.name),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref
                          .read(lanSyncProvider)
                          .revokeSharePeer(peer.deviceId);
                      final updated = await ref
                          .read(lanSyncProvider)
                          .loadHostedShare(widget.notebookId ?? '');
                      if (mounted) setState(() => _savedShare = updated);
                    },
                    child: Text(l10n.nearbyShareRevoke),
                  ),
                ),
          ],
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
                  title: Text(host.publicName),
                  subtitle: Text(
                    [
                      if (host.host.isNotEmpty) host.host,
                      if (host.bleId != null) 'Bluetooth',
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

Future<NearbyLink?> showNearbyScanJoinSheet(BuildContext context) {
  return showModalBottomSheet<NearbyLink>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppTheme.paper,
    builder: (context) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: _NearbyScanJoinSheet(),
        ),
      );
    },
  );
}

class _NearbyScanJoinSheet extends StatefulWidget {
  const _NearbyScanJoinSheet();

  @override
  State<_NearbyScanJoinSheet> createState() => _NearbyScanJoinSheetState();
}

class _NearbyScanJoinSheetState extends State<_NearbyScanJoinSheet> {
  var _done = false;

  void _handle(String? raw) {
    if (_done) return;
    final link = NearbyLink.tryParse(raw ?? '');
    if (link == null) return;
    _done = true;
    Navigator.of(context).pop(link);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = (MediaQuery.sizeOf(context).height * 0.42).clamp(220.0, 360.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.nearbySyncScanQr,
          style: AppTheme.headline(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.nearbyScanSheetHint,
          style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13.5),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: kIsWeb
                ? ColoredBox(
                    color: AppTheme.card,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.nearbyJoinManual,
                          textAlign: TextAlign.center,
                          style: AppTheme.body(color: AppTheme.inkMuted),
                        ),
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          for (final barcode in capture.barcodes) {
                            _handle(barcode.rawValue);
                            if (_done) return;
                          }
                        },
                      ),
                      const IgnorePointer(child: _ScanFrameOverlay()),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScanFramePainter());
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.62,
      height: size.width * 0.62,
    );
    final dim = Paint()..color = const Color(0x99000000);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dim);
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
