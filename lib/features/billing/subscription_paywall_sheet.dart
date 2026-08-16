import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../library/providers/library_providers.dart';
import 'revenuecat_billing.dart';
import 'revenuecat_config.dart';

Future<PurchaseOutcome> showSubscriptionPaywall(
  BuildContext context,
  WidgetRef ref,
) async {
  final role = ref.read(settingsProvider).userRole ?? AppUserRole.student;
  final audience = role == AppUserRole.teacher
      ? PaywallAudience.teacher
      : PaywallAudience.student;
  final billing = ref.read(revenueCatBillingProvider);
  if (billing.configured) {
    await billing.refresh();
  }
  if (!context.mounted) return PurchaseOutcome.cancelled;
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
  const _SubscriptionPaywallSheet({required this.audience});

  final PaywallAudience audience;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final billing = ref.watch(revenueCatBillingProvider);
    final packages = billing.packagesForAudience(audience);
    final teacher = audience == PaywallAudience.teacher;
    final plans = <_PlanCopy>[
      if (teacher) ...[
        _PlanCopy(
          title: l10n.planLehrerLite,
          price: l10n.planLehrerLitePrice,
          points: [
            l10n.planPointWeeklyBackup,
            l10n.planPointTeacherExchange,
            l10n.planPointPartialMarketplace,
          ],
        ),
        _PlanCopy(
          title: l10n.planLehrerPro,
          price: l10n.planLehrerProPrice,
          points: [
            l10n.planPointDailyBackup,
            l10n.planPointFullMarketplace,
            l10n.planPointClassLoans,
          ],
        ),
      ] else ...[
        _PlanCopy(
          title: l10n.planSchuelerLite,
          price: l10n.planSchuelerLitePrice,
          points: [l10n.planPointWeeklyBackup, l10n.planPointSyncFive],
        ),
        _PlanCopy(
          title: l10n.planSchuelerPro,
          price: l10n.planSchuelerProPrice,
          points: [
            l10n.planPointDailyBackup,
            l10n.planPointSyncUnlimited,
            l10n.planPointMarketplaceThree,
          ],
        ),
      ],
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                l10n.choosePlan,
                style: AppTheme.headline(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.choosePlanHint,
                style: AppTheme.body(color: AppTheme.inkMuted),
              ),
              if (billing.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  billing.error!,
                  style: AppTheme.body(color: AppTheme.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              if (packages.isNotEmpty)
                for (final package in packages)
                  _StorePackageTile(
                    package: package,
                    onBuy: () async {
                      final outcome = await billing.purchase(package);
                      if (!context.mounted) return;
                      Navigator.pop(context, outcome);
                    },
                  )
              else
                for (final plan in plans) _CatalogPlanCard(plan: plan),
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

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          product.title,
          style: AppTheme.body(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(product.description, style: AppTheme.body(fontSize: 13)),
        trailing: FilledButton(
          onPressed: onBuy,
          child: Text(product.priceString),
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
