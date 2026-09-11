import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/launch_gates.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/coming_soon_sheet.dart';
import '../auth/auth_repository.dart';
import '../legal/legal_urls.dart';
import '../library/providers/library_providers.dart';
import 'plan_catalog.dart';
import 'revenuecat_billing.dart';
import 'revenuecat_config.dart';

PaywallAudience _paywallAudienceFor(WidgetRef ref) {
  final role = ref.read(settingsProvider).userRole ?? AppUserRole.student;
  return role == AppUserRole.teacher
      ? PaywallAudience.teacher
      : PaywallAudience.student;
}

Future<PurchaseOutcome> _presentRolePaywall(
  BuildContext context,
  WidgetRef ref,
) async {
  final billing = ref.read(revenueCatBillingProvider);
  if (billing.configured) {
    await billing.refresh();
  } else {
    await billing.initialize(appUserId: ref.read(authProvider).user?.uid);
  }
  if (!context.mounted) return PurchaseOutcome.unavailable;
  if (!billing.paywallSupported) return PurchaseOutcome.unavailable;
  return billing.presentPaywall(
    audience: _paywallAudienceFor(ref),
    context: context,
  );
}

Future<void> presentInAppPurchases(BuildContext context, WidgetRef ref) async {
  if (!LaunchGates.commerceEnabled) {
    await showComingSoonSheet(context);
    return;
  }
  final outcome = await _presentRolePaywall(context, ref);
  if (!context.mounted) return;
  if (outcome == PurchaseOutcome.success) {
    await showPurchaseOutcomeMessage(context, outcome);
    return;
  }
  if (outcome == PurchaseOutcome.cancelled) return;
  if (outcome == PurchaseOutcome.error) {
    final billing = ref.read(revenueCatBillingProvider);
    await showPurchaseOutcomeMessage(
      context,
      outcome,
      detail: billing.userMessage,
    );
    return;
  }
  context.push('/iap');
}

Future<void> showPurchaseOutcomeMessage(
  BuildContext context,
  PurchaseOutcome outcome, {
  String? detail,
}) async {
  if (outcome == PurchaseOutcome.cancelled) return;
  final l10n = AppLocalizations.of(context)!;
  final message = switch (outcome) {
    PurchaseOutcome.success => l10n.purchaseSuccess,
    PurchaseOutcome.cancelled => l10n.purchaseCancelled,
    PurchaseOutcome.unavailable => l10n.storeProductsUnavailable,
    PurchaseOutcome.error =>
      (detail != null && detail.trim().isNotEmpty)
          ? l10n.purchaseFailed(detail)
          : l10n.storeProductsUnavailable,
  };
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<PurchaseOutcome> showSubscriptionPaywall(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!LaunchGates.commerceEnabled) {
    await showComingSoonSheet(context);
    return PurchaseOutcome.cancelled;
  }
  final presented = await _presentRolePaywall(context, ref);
  if (!context.mounted) return PurchaseOutcome.cancelled;
  if (presented == PurchaseOutcome.success ||
      presented == PurchaseOutcome.cancelled ||
      presented == PurchaseOutcome.error) {
    return presented;
  }
  // Fallback product list if the dashboard paywall is missing (App Review).
  final audience = _paywallAudienceFor(ref);
  final outcome = await showModalBottomSheet<PurchaseOutcome>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SubscriptionPaywallSheet(audience: audience),
  );
  return outcome ?? PurchaseOutcome.cancelled;
}

/// Full page App Review can find: title is exactly "In-App Purchases".
class InAppPurchasesScreen extends ConsumerWidget {
  const InAppPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final role = ref.watch(settingsProvider).userRole ?? AppUserRole.student;
    final audience = role == AppUserRole.teacher
        ? PaywallAudience.teacher
        : PaywallAudience.student;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inAppPurchases, style: AppTheme.headline()),
      ),
      body: _SubscriptionPaywallSheet(audience: audience, asPage: true),
    );
  }
}

class _PlanCopy {
  const _PlanCopy({
    required this.title,
    required this.price,
    required this.points,
  });

  final String title;
  final String price;
  final List<String> points;
}

class _SubscriptionPaywallSheet extends ConsumerWidget {
  const _SubscriptionPaywallSheet({
    required this.audience,
    this.asPage = false,
  });

