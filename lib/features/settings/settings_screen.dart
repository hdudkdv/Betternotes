import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme.dart';
import '../../data/models/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../billing/revenuecat_billing.dart';
import '../billing/subscription_paywall_sheet.dart';
import '../editor/domain/editor_gestures.dart';
import '../editor/domain/ink_models.dart';
import '../entitlements/entitlement_model.dart';
import '../entitlements/rewarded_ad_mock.dart';
import '../entitlements/rewarded_ad_service.dart';
import '../import_export/import_export_providers.dart';
import '../lan_sync/classroom_auto_connect.dart';
import '../library/providers/library_providers.dart';
import '../onboarding/app_tour.dart';
import '../planner/education_settings.dart';
import '../planner/planner_model.dart';
import '../sync/sync_engine.dart';
import '../timetable/timetable_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  TextStyle get _sectionTitle => AppTheme.headline(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppTheme.ink,
  );

  TextStyle get _body => AppTheme.body(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppTheme.inkMuted,
  );

  TextStyle get _label => AppTheme.body(
    fontWeight: FontWeight.w700,
    fontSize: 15,
    color: AppTheme.ink,
  );

  String _lookLabel(AppLocalizations l10n, AppLook look) => switch (look) {
    AppLook.studio => l10n.lookStudio,
    AppLook.paper => l10n.lookPaper,
    AppLook.fresh => l10n.lookFresh,
    AppLook.mono => l10n.lookMono,
  };

  String _lookHint(AppLocalizations l10n, AppLook look) => switch (look) {
    AppLook.studio => l10n.lookStudioHint,
    AppLook.paper => l10n.lookPaperHint,
    AppLook.fresh => l10n.lookFreshHint,
    AppLook.mono => l10n.lookMonoHint,
  };

  String _tierLabel(AppLocalizations l10n, AppTier tier) => switch (tier) {
    AppTier.free => l10n.tierFree,
    AppTier.pro => l10n.tierPro,
    AppTier.proPlus => l10n.tierProPlus,
    AppTier.teacher => l10n.tierTeacher,
  };

  String _featureLabel(AppLocalizations l10n, String key) => switch (key) {
    FeatureKeys.premiumPaper => l10n.featurePremiumPaper,
    FeatureKeys.premiumCover => l10n.featurePremiumCover,
    FeatureKeys.audioTranscription => l10n.featureAudioTranscription,
    FeatureKeys.pdfCompress => l10n.featurePdfCompress,
    FeatureKeys.handwritingOcr => l10n.featureHandwritingOcr,
    FeatureKeys.noForcedAds => l10n.featureNoForcedAds,
    FeatureKeys.sessionCollab => l10n.featureSessionCollab,
    FeatureKeys.asyncCollab => l10n.featureAsyncCollab,
    FeatureKeys.whiteboard => l10n.featureWhiteboard,
    FeatureKeys.cloudSync => l10n.featureCloudSync,
    _ => key,
  };

  String _syncLabel(
    AppLocalizations l10n,
    SyncStatus status,
  ) => switch (status) {
    SyncStatus.idle => l10n.syncStatusIdle,
    SyncStatus.upToDate => l10n.syncStatusUpToDate,
    SyncStatus.syncing => l10n.syncStatusSyncing,
    SyncStatus.synced => l10n.syncStatusSynced,
    SyncStatus.firebaseNotConfigured => l10n.syncStatusFirebaseNotConfigured,
    SyncStatus.authenticationRequired => l10n.syncStatusAuthenticationRequired,
    SyncStatus.preparingCloud => l10n.syncStatusPreparingCloud,
    SyncStatus.paused => l10n.syncStatusPaused,
  };

  Future<void> _signIn(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() signIn,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await signIn();
      await ref.read(syncEngineProvider).bootstrapCloud();
      ref.invalidate(plannerProvider);
      ref.invalidate(timetableProvider);
      ref.invalidate(entitlementProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cloudSyncError('$error'))));
    }
  }

  Future<void> _editSupportDetails(
    BuildContext context,
    WidgetRef ref,
    EntitlementState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final url = TextEditingController(text: state.supportUrl);
    final costs = TextEditingController(text: '${state.serverCostEuro}');
    final covered = TextEditingController(
      text: '${state.donationsCoveredEuro}',
    );
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editSupportDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: url,
              decoration: InputDecoration(labelText: l10n.supportUrl),
            ),
            TextField(
              controller: costs,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.serverCosts),
            ),
            TextField(
              controller: covered,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.amountCovered),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (save == true) {
      await ref
          .read(entitlementProvider.notifier)
          .setSupportMeta(
            supportUrl: url.text.trim().isEmpty
                ? state.supportUrl
                : url.text.trim(),
            serverCostEuro: int.tryParse(costs.text),
            donationsCoveredEuro: int.tryParse(covered.text),
          );
    }
    url.dispose();
    costs.dispose();
    covered.dispose();
  }

  Future<void> _handlePurchaseOutcome(
    BuildContext context,
    WidgetRef ref,
    PurchaseOutcome outcome,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final billing = ref.read(revenueCatBillingProvider);
    final message = switch (outcome) {
      PurchaseOutcome.success =>
        billing.hasNotisPro
            ? l10n.restorePurchasesSuccess
            : l10n.restorePurchasesEmpty,
      PurchaseOutcome.cancelled => l10n.purchaseCancelled,
      PurchaseOutcome.unavailable => l10n.paywallUnavailable,
      PurchaseOutcome.error => l10n.purchaseFailed(billing.error ?? ''),
    };
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final sync = ref.watch(syncEngineProvider);
    final entitlements = ref.watch(entitlementProvider);
    final auth = ref.watch(authProvider);
    final billing = ref.watch(revenueCatBillingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings, style: AppTheme.headline())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _SettingsSection(
            title: l10n.sectionGeneral,
            titleStyle: _sectionTitle,
            initiallyExpanded: true,
            children: [
              Text(l10n.language, style: _label),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'system',
                    label: Text(l10n.systemLanguage),
                  ),
                  ButtonSegment(value: 'de', label: Text(l10n.german)),
                  ButtonSegment(value: 'en', label: Text(l10n.english)),
                ],
                selected: {settings.localeCode},
                onSelectionChanged: (s) =>
                    ref.read(settingsProvider.notifier).setLocaleCode(s.first),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.roleSection,
            titleStyle: _sectionTitle,
            children: [
              Text(l10n.roleSectionHint, style: _body),
              const SizedBox(height: 10),
              SegmentedButton<AppUserRole>(
                segments: [
                  ButtonSegment(
                    value: AppUserRole.student,
                    icon: const Icon(Icons.school_outlined),
                    label: Text(l10n.roleStudent),
                  ),
                  ButtonSegment(
                    value: AppUserRole.teacher,
                    icon: const Icon(Icons.co_present_outlined),
                    label: Text(l10n.roleTeacher),
                  ),
                ],
                selected: {settings.userRole ?? AppUserRole.student},
                onSelectionChanged: (selection) => ref
                    .read(settingsProvider.notifier)
                    .setUserRole(selection.first),
              ),
              if (settings.isTeacher) ...[
                const SizedBox(height: 12),
                Text(l10n.setupTeacherTrack, style: _label),
                const SizedBox(height: 6),
                SegmentedButton<TeacherTrack>(
                  segments: [
                    ButtonSegment(
                      value: TeacherTrack.studying,
                      label: Text(l10n.teacherTrackStudying),
                    ),
                    ButtonSegment(
                      value: TeacherTrack.qualified,
                      label: Text(l10n.teacherTrackQualified),
                    ),
                  ],
                  selected: {settings.teacherTrack ?? TeacherTrack.qualified},
                  onSelectionChanged: (selection) async {
                    final track = selection.first;
                    await ref
                        .read(settingsProvider.notifier)
                        .setTeacherTrack(track);
                    await ref
                        .read(settingsProvider.notifier)
                        .setEducationLevel(
                          track == TeacherTrack.studying
                              ? EducationLevel.university
                              : settings.educationLevel ==
                                    EducationLevel.university
                              ? EducationLevel.sek2
                              : settings.educationLevel,
                        );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dashboard_outlined),
                  title: Text(l10n.teacherWorkspace, style: _label),
                  subtitle: Text(l10n.teacherOverviewHint, style: _body),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/teacher'),
                ),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tour_outlined),
                title: Text(l10n.tutorialStart, style: _label),
                subtitle: Text(l10n.tutorialOfferBody, style: _body),
                onTap: () {
                  ref.read(pendingAppTourProvider.notifier).state = true;
                  context.go('/');
                },
              ),
              if (settings.userRole == AppUserRole.student &&
                  ref
                          .watch(sharedPreferencesProvider)
                          .getBool(ClassroomAutoConnect.askedKey) ==
                      true)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: ref.watch(classroomAutoConnectEnabledProvider),
                  onChanged: (value) async {
                    await ref
                        .read(sharedPreferencesProvider)
                        .setBool(ClassroomAutoConnect.enabledKey, value);
                    ref
                            .read(classroomAutoConnectEnabledProvider.notifier)
                            .state =
                        value;
                  },
                  title: Text(l10n.classroomAutoConnectSetting, style: _label),
                  subtitle: Text(
                    l10n.classroomAutoConnectSettingHint,
                    style: _body,
                  ),
                ),
            ],
          ),
          _SettingsSection(
            title: l10n.appearance,
            titleStyle: _sectionTitle,
            initiallyExpanded: true,
            children: [
              Text(l10n.appearanceHint, style: _body),
              const SizedBox(height: 12),
              for (final look in AppLook.values)
                _LookOption(
                  look: look,
                  selected: settings.look == look,
                  title: _lookLabel(l10n, look),
                  subtitle: _lookHint(l10n, look),
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setLook(look),
                ),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeModeSystem),
                    icon: const Icon(Icons.brightness_auto_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeModeLight),
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeModeDark),
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) =>
                    ref.read(settingsProvider.notifier).setThemeMode(s.first),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.writing,
            titleStyle: _sectionTitle,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.fingerPanZoom, style: _label),
                subtitle: Text(l10n.fingerPanZoomHint, style: _body),
                value: settings.fingerPanZoom,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setFingerPanZoom(v),
              ),
              const SizedBox(height: 8),
              Text(l10n.pageBrowseMode, style: _label),
              const SizedBox(height: 6),
              SegmentedButton<PageBrowseMode>(
                segments: [
                  ButtonSegment(
                    value: PageBrowseMode.swipeHorizontal,
                    label: Text(l10n.browseSwipe),
                    icon: const Icon(Icons.swipe_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: PageBrowseMode.scrollVertical,
                    label: Text(l10n.browseScroll),
                    icon: const Icon(Icons.swap_vert, size: 18),
                  ),
                ],
                selected: {settings.pageBrowseMode},
                onSelectionChanged: (s) => ref
                    .read(settingsProvider.notifier)
                    .setPageBrowseMode(s.first),
              ),
              const SizedBox(height: 12),
              Text(l10n.defaultTemplate, style: _label),
              const SizedBox(height: 6),
              SegmentedButton<PageTemplate>(
                segments: [
                  ButtonSegment(
                    value: PageTemplate.blank,
                    label: Text(l10n.blank),
                  ),
                  ButtonSegment(
                    value: PageTemplate.lined,
                    label: Text(l10n.lined),
                  ),
                  ButtonSegment(
                    value: PageTemplate.grid,
                    label: Text(l10n.grid),
                  ),
                ],
                selected: {settings.defaultTemplate},
                onSelectionChanged: (s) => ref
                    .read(settingsProvider.notifier)
                    .setDefaultTemplate(s.first),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.gesturesSection,
            titleStyle: _sectionTitle,
            children: [
              Text(l10n.gesturesSectionHint, style: _body),
              const SizedBox(height: 12),
              _GestureActionTile(
                label: l10n.gesturePencilDoubleTap,
                value: settings.pencilDoubleTapAction,
                labelStyle: _label,
                bodyStyle: _body,
                onChanged: (a) => ref
                    .read(settingsProvider.notifier)
                    .setGestureAction(EditorGestureSlot.pencilDoubleTap, a),
              ),
              _GestureActionTile(
                label: l10n.gesturePencilSqueeze,
                value: settings.pencilSqueezeAction,
                labelStyle: _label,
                bodyStyle: _body,
                onChanged: (a) => ref
                    .read(settingsProvider.notifier)
                    .setGestureAction(EditorGestureSlot.pencilSqueeze, a),
              ),
              _GestureActionTile(
                label: l10n.gestureTwoFingerTap,
                value: settings.twoFingerTapAction,
                labelStyle: _label,
                bodyStyle: _body,
                onChanged: (a) => ref
                    .read(settingsProvider.notifier)
                    .setGestureAction(EditorGestureSlot.twoFingerTap, a),
              ),
              _GestureActionTile(
                label: l10n.gestureThreeFingerSwipeLeft,
                value: settings.threeFingerSwipeLeftAction,
                labelStyle: _label,
                bodyStyle: _body,
                onChanged: (a) => ref
                    .read(settingsProvider.notifier)
                    .setGestureAction(
                      EditorGestureSlot.threeFingerSwipeLeft,
                      a,
                    ),
              ),
              _GestureActionTile(
                label: l10n.gestureThreeFingerSwipeRight,
                value: settings.threeFingerSwipeRightAction,
                labelStyle: _label,
                bodyStyle: _body,
                onChanged: (a) => ref
                    .read(settingsProvider.notifier)
                    .setGestureAction(
                      EditorGestureSlot.threeFingerSwipeRight,
                      a,
                    ),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.schoolSection,
            titleStyle: _sectionTitle,
            children: [
              SegmentedButton<EducationLevel>(
                segments: [
                  for (final level in EducationLevel.values)
                    ButtonSegment(value: level, label: Text(level.label(l10n))),
                ],
                selected: {settings.educationLevel},
                onSelectionChanged: (s) => ref
                    .read(settingsProvider.notifier)
                    .setEducationLevel(s.first),
              ),
              const SizedBox(height: 6),
              Text(settings.educationLevel.scaleHint(l10n), style: _body),
              if (settings.educationLevel == EducationLevel.university) ...[
                const SizedBox(height: 12),
                Text(l10n.targetEcts, style: _label),
                const SizedBox(height: 6),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 180, label: Text('180')),
                    ButtonSegment(value: 210, label: Text('210')),
                    ButtonSegment(value: 240, label: Text('240')),
                    ButtonSegment(value: 300, label: Text('300')),
                  ],
                  selected: {
                    {180, 210, 240, 300}.contains(settings.targetEcts)
                        ? settings.targetEcts
                        : 180,
                  },
                  onSelectionChanged: (s) => ref
                      .read(settingsProvider.notifier)
                      .setTargetEcts(s.first),
                ),
              ],
              if (settings.educationLevel == EducationLevel.sek2) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.abiCourseCount, style: _label),
                  subtitle: Text('${settings.abiCourseCount}', style: _body),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .setAbiCourseCount(settings.abiCourseCount - 1),
                        icon: const Icon(Icons.remove),
                      ),
                      IconButton(
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .setAbiCourseCount(settings.abiCourseCount + 1),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 4, label: Text(l10n.abiExams4)),
                    ButtonSegment(value: 5, label: Text(l10n.abiExams5)),
                  ],
                  selected: {settings.abiExamCount},
                  onSelectionChanged: (s) => ref
                      .read(settingsProvider.notifier)
                      .setAbiExamCount(s.first),
                ),
              ],
              const SizedBox(height: 12),
              Text(l10n.federalState, style: _label),
              const SizedBox(height: 6),
              DropdownButtonFormField<GermanState>(
                initialValue: settings.germanState,
                decoration: const InputDecoration(),
                items: [
                  for (final s in GermanState.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.label(l10n),
                        style: AppTheme.body(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).setGermanState(v);
                  }
                },
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.sectionSubscription,
            titleStyle: _sectionTitle,
            initiallyExpanded: true,
            children: [
              if (kDebugMode) ...[
                Text(l10n.developerTools, style: _label),
                const SizedBox(height: 2),
                Text(l10n.developerTierHint, style: _body),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tier in AppTier.values)
                      ChoiceChip(
                        label: Text(
                          _tierLabel(l10n, tier),
                          style: AppTheme.body(
                            fontWeight: FontWeight.w700,
                            color: entitlements.tier == tier
                                ? AppTheme.onAccent
                                : AppTheme.ink,
                          ),
                        ),
                        selected: entitlements.tier == tier,
                        selectedColor: AppTheme.accent,
                        onSelected: (_) => ref
                            .read(entitlementProvider.notifier)
                            .setTier(tier),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (billing.error != null) ...[
                Text(
                  billing.error!,
                  style: AppTheme.body(color: AppTheme.danger, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  billing.hasNotisPro
                      ? Icons.workspace_premium
                      : Icons.workspace_premium_outlined,
                ),
                title: Text(
                  billing.hasNotisPro ? l10n.notisProActive : l10n.choosePlan,
                  style: _label,
                ),
                subtitle: Text(
                  billing.hasNotisPro
                      ? l10n.manageSubscriptionHint
                      : l10n.choosePlanHint,
                  style: _body,
                ),
                onTap: () async {
                  if (billing.hasNotisPro) {
                    await billing.presentCustomerCenter();
                    return;
                  }
                  final outcome = await showSubscriptionPaywall(context, ref);
                  if (!context.mounted) return;
                  await _handlePurchaseOutcome(context, ref, outcome);
                },
              ),
              if (billing.configured && billing.hasNotisPro)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: Text(l10n.manageSubscription, style: _label),
                  subtitle: Text(l10n.manageSubscriptionHint, style: _body),
                  onTap: () => billing.presentCustomerCenter(),
                ),
              if (billing.configured)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restore),
                  title: Text(l10n.restorePurchases, style: _label),
                  onTap: () async {
                    final outcome = await billing.restorePurchases();
                    if (!context.mounted) return;
                    await _handlePurchaseOutcome(context, ref, outcome);
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storefront_outlined),
                title: Text(l10n.marketplace, style: _label),
                subtitle: Text(l10n.marketplaceHint, style: _body),
                onTap: () => context.push('/marketplace'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.monetization_on_outlined),
                title: Text(
                  l10n.coinsBalance(entitlements.coins),
                  style: _label,
                ),
                trailing: TextButton(
                  onPressed: () => runRewardedUnlock(
                    context: context,
                    ref: ref,
                    coinReward: 15,
                  ),
                  child: Text(l10n.watchAdForCoins),
                ),
              ),
              if (ref.read(rewardedAdServiceProvider).privacyOptionsRequired)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.adPrivacyOptions, style: _label),
                  subtitle: Text(l10n.adPrivacyOptionsHint, style: _body),
                  onTap: () =>
                      ref.read(rewardedAdServiceProvider).showPrivacyOptions(),
                ),
              const SizedBox(height: 8),
              for (final key in FeatureKeys.all)
                _FeatureRow(
                  label: _featureLabel(l10n, key),
                  unlocked: entitlements.hasAccess(key),
                  coinCost: FeatureKeys.coinCost(key),
                  onUnlockCoins: () async {
                    final ok = await ref
                        .read(entitlementProvider.notifier)
                        .unlockWithCoins(key);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? l10n.featureUnlocked : l10n.notEnoughCoins,
                        ),
                      ),
                    );
                  },
                  onWatchAd: () => runRewardedUnlock(
                    context: context,
                    ref: ref,
                    featureKey: key,
                  ),
                ),
            ],
          ),
          _SettingsSection(
            title: l10n.sectionSupport,
            titleStyle: _sectionTitle,
            children: [
              Text(l10n.supportBody, style: _body),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: entitlements.supportUrl),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.supportLinkCopied)),
                  );
                },
                icon: const Icon(Icons.coffee_outlined),
                label: Text(l10n.supportBuyCoffee),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.serverCostsLabel(entitlements.serverCostEuro),
                style: _label,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.serverCostsCovered(entitlements.donationsCoveredEuro),
                style: _body,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    (entitlements.donationsCoveredEuro /
                            entitlements.serverCostEuro.clamp(1, 9999))
                        .clamp(0.0, 1.0),
                backgroundColor: AppTheme.ink.withValues(alpha: 0.08),
                color: AppTheme.accent,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
              ),
              TextButton.icon(
                onPressed: () =>
                    _editSupportDetails(context, ref, entitlements),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.editSupportDetails),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.sectionSyncPreview,
            titleStyle: _sectionTitle,
            children: [
              Text(
                auth.firebaseAvailable
                    ? l10n.cloudSyncOffline
                    : l10n.firebaseSetupRequired,
                style: _body,
              ),
              const SizedBox(height: 10),
              if (auth.firebaseAvailable)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(l10n.cloudAccount, style: _label),
                  subtitle: Text(
                    auth.signedIn
                        ? l10n.signedInAs(
                            auth.user!.displayName ??
                                auth.user!.email ??
                                auth.user!.uid,
                          )
                        : l10n.cloudSyncOffline,
                    style: _body,
                  ),
                  trailing: auth.signedIn
                      ? TextButton(
                          onPressed: () =>
                              ref.read(authProvider.notifier).signOut(),
                          child: Text(l10n.signOut),
                        )
                      : null,
                ),
              if (auth.firebaseAvailable && !auth.signedIn)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _signIn(
                        context,
                        ref,
                        ref.read(authProvider.notifier).signInWithGoogle,
                      ),
                      icon: const Icon(Icons.g_mobiledata_rounded),
                      label: Text(l10n.signInGoogle),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _signIn(
                        context,
                        ref,
                        ref.read(authProvider.notifier).signInWithApple,
                      ),
                      icon: const Icon(Icons.apple),
                      label: Text(l10n.signInApple),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_syncLabel(l10n, sync.syncStatus), style: _label),
                subtitle: Text(
                  sync.errorMessage ??
                      (sync.pending == 0
                          ? l10n.syncQueueEmpty
                          : l10n.syncPending(sync.pending)),
                  style: _body,
                ),
                trailing: sync.syncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: l10n.flushSync,
                        onPressed: () => ref.read(syncEngineProvider).flush(),
                        icon: const Icon(Icons.cloud_sync_outlined),
                      ),
              ),
              if (sync.lastSyncAt != null)
                Text(
                  l10n.lastSync(
                    DateFormat('dd.MM.yyyy HH:mm').format(sync.lastSyncAt!),
                  ),
                  style: _body,
                ),
            ],
          ),
          _SettingsSection(
            title: l10n.backupSection,
            titleStyle: _sectionTitle,
            children: [
              Text(l10n.backupSectionHint, style: _body),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.backup_outlined),
                title: Text(l10n.backupExport, style: _label),
                subtitle: Text(l10n.backupExportHint, style: _body),
                onTap: () async {
                  final prefs = ref.read(sharedPreferencesProvider);
                  try {
                    await ref
                        .read(backupServiceProvider)
                        .shareBackup(prefs: prefs);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore_outlined),
                title: Text(l10n.backupRestore, style: _label),
                subtitle: Text(l10n.backupRestoreHint, style: _body),
                onTap: () async {
                  final merge = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.backupRestore),
                      content: Text(l10n.backupRestoreMergeQuestion),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.backupReplace),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.backupMerge),
                        ),
                      ],
                    ),
                  );
                  if (merge == null || !context.mounted) return;
                  final prefs = ref.read(sharedPreferencesProvider);
                  try {
                    final count = await ref
                        .read(backupServiceProvider)
                        .restoreFromPicker(prefs: prefs, merge: merge);
                    if (!context.mounted) return;
                    ref.invalidate(notebooksProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.backupRestored(count))),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.about,
            titleStyle: _sectionTitle,
            children: [
              Text(l10n.aboutBody, style: _body),
              const SizedBox(height: 12),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  if (info == null) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    l10n.appVersion(info.version, info.buildNumber),
                    style: _body,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(l10n.legalSection, style: _label),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.privacyPolicy, style: _label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/legal/privacy'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.gavel_outlined),
                title: Text(l10n.termsOfService, style: _label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/legal/terms'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.business_outlined),
                title: Text(l10n.impressum, style: _label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/legal/impressum'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.openLicenses, style: _label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Notis',
                    applicationLegalese: l10n.aboutBody,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.titleStyle,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final TextStyle titleStyle;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(title, style: titleStyle),
          children: children,
        ),
      ),
    );
  }
}

