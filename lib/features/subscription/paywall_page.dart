import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:life_app/core/subscriptions/revenuecat_keys.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/analytics/growth_kpi_events.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  String? _selectedPackageId;
  String? _lastViewKey;
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = ref
        .watch(todaySummaryProvider)
        .maybeWhen(data: (value) => value, orElse: TodaySummary.new);
    final streak = ref
        .watch(streakCountProvider)
        .maybeWhen(data: (value) => value, orElse: () => 0);
    final focusGoal = ref.watch(settingsFutureProvider).maybeWhen(
          data: (settings) =>
              settings.focusMinutes > 0 ? settings.focusMinutes : 25,
          orElse: () => 25,
        );
    final weeklyTotals = ref.watch(weeklyTotalsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => SummaryTotals(
            focusMinutes: 0,
            restMinutes: 0,
            workoutMinutes: 0,
            sleepMinutes: 0,
          ),
        );
    const workoutGoal = 30;
    const sleepGoalMinutes = 8 * 60;
    final completion = ((((today.focus / focusGoal).clamp(0.0, 1.0) +
                    (today.workout / workoutGoal).clamp(0.0, 1.0) +
                    (today.sleep / sleepGoalMinutes).clamp(0.0, 1.0)) /
                3) *
            100)
        .round();
    final averageDailyMinutes = (weeklyTotals.totalMinutes / 7).round();
    final momentumScore =
        ((streak * 6) + completion + (averageDailyMinutes / 2))
            .clamp(0, 100)
            .round();
    final nextStreakTarget = streak < 7
        ? 7
        : streak < 21
            ? 21
            : 50;
    final daysToTarget = math.max(nextStreakTarget - streak, 0);

    final revenueCatAsync = ref.watch(revenueCatControllerProvider);
    final experimentAsync = ref.watch(paywallExperimentProvider);
    final hasConfiguredKey = _hasPlatformKey();
    final supportsPurchases = isRevenueCatSupportedPlatform();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('paywall_title')),
        actions: [
          IconButton(
            tooltip: l10n.tr('paywall_restore_tooltip'),
            icon: const Icon(Icons.restore),
            onPressed: supportsPurchases && hasConfiguredKey && !_isPurchasing
                ? _restorePurchases
                : null,
          ),
        ],
      ),
      body: !supportsPurchases
          ? _PlaceholderMessage(
              message: l10n.tr('paywall_unsupported_platform'),
            )
          : !hasConfiguredKey
              ? _PlaceholderMessage(
                  message: l10n.tr('paywall_missing_key_message'),
                )
              : revenueCatAsync.when(
                  data: (state) => experimentAsync.when(
                    data: (experiment) {
                      if (state == null) {
                        return _PlaceholderMessage(
                          message: l10n.tr('paywall_info_unavailable'),
                        );
                      }
                      final variant = experiment.variant;

                      final packages = _orderedPackages(
                        state.offerings.current?.availablePackages ?? [],
                        emphasizeAnnual: experiment.emphasizeAnnualPlan,
                      );
                      if (packages.isEmpty) {
                        return _PlaceholderMessage(
                          message: l10n.tr('paywall_no_products'),
                        );
                      }

                      _selectedPackageId ??= packages.first.identifier;
                      final selectedPackage = packages.firstWhere(
                        (pkg) => pkg.identifier == _selectedPackageId,
                        orElse: () => packages.first,
                      );
                      final selectedProduct = selectedPackage.storeProduct;

                      _trackViewOnce(
                        source: 'paywall_page',
                        variant: variant,
                        experimentId: experiment.experimentId,
                        emphasizeAnnual: experiment.emphasizeAnnualPlan,
                        packages: packages,
                        hasOfferings: state.offerings.current != null,
                      );

                      return DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFFBF5),
                              Color(0xFFF9F3EA),
                              Color(0xFFF5F4FF),
                            ],
                          ),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            _PaywallHero(variant: variant),
                            const SizedBox(height: 12),
                            _ValueProofCard(
                              streak: streak,
                              completionPercent: completion,
                            ),
                            const SizedBox(height: 12),
                            _PersonalProofPreviewCard(
                              weeklyTotalMinutes: weeklyTotals.totalMinutes,
                              averageDailyMinutes: averageDailyMinutes,
                              momentumScore: momentumScore,
                              nextStreakTarget: nextStreakTarget,
                              daysToTarget: daysToTarget,
                            ),
                            const SizedBox(height: 12),
                            if (state.isPro) ...[
                              _ActiveSubscriptionCard(),
                              const SizedBox(height: 12),
                            ],
                            _BenefitsCard(variant: variant),
                            const SizedBox(height: 12),
                            _PlanSelectionCard(
                              packages: packages,
                              selectedId: selectedPackage.identifier,
                              emphasizeAnnual: experiment.emphasizeAnnualPlan,
                              onSelected: (pkg, index) => _selectPackage(
                                pkg,
                                variant,
                                experiment.experimentId,
                                index,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _CheckoutCard(
                              title: selectedProduct.title,
                              subtitle: selectedProduct.description,
                              price: selectedProduct.priceString,
                              purchasing: _isPurchasing,
                              onPurchase: state.isPro
                                  ? null
                                  : () => _purchaseSelected(
                                        selectedPackage,
                                        variant,
                                        experiment.experimentId,
                                      ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _PlaceholderMessage(
                      message: l10n.tr('paywall_error_message', {
                        'error': '$error',
                      }),
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _PlaceholderMessage(
                    message:
                        l10n.tr('paywall_fetch_error', {'error': '$error'}),
                  ),
                ),
    );
  }

  Future<void> _restorePurchases() async {
    final pageContext = context;
    try {
      await ref.read(revenueCatControllerProvider.notifier).restorePurchases();
      if (!pageContext.mounted) return;
      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(content: Text(pageContext.l10n.tr('paywall_restore_success'))),
      );
    } catch (error) {
      if (!pageContext.mounted) return;
      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(
          content: Text(
            pageContext.l10n.tr('paywall_restore_error', {'error': '$error'}),
          ),
        ),
      );
    }
  }

  List<Package> _orderedPackages(
    List<Package> input, {
    required bool emphasizeAnnual,
  }) {
    final list = [...input];
    list.sort(
      (a, b) => _packagePriority(a, emphasizeAnnual)
          .compareTo(_packagePriority(b, emphasizeAnnual)),
    );
    return list;
  }

  int _packagePriority(Package pkg, bool emphasizeAnnual) {
    if (emphasizeAnnual) {
      switch (pkg.packageType) {
        case PackageType.annual:
          return 0;
        case PackageType.monthly:
          return 1;
        case PackageType.weekly:
          return 2;
        case PackageType.lifetime:
          return 3;
        default:
          return 4;
      }
    }
    switch (pkg.packageType) {
      case PackageType.monthly:
        return 0;
      case PackageType.annual:
        return 1;
      case PackageType.weekly:
        return 2;
      case PackageType.lifetime:
        return 3;
      default:
        return 4;
    }
  }

  void _trackViewOnce({
    required String source,
    required PaywallVariant variant,
    required String experimentId,
    required bool emphasizeAnnual,
    required List<Package> packages,
    required bool hasOfferings,
  }) {
    final key = '${variant.name}:$experimentId:$emphasizeAnnual:'
        '${packages.length}:$hasOfferings';
    if (_lastViewKey == key) return;
    _lastViewKey = key;

    unawaited(
      AnalyticsService.logEvent('paywall_view', {
        'variant': variant.name,
        'experiment_id': experimentId,
        'annual_emphasis': emphasizeAnnual,
        'hasOfferings': hasOfferings,
      }),
    );
    unawaited(
      GrowthKpiEvents.paywallView(
        source: source,
        variant: variant.name,
        experimentId: experimentId,
        annualEmphasis: emphasizeAnnual,
        hasOfferings: hasOfferings,
        packageCount: packages.length,
      ),
    );
  }

  void _selectPackage(
    Package package,
    PaywallVariant variant,
    String experimentId,
    int index,
  ) {
    if (_selectedPackageId == package.identifier) return;
    setState(() {
      _selectedPackageId = package.identifier;
    });
    unawaited(
      GrowthKpiEvents.paywallPlanSelect(
        variant: variant.name,
        experimentId: experimentId,
        productId: package.storeProduct.identifier,
        packageType: package.packageType.name,
        rank: index + 1,
      ),
    );
    unawaited(
      AnalyticsService.logEvent(
        'paywall_plan_select',
        {
          'variant': variant.name,
          'experiment_id': experimentId,
          'product': package.storeProduct.identifier,
          'package_type': package.packageType.name,
          'rank': index + 1,
        },
      ),
    );
  }

  Future<void> _purchaseSelected(
    Package package,
    PaywallVariant variant,
    String experimentId,
  ) async {
    if (_isPurchasing) return;
    final l10n = context.l10n;
    final product = package.storeProduct;

    setState(() => _isPurchasing = true);
    unawaited(
      GrowthKpiEvents.paywallPurchaseStart(
        variant: variant.name,
        experimentId: experimentId,
        productId: product.identifier,
        packageType: package.packageType.name,
      ),
    );

    try {
      await ref.read(revenueCatControllerProvider.notifier).purchasePackage(
            package,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.tr('paywall_purchase_success', {'product': product.title}),
          ),
        ),
      );
      unawaited(
        AnalyticsService.logEvent(
          'paywall_purchase',
          {
            'variant': variant.name,
            'experiment_id': experimentId,
            'product': product.identifier,
            'package_type': package.packageType.name,
          },
        ),
      );
      unawaited(
        GrowthKpiEvents.paywallPurchaseSuccess(
          variant: variant.name,
          experimentId: experimentId,
          productId: product.identifier,
          packageType: package.packageType.name,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.tr('paywall_purchase_error', {
                'error': '$error',
              }),
            ),
          ),
        );
      }
      unawaited(
        AnalyticsService.logEvent(
          'paywall_purchase_error',
          {
            'variant': variant.name,
            'experiment_id': experimentId,
            'product': product.identifier,
            'package_type': package.packageType.name,
            'error': error.toString(),
          },
        ),
      );
      unawaited(
        GrowthKpiEvents.paywallPurchaseFailure(
          variant: variant.name,
          experimentId: experimentId,
          productId: product.identifier,
          packageType: package.packageType.name,
          error: error.toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }
}

