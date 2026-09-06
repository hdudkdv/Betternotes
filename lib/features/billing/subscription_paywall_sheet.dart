import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/launch_gates.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/coming_soon_sheet.dart';
import '../legal/legal_urls.dart';
import '../library/providers/library_providers.dart';
import 'plan_catalog.dart';
import 'revenuecat_billing.dart';
import 'revenuecat_config.dart';

Future<void> presentInAppPurchases(BuildContext context, WidgetRef ref) async {
  if (!LaunchGates.commerceEnabled) {
    await showComingSoonSheet(context);
    return;
  }
  final billing = ref.read(revenueCatBillingProvider);
  if (billing.configured) {
    await billing.refresh();
  }
  if (!context.mounted) return;
  if (billing.hasNotisPro) {
    await billing.presentCustomerCenter();
    return;
  }
  context.push('/iap');
}

Future<void> showPurchaseOutcomeMessage(
  BuildContext context,
  PurchaseOutcome outcome,
) async {
  if (outcome == PurchaseOutcome.cancelled) return;
  final l10n = AppLocalizations.of(context)!;
  final message = switch (outcome) {
    PurchaseOutcome.success => l10n.purchaseSuccess,
    PurchaseOutcome.cancelled => l10n.purchaseCancelled,
    PurchaseOutcome.unavailable => l10n.storeProductsUnavailable,
    PurchaseOutcome.error => l10n.storeProductsUnavailable,
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
  final role = ref.read(settingsProvider).userRole ?? AppUserRole.student;
  final audience = role == AppUserRole.teacher
      ? PaywallAudience.teacher
      : PaywallAudience.student;
  final billing = ref.read(revenueCatBillingProvider);
  if (billing.configured) {
    await billing.refresh();
  }
  if (!context.mounted) return PurchaseOutcome.cancelled;
  // Always show the in-app product list. The native RevenueCat paywall
  // can present empty in App Review sandbox and then return "cancelled",
  // which hid In-App Purchases (Guideline 2.1(b)).
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
    final packages = billing.packagesForAudience(audience);
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
      if (asPage) {
        await showPurchaseOutcomeMessage(context, outcome);
        return;
      }
      if (context.mounted) Navigator.pop(context, outcome);
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
              if (packages.isNotEmpty)
                for (final package in packages)
                  _StorePackageTile(
                    package: package,
                    onBuy: () async {
                      final outcome = await billing.purchase(package);
                      if (!context.mounted) return;
                      if (outcome == PurchaseOutcome.success ||
                          outcome == PurchaseOutcome.cancelled) {
                        await finish(outcome);
                      }
                    },
                  )
              else ...[
                Text(
                  l10n.storeProductsUnavailable,
                  style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: billing.configured
                      ? () => billing.refresh()
                      : null,
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
                onPressed: billing.configured
                    ? () async {
                        final outcome = await billing.restorePurchases();
                        if (!context.mounted) return;
                        await finish(outcome);
                      }
                    : null,
                child: Text(l10n.restorePurchases),
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

class _StorePackageTile extends StatelessWidget {
  const _StorePackageTile({required this.package, required this.onBuy});

  final Package package;
  final VoidCallback onBuy;

  String _length(AppLocalizations l10n) {
    return switch (package.packageType) {
      PackageType.annual => l10n.subscriptionLengthYear,
      PackageType.monthly => l10n.subscriptionLengthMonth,
      PackageType.weekly => l10n.subscriptionLengthWeek,
      PackageType.sixMonth => l10n.subscriptionLengthSixMonths,
      PackageType.lifetime => l10n.subscriptionLengthLifetime,
      _ => l10n.subscriptionLengthYear,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final product = package.storeProduct;
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
                child: Text(product.priceString),
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