  final PaywallAudience audience;
  final bool asPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final billing = ref.watch(revenueCatBillingProvider);
    final products = billing.productsForAudience(audience);
    final german = Localizations.localeOf(context).languageCode == 'de';
    final role = audience == PaywallAudience.teacher
        ? AppUserRole.teacher
        : AppUserRole.student;
    final plans = [
      for (final plan in PlanCatalog.paidFor(role))
        _PlanCopy(
          title: plan.title(german),
          price: plan.price(german),
          points: plan.points(german),
        ),
    ];

    Future<void> finish(PurchaseOutcome outcome) async {
      if (!context.mounted) return;
      if (asPage || outcome != PurchaseOutcome.success) {
        await showPurchaseOutcomeMessage(
          context,
          outcome,
          detail: billing.userMessage,
        );
        return;
      }
      Navigator.pop(context, outcome);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!asPage) ...[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                asPage ? l10n.inAppPurchases : l10n.choosePlan,
                style: AppTheme.headline(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                asPage ? l10n.inAppPurchasesHint : l10n.choosePlanHint,
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 16),
              if (products.isNotEmpty)
                for (final product in products)
                  _StoreProductTile(
                    product: product,
                    busy: billing.purchasing,
                    onBuy: billing.purchasing
                        ? null
                        : () async {
                            final outcome = await billing.purchaseProduct(
                              product,
                            );
                            if (!context.mounted) return;
                            await finish(outcome);
                          },
                  )
              else ...[
                FilledButton.icon(
                  onPressed: billing.purchasing
                      ? null
                      : () async {
                          final outcome = await billing.presentPaywall(
                            audience: audience,
                            context: context,
                          );
                          if (!context.mounted) return;
                          if (outcome == PurchaseOutcome.success ||
                              outcome == PurchaseOutcome.cancelled ||
                              outcome == PurchaseOutcome.error) {
                            await finish(outcome);
                          }
                        },
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: Text(l10n.openRevenueCatPaywall),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.openRevenueCatPaywallHint,
                  style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.storeProductsUnavailable,
                  style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: billing.purchasing
                      ? null
                      : billing.configured
                      ? () => billing.refresh()
                      : () => billing.initialize(
                          appUserId: ref.read(authProvider).user?.uid,
                        ),
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(l10n.retryStoreProducts),
                ),
                const SizedBox(height: 12),
                for (final plan in plans) _CatalogPlanCard(plan: plan),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.subscriptionLegalNote,
                style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 0,
                children: [
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(LegalUrls.privacy),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l10n.privacyPolicy),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(LegalUrls.terms),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l10n.termsOfUseEula),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(LegalUrls.appleStandardEula),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l10n.appleStandardEula),
                  ),
                ],
              ),
              TextButton(
                onPressed: !billing.configured || billing.purchasing
                    ? null
                    : () async {
                        final outcome = await billing.restorePurchases();
                        if (!context.mounted) return;
                        await finish(outcome);
                      },
                child: Text(l10n.restorePurchases),
              ),
              if (billing.hasNotisPro)
                TextButton(
                  onPressed: billing.purchasing
                      ? null
                      : () => billing.presentCustomerCenter(),
                  child: Text(l10n.manageSubscription),
                ),
              if (!asPage)
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, PurchaseOutcome.cancelled),
                  child: Text(l10n.cancel),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreProductTile extends StatelessWidget {
  const _StoreProductTile({
    required this.product,
    required this.onBuy,
    this.busy = false,
  });

  final StoreProduct product;
  final VoidCallback? onBuy;
  final bool busy;

  String _length(AppLocalizations l10n) {
    switch (product.productCategory) {
      case ProductCategory.nonSubscription:
        return l10n.subscriptionLengthLifetime;
      case ProductCategory.subscription:
      case null:
        break;
    }
    final period = product.subscriptionPeriod?.toLowerCase() ?? '';
    if (period.contains('p1y') || period.contains('year')) {
      return l10n.subscriptionLengthYear;
    }
    if (period.contains('p1m') || period.contains('month')) {
      return l10n.subscriptionLengthMonth;
    }
    if (period.contains('p1w') || period.contains('week')) {
      return l10n.subscriptionLengthWeek;
    }
    if (period.contains('p6m')) {
      return l10n.subscriptionLengthSixMonths;
    }
    return l10n.subscriptionLengthYear;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: AppTheme.body(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(_length(l10n), style: AppTheme.body(fontSize: 13)),
            if (product.description.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                product.description,
                style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onBuy,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(product.priceString),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogPlanCard extends StatelessWidget {
  const _CatalogPlanCard({required this.plan});

  final _PlanCopy plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: AppTheme.body(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  plan.price,
                  style: AppTheme.body(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final point in plan.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $point', style: AppTheme.body(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