class _PaywallHero extends StatelessWidget {
  const _PaywallHero({required this.variant});

  final PaywallVariant variant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (variant) {
      PaywallVariant.focusValue => l10n.tr('paywall_focus_title'),
      PaywallVariant.backupSecurity => l10n.tr('paywall_backup_title'),
      PaywallVariant.coachMomentum => l10n.tr('paywall_coach_title'),
    };
    final subtitle = switch (variant) {
      PaywallVariant.focusValue => l10n.tr('paywall_focus_body'),
      PaywallVariant.backupSecurity => l10n.tr('paywall_backup_body'),
      PaywallVariant.coachMomentum => l10n.tr('paywall_coach_body'),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2638), Color(0xFF314267)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ValueProofCard extends StatelessWidget {
  const _ValueProofCard({
    required this.streak,
    required this.completionPercent,
  });

  final int streak;
  final int completionPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SectionCard(
      title: l10n.tr('paywall_proof_title'),
      subtitle: l10n.tr('paywall_proof_body'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Pill(
            label: l10n.tr('paywall_proof_streak', {'days': '$streak'}),
          ),
          _Pill(
            label: l10n.tr('paywall_proof_completion', {
              'percent': '$completionPercent',
            }),
          ),
        ],
      ),
    );
  }
}

class _PersonalProofPreviewCard extends StatelessWidget {
  const _PersonalProofPreviewCard({
    required this.weeklyTotalMinutes,
    required this.averageDailyMinutes,
    required this.momentumScore,
    required this.nextStreakTarget,
    required this.daysToTarget,
  });

