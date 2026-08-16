import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import 'cloud_session.dart';
import 'sync_engine.dart';

class WebCloudBar extends ConsumerStatefulWidget {
  const WebCloudBar({super.key});

  @override
  ConsumerState<WebCloudBar> createState() => _WebCloudBarState();
}

class _WebCloudBarState extends ConsumerState<WebCloudBar> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.webCloudUpdated)),
      );
    } catch (error) {
      if (!mounted) return;
      final failure = error is AuthFailure ? error : AuthFailure.map(error);
      if (failure.cancelled) {
        setState(() => _busy = false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final sync = ref.watch(syncEngineProvider);
    final signedIn = auth.signedIn;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              signedIn ? l10n.webCloudSignedIn : l10n.webCloudSignInTitle,
              style: AppTheme.body(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              signedIn
                  ? l10n.webCloudSignedInBody(
                      auth.user?.email ?? auth.user?.displayName ?? '',
                    )
                  : l10n.webCloudSignInBody,
              style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!signedIn) ...[
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => signInAndLoadCloud(
                              ref,
                              ref.read(authProvider.notifier).signInWithGoogle,
                            ),
                          ),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 18),
                    label: Text(l10n.signInGoogle),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => signInAndLoadCloud(
                              ref,
                              ref.read(authProvider.notifier).signInWithApple,
                            ),
                          ),
                    icon: const Icon(Icons.apple, size: 18),
                    label: Text(l10n.signInApple),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => loadCloudNotebooks(ref, replaceLocal: true),
                          ),
                    icon: sync.syncing || _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_sync_outlined, size: 18),
                    label: Text(l10n.webReloadFromCloud),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _busy
                        ? null
                        : () => context.push('/import'),
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(l10n.webUploadFiles),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
