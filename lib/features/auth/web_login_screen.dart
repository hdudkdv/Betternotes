import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../sync/cloud_session.dart';
import 'auth_repository.dart';

class WebLoginScreen extends ConsumerStatefulWidget {
  const WebLoginScreen({super.key});

  @override
  ConsumerState<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends ConsumerState<WebLoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn(Future<void> Function() signIn) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await signInAndLoadCloud(ref, signIn, context: context);
      if (!mounted) return;
      if (!ref.read(authProvider).signedIn) {
        setState(() => _busy = false);
        return;
      }
      context.go('/');
    } catch (error) {
      if (!mounted) return;
      final failure = error is AuthFailure ? error : AuthFailure.map(error);
      setState(() {
        _busy = false;
        _error = failure.cancelled ? null : failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/branding/app_icon.png',
                      width: 96,
                      height: 96,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.appTitle,
                    style: AppTheme.headline(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.webLoginHeadline,
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.webLoginBody,
                    textAlign: TextAlign.center,
                    style: AppTheme.body(color: AppTheme.inkMuted),
                  ),
                  const SizedBox(height: 28),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(color: AppTheme.danger, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _signIn(
                            ref.read(authProvider.notifier).signInWithGoogle,
                          ),
                    icon: const Icon(Icons.g_mobiledata_rounded),
                    label: Text(l10n.signInGoogle),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _signIn(
                            ref.read(authProvider.notifier).signInWithApple,
                          ),
                    icon: const Icon(Icons.apple),
                    label: Text(l10n.signInApple),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 18),
                    const CircularProgressIndicator(),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