  final int weeklyTotalMinutes;
  final int averageDailyMinutes;
  final int momentumScore;
  final int nextStreakTarget;
  final int daysToTarget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final milestoneLabel = daysToTarget == 0
        ? l10n.tr('paywall_preview_goal_reached')
        : l10n.tr('paywall_preview_next_milestone', {
            'days': '$daysToTarget',
            'target': '$nextStreakTarget',
          });

    return _SectionCard(
      title: l10n.tr('paywall_preview_title'),
      subtitle: l10n.tr('paywall_preview_subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                label: l10n.tr('paywall_preview_weekly_total', {
                  'minutes': '$weeklyTotalMinutes',
                }),
              ),
              _Pill(
                label: l10n.tr('paywall_preview_daily_average', {
                  'minutes': '$averageDailyMinutes',
                }),
              ),
              _Pill(
                label: l10n.tr('paywall_preview_momentum_score', {
                  'score': '$momentumScore',
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            milestoneLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.variant});

  final PaywallVariant variant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final benefits = _benefitsForVariant(variant, l10n);
    return _SectionCard(
      title: l10n.tr('paywall_value_section_title'),
      subtitle: l10n.tr('paywall_value_section_subtitle'),
      child: Column(
        children: [
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.check_circle_outline, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanSelectionCard extends StatelessWidget {
  const _PlanSelectionCard({
    required this.packages,
    required this.selectedId,
    required this.emphasizeAnnual,
    required this.onSelected,
  });

  final List<Package> packages;
  final String selectedId;
  final bool emphasizeAnnual;
  final void Function(Package package, int index) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _SectionCard(
      title: l10n.tr('paywall_plan_section_title'),
      subtitle: l10n.tr('paywall_plan_section_subtitle'),
      child: Column(
        children: [
          for (var index = 0; index < packages.length; index++)
            _PlanChoiceTile(
              package: packages[index],
              selected: packages[index].identifier == selectedId,
              showRecommendedBadge: _isRecommendedPackage(packages[index]),
              rank: index + 1,
              onTap: () => onSelected(packages[index], index),
            ),
        ],
      ),
    );
  }

  bool _isRecommendedPackage(Package package) {
    if (emphasizeAnnual) {
      return package.packageType == PackageType.annual;
    }
    return package.packageType == PackageType.monthly;
  }
}

class _PlanChoiceTile extends StatelessWidget {
  const _PlanChoiceTile({
    required this.package,
    required this.selected,
    required this.showRecommendedBadge,
    required this.rank,
    required this.onTap,
  });

  final Package package;
  final bool selected;
  final bool showRecommendedBadge;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: l10n.tr('paywall_package_semantics_label', {
          'product': package.storeProduct.title,
          'price': package.storeProduct.priceString,
        }),
        hint: l10n.tr('paywall_package_semantics_hint'),
        child: Material(
          color: selected
              ? const Color(0xFFEAF1FF)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onTap,
                    icon: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Text(
                              package.storeProduct.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (showRecommendedBadge)
                              _Pill(label: l10n.tr('paywall_badge_best_value')),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          package.storeProduct.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        package.storeProduct.priceString,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#$rank',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.purchasing,
    required this.onPurchase,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool purchasing;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3DBCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('paywall_checkout_title'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tr('paywall_checkout_subtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: purchasing ? null : onPurchase,
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: Text(
              purchasing
                  ? l10n.tr('paywall_purchase_processing')
                  : '${l10n.tr('paywall_purchase_button')} · $price',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSubscriptionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SectionCard(
      title: l10n.tr('paywall_active_title'),
      subtitle: l10n.tr('paywall_active_body'),
      child: const SizedBox.shrink(),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3DBCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (child is! SizedBox) ...[
            const SizedBox(height: 10),
            child,
          ],
        ],
      ),
    );
  }
}

class _PlaceholderMessage extends StatelessWidget {
  const _PlaceholderMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

bool _hasPlatformKey() {
  if (kIsWeb) {
    return true;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return !RevenueCatKeys.androidKey.startsWith('REPLACE_WITH');
    case TargetPlatform.iOS:
      return !RevenueCatKeys.iosKey.startsWith('REPLACE_WITH');
    default:
      // Allow desktop previews without enforcing mobile keys.
      return true;
  }
}

List<String> _benefitsForVariant(
  PaywallVariant variant,
  AppLocalizations l10n,
) {
  switch (variant) {
    case PaywallVariant.focusValue:
      return [
        l10n.tr('paywall_focus_benefit_1'),
        l10n.tr('paywall_focus_benefit_2'),
        l10n.tr('paywall_focus_benefit_3'),
      ];
    case PaywallVariant.backupSecurity:
      return [
        l10n.tr('paywall_backup_benefit_1'),
        l10n.tr('paywall_backup_benefit_2'),
        l10n.tr('paywall_backup_benefit_3'),
      ];
    case PaywallVariant.coachMomentum:
      return [
        l10n.tr('paywall_coach_benefit_1'),
        l10n.tr('paywall_coach_benefit_2'),
        l10n.tr('paywall_coach_benefit_3'),
      ];
  }
}
