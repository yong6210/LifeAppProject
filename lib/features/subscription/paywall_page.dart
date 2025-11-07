import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:life_app/core/subscriptions/revenuecat_keys.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';
import 'package:life_app/l10n/app_localizations.dart';

class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final revenueCatAsync = ref.watch(revenueCatControllerProvider);
    final variantAsync = ref.watch(paywallVariantProvider);
    final hasConfiguredKey = _hasPlatformKey();
    final supportsPurchases = isRevenueCatSupportedPlatform();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('paywall_title')),
        actions: [
          IconButton(
            tooltip: l10n.tr('paywall_restore_tooltip'),
            icon: const Icon(Icons.restore),
            onPressed: supportsPurchases && hasConfiguredKey
                ? () async {
                    try {
                      await ref
                          .read(revenueCatControllerProvider.notifier)
                          .restorePurchases();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.tr('paywall_restore_success')),
                          ),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.tr('paywall_restore_error', {
                                'error': '$error',
                              }),
                            ),
                          ),
                        );
                      }
                    }
                  }
                : null,
          ),
        ],
      ),
      body: !supportsPurchases
          ? _PlaceholderMessage(
              message: l10n.tr('paywall_unsupported_platform'),
            )
          : !hasConfiguredKey
          ? _PlaceholderMessage(message: l10n.tr('paywall_missing_key_message'))
          : revenueCatAsync.when(
              data: (state) => variantAsync.when(
                data: (variant) {
                  AnalyticsService.logEvent('paywall_view', {
                    'variant': variant.name,
                    'hasOfferings': state?.offerings.current != null,
                  });
                  if (state == null) {
                    return _PlaceholderMessage(
                      message: l10n.tr('paywall_info_unavailable'),
                    );
                  }
                  final packages =
                      state.offerings.current?.availablePackages ?? [];
                  if (packages.isEmpty) {
                    return _PlaceholderMessage(
                      message: l10n.tr('paywall_no_products'),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _PaywallHeader(variant: variant),
                      const SizedBox(height: 16),
                      if (state.isPro)
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('paywall_active_title'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(l10n.tr('paywall_active_body')),
                              ],
                            ),
                          ),
                        ),
                      ...packages.map(
                        (pkg) => _PackageTile(package: pkg, variant: variant),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _PlaceholderMessage(
                  message: l10n.tr('paywall_error_message', {
                    'error': '$error',
                  }),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _PlaceholderMessage(
                message: l10n.tr('paywall_fetch_error', {'error': '$error'}),
              ),
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

class _PackageTile extends ConsumerWidget {
  const _PackageTile({required this.package, required this.variant});

  final Package package;
  final PaywallVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final loading = ref.watch(revenueCatControllerProvider).isLoading;
    final product = package.storeProduct;
    final benefits = _benefitsForVariant(variant, l10n);
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.6);
    final iconSize = math.min(20.0, textScaler.scale(16));
    final packageSemanticLabel = l10n.tr('paywall_package_semantics_label', {
      'product': product.title,
      'price': product.priceString,
    });
    final packageSemanticHint = l10n.tr('paywall_package_semantics_hint');

    return Semantics(
      container: true,
      label: packageSemanticLabel,
      hint: packageSemanticHint,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: theme.textTheme.titleMedium,
                softWrap: true,
              ),
              const SizedBox(height: 4),
              Text(product.description, softWrap: true),
              const SizedBox(height: 8),
              Text(
                product.priceString,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListBody(
                children: benefits
                    .map(
                      (benefit) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(Icons.check, size: iconSize),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(benefit, softWrap: true)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: l10n.tr('paywall_purchase_semantics_label', {
                  'product': product.title,
                }),
                hint: l10n.tr('paywall_purchase_semantics_hint', {
                  'price': product.priceString,
                }),
                child: FilledButton(
                  onPressed: loading
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(revenueCatControllerProvider.notifier)
                                .purchasePackage(package);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.tr('paywall_purchase_success', {
                                      'product': product.title,
                                    }),
                                  ),
                                ),
                              );
                            }
                            AnalyticsService.logEvent('paywall_purchase', {
                              'variant': variant.name,
                              'product': product.identifier,
                            });
                          } catch (error) {
                            if (context.mounted) {
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
                            AnalyticsService.logEvent(
                              'paywall_purchase_error',
                              {
                                'variant': variant.name,
                                'product': product.identifier,
                                'error': error.toString(),
                              },
                            );
                          }
                        },
                  child: Text(
                    loading
                        ? l10n.tr('paywall_purchase_processing')
                        : l10n.tr('paywall_purchase_button'),
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _PaywallHeader extends StatelessWidget {
  const _PaywallHeader({required this.variant});

  final PaywallVariant variant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    switch (variant) {
      case PaywallVariant.focusValue:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('paywall_focus_title'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.tr('paywall_focus_body')),
          ],
        );
      case PaywallVariant.backupSecurity:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('paywall_backup_title'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.tr('paywall_backup_body')),
          ],
        );
    }
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
  }
}
