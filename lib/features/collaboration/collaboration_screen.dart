import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../entitlements/entitlement_model.dart';
import 'collaboration_service.dart';

class CollaborationScreen extends ConsumerStatefulWidget {
  const CollaborationScreen({super.key, required this.notebookId});

  final String notebookId;

  @override
  ConsumerState<CollaborationScreen> createState() =>
      _CollaborationScreenState();
}

class _CollaborationScreenState extends ConsumerState<CollaborationScreen> {
  final _memberUid = TextEditingController();
  final _comment = TextEditingController();
  CollaborationRole _role = CollaborationRole.editor;
  bool _working = false;

  @override
  void dispose() {
    _memberUid.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (_memberUid.text.trim().isEmpty) return;
    setState(() => _working = true);
    try {
      await ref
          .read(collaborationServiceProvider)
          .invite(
            notebookId: widget.notebookId,
            memberUid: _memberUid.text.trim(),
            role: _role,
          );
      _memberUid.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final service = ref.watch(collaborationServiceProvider);
    final canCloud = auth.signedIn &&
        ref.watch(entitlementProvider).hasAccess(FeatureKeys.sessionCollab);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.collaborate)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.collabLocalTitle,
            style: AppTheme.headline(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.collabLocalBody,
            style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 14.5),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/nearby-sync/${widget.notebookId}'),
            icon: const Icon(Icons.wifi_tethering_rounded),
            label: Text(l10n.nearbySyncTitle),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.collabCloudTitle,
            style: AppTheme.headline(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (!auth.signedIn) ...[
            Text(
              l10n.collaborationSignInRequired,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 14.5),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.login_rounded),
              label: Text(l10n.signIn),
            ),
          ] else if (!canCloud) ...[
            Text(
              l10n.collaborationUpgradeRequired,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 14.5),
            ),
          ] else
            StreamBuilder<Map<String, dynamic>?>(
              stream: service.watchCollaboration(widget.notebookId),
              builder: (context, snapshot) {
                final members = Map<String, dynamic>.from(
                  snapshot.data?['members'] as Map? ?? const {},
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.collabCloudBody,
                      style: AppTheme.body(
                        color: AppTheme.inkMuted,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _memberUid,
                      decoration: InputDecoration(
                        labelText: l10n.collabMemberUid,
                        prefixIcon: const Icon(Icons.person_add_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<CollaborationRole>(
                      initialValue: _role,
                      decoration: InputDecoration(labelText: l10n.collabRole),
                      items: [
                        for (final role in CollaborationRole.values)
                          DropdownMenuItem(
                            value: role,
                            child: Text(role.name),
                          ),
                      ],
                      onChanged: (role) {
                        if (role != null) setState(() => _role = role);
                      },
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: _working ? null : _invite,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(l10n.collabSaveInvite),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.collabMembers,
                      style: AppTheme.headline(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    for (final entry in members.entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: Text(entry.key),
                        subtitle: Text('${entry.value}'),
                        trailing: entry.key == auth.user?.uid
                            ? Icon(Icons.star_rounded, color: AppTheme.accent)
                            : IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => service.revoke(
                                  notebookId: widget.notebookId,
                                  memberUid: entry.key,
                                ),
                              ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        final id = await service.startLiveSession(
                          widget.notebookId,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.collabLiveStarted(id)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.sensors_outlined),
                      label: Text(l10n.collabStartLive),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.collabComments,
                      style: AppTheme.headline(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _comment,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.collabLeaveComment,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send_outlined),
                          onPressed: () async {
                            await service.addComment(
                              notebookId: widget.notebookId,
                              message: _comment.text,
                            );
                            _comment.clear();
                          },
                        ),
                      ),
                    ),
                    StreamBuilder<List<CollaborationComment>>(
                      stream: service.watchComments(widget.notebookId),
                      builder: (context, comments) {
                        final entries = comments.data ?? const [];
                        return Column(
                          children: [
                            for (final comment in entries)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.comment_outlined),
                                title: Text(comment.message),
                                subtitle: Text(comment.authorUid),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