/// Row with a miniature of the look, so the choice is visible before applying.
class _LookOption extends StatelessWidget {
  const _LookOption({
    required this.look,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AppLook look;
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: selected ? AppTheme.accent : AppTheme.outline,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              _LookPreview(look: look),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppTheme.accent : AppTheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny stand-in for the app: chrome bar, page, accent.
class _LookPreview extends StatelessWidget {
  const _LookPreview({required this.look});

  final AppLook look;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(look, Theme.of(context).brightness);
    return Container(
      width: 56,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 12,
            color: palette.chrome,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.chromeActive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Container(height: 3, color: palette.onChromeMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Container(width: 30, height: 4, color: palette.ink),
                  Container(width: 40, height: 3, color: palette.inkMuted),
                  Container(width: 18, height: 6, color: palette.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GestureActionTile extends StatelessWidget {
  const _GestureActionTile({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.labelStyle,
    required this.bodyStyle,
  });

  final String label;
  final EditorGestureAction value;
  final ValueChanged<EditorGestureAction> onChanged;
  final TextStyle labelStyle;
  final TextStyle bodyStyle;

  static String actionLabel(AppLocalizations l10n, EditorGestureAction action) {
    switch (action) {
      case EditorGestureAction.none:
        return l10n.gestureActionNone;
      case EditorGestureAction.toggleEraser:
        return l10n.gestureActionToggleEraser;
      case EditorGestureAction.previousTool:
        return l10n.gestureActionPreviousTool;
      case EditorGestureAction.openToolWheel:
        return l10n.gestureActionOpenToolWheel;
      case EditorGestureAction.undo:
        return l10n.gestureActionUndo;
      case EditorGestureAction.redo:
        return l10n.gestureActionRedo;
      case EditorGestureAction.nextPage:
        return l10n.gestureActionNextPage;
      case EditorGestureAction.previousPage:
        return l10n.gestureActionPreviousPage;
      case EditorGestureAction.exportPage:
        return l10n.gestureActionExportPage;
      case EditorGestureAction.cyclePenColor:
        return l10n.gestureActionCyclePenColor;
      case EditorGestureAction.fitZoom:
        return l10n.gestureActionFitZoom;
      case EditorGestureAction.goBack:
        return l10n.gestureActionGoBack;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 4),
          DropdownButtonFormField<EditorGestureAction>(
            key: ValueKey(value),
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: [
              for (final action in EditorGestureAction.values)
                DropdownMenuItem(
                  value: action,
                  child: Text(actionLabel(l10n, action), style: bodyStyle),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.unlocked,
    required this.coinCost,
    required this.onUnlockCoins,
    required this.onWatchAd,
  });

  final String label;
  final bool unlocked;
  final int coinCost;
  final VoidCallback onUnlockCoins;
  final VoidCallback onWatchAd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        color: unlocked ? AppTheme.accent : AppTheme.inkMuted,
      ),
      title: Text(
        label,
        style: AppTheme.body(fontWeight: FontWeight.w700, color: AppTheme.ink),
      ),
      subtitle: Text(
        unlocked ? l10n.featureAvailable : l10n.unlockWithCoins(coinCost),
        style: AppTheme.body(
          fontWeight: FontWeight.w600,
          color: AppTheme.inkMuted,
          fontSize: 13,
        ),
      ),
      trailing: unlocked
          ? null
          : PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'coins') onUnlockCoins();
                if (v == 'ad') onWatchAd();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'coins',
                  child: Text(l10n.unlockWithCoins(coinCost)),
                ),
                PopupMenuItem(value: 'ad', child: Text(l10n.watchRewardedAd)),
              ],
            ),
    );
  }
}
