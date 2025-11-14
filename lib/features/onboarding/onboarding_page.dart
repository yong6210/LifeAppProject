import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/providers/remote_config_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/remote_config/remote_config_service.dart';
import 'package:life_app/l10n/app_localizations.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _controller;
  int _currentIndex = 0;
  late final DateTime _startedAt;
  String? _lastLoggedVariant;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startedAt = DateTime.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfigAsync = ref.watch(remoteConfigProvider);
    final config = remoteConfigAsync.maybeWhen(
      data: (snapshot) => snapshot,
      orElse: () => null,
    );
    final variant = config?.onboardingVariant ?? 'default';
    if (_lastLoggedVariant != variant) {
      _lastLoggedVariant = variant;
      AnalyticsService.setUserProperty('onboarding_variant', variant);
    }
    final pages = _resolvePages(config);
    final totalPages = pages.length;
    final displayIndex = totalPages == 0
        ? 0
        : _currentIndex.clamp(0, totalPages - 1);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('onboarding_appbar_title')),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: totalPages,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final page = pages[index];
                switch (page) {
                  case final _OnboardingInfoPage infoPage:
                    return _InfoPageView(page: infoPage);
                  case final _OnboardingPersonaPage _:
                    return _PersonaSelectionView(
                      controller: _controller,
                      variant: variant,
                      startedAt: _startedAt,
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tr('onboarding_progress', {
                      'current': '${displayIndex + 1}',
                      'total': '$totalPages',
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 160,
                  child: FilledButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final currentPage = totalPages > 0
                          ? pages[displayIndex]
                          : null;
                      if (currentPage != null) {
                        await _logStepComplete(
                          currentPage,
                          variant,
                          isManualPersonaSelection:
                              currentPage is _OnboardingPersonaPage,
                        );
                      }
                      if (displayIndex < totalPages - 1) {
                        await _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        await ref
                            .read(settingsMutationControllerProvider.notifier)
                            .completeOnboarding();
                        await AnalyticsService.logEvent('onboarding_complete', {
                          'variant': variant,
                          'duration_sec': DateTime.now()
                              .difference(_startedAt)
                              .inSeconds,
                        });
                        if (!mounted) return;
                        navigator.pop(true);
                      }
                    },
                    child: Text(
                      displayIndex == totalPages - 1
                          ? l10n.tr('onboarding_start_button')
                          : l10n.tr('onboarding_next_button'),
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

  Future<void> _logStepComplete(
    Object page,
    String variant, {
    bool isManualPersonaSelection = false,
  }) async {
    String? stepId;
    final params = <String, String>{'variant': variant};
    if (page is _OnboardingInfoPage) {
      stepId = page.titleKey;
    } else if (page is _OnboardingPersonaPage) {
      stepId = 'persona_selection';
      if (!isManualPersonaSelection) {
        // No explicit user action yet; skip logging until selection or finish.
        return;
      }
      params['choice'] = 'skip';
    }
    if (stepId == null) return;
    params['step_id'] = stepId;
    await AnalyticsService.logEvent('onboarding_step_complete', params);
  }
}

class _OnboardingInfoPage {
  const _OnboardingInfoPage({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  final IconData icon;
  final String titleKey;
  final String bodyKey;
}

class _OnboardingPersonaPage {
  const _OnboardingPersonaPage();
}

List<Object> _resolvePages(RemoteConfigSnapshot? config) {
  final defaultPages = List<Object>.from(_defaultOnboardingPages);
  if (config == null) {
    return defaultPages;
  }

  switch (config.onboardingVariant) {
    case 'persona_first':
      defaultPages.removeWhere((element) => element is _OnboardingPersonaPage);
      defaultPages.insert(0, _onboardingPersonaStep);
      return defaultPages;
    case 'short_intro':
      return <Object>[defaultPages.first, _onboardingPersonaStep];
    default:
      return defaultPages;
  }
}

class _InfoPageView extends StatelessWidget {
  const _InfoPageView({required this.page});

  final _OnboardingInfoPage page;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Icon(
                  page.icon,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.tr(page.titleKey),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.tr(page.bodyKey),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonaSelectionView extends ConsumerWidget {
  const _PersonaSelectionView({
    required this.controller,
    required this.variant,
    required this.startedAt,
  });

  final PageController controller;
  final String variant;
  final DateTime startedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  l10n.tr('onboarding_persona_heading'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.tr('onboarding_persona_subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ..._personaTemplates.map(
                  (template) => Card(
                    child: ListTile(
                      leading: Icon(
                        template.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(l10n.tr(template.titleKey)),
                      subtitle: Text(l10n.tr(template.bodyKey)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        try {
                          AnalyticsService.logEvent(
                            'onboarding_step_complete',
                            {
                              'step_id': 'persona_selection',
                              'variant': variant,
                              'choice': template.titleKey,
                            },
                          );
                          final mutations = ref.read(
                            settingsMutationControllerProvider.notifier,
                          );
                          await mutations.savePreset(template.minutes);
                          await mutations.completeOnboarding();
                          await AnalyticsService.logEvent(
                            'onboarding_complete',
                            {
                              'variant': variant,
                              'duration_sec': DateTime.now()
                                  .difference(startedAt)
                                  .inSeconds,
                              'choice': template.titleKey,
                            },
                          );
                          if (context.mounted) Navigator.pop(context, true);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.tr('onboarding_preset_error', {
                                    'error': '$error',
                                  }),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonaTemplate {
  const _PersonaTemplate({
    required this.titleKey,
    required this.bodyKey,
    required this.icon,
    required this.minutes,
  });

  final String titleKey;
  final String bodyKey;
  final IconData icon;
  final Map<String, int> minutes;
}

const _onboardingPersonaStep = _OnboardingPersonaPage();

const _defaultOnboardingPages = <Object>[
  _OnboardingInfoPage(
    icon: Icons.timer_outlined,
    titleKey: 'onboarding_intro_focus_title',
    bodyKey: 'onboarding_intro_focus_body',
  ),
  _OnboardingInfoPage(
    icon: Icons.cloud_sync_outlined,
    titleKey: 'onboarding_intro_backup_title',
    bodyKey: 'onboarding_intro_backup_body',
  ),
  _onboardingPersonaStep,
];

const _personaTemplates = <_PersonaTemplate>[
  _PersonaTemplate(
    titleKey: 'onboarding_persona_student_title',
    bodyKey: 'onboarding_persona_student_body',
    icon: Icons.school_outlined,
    minutes: {'focus': 25, 'rest': 5, 'workout': 10, 'sleep': 30},
  ),
  _PersonaTemplate(
    titleKey: 'onboarding_persona_knowledge_title',
    bodyKey: 'onboarding_persona_knowledge_body',
    icon: Icons.laptop_mac_outlined,
    minutes: {'focus': 50, 'rest': 10, 'workout': 15, 'sleep': 35},
  ),
  _PersonaTemplate(
    titleKey: 'onboarding_persona_wellbeing_title',
    bodyKey: 'onboarding_persona_wellbeing_body',
    icon: Icons.self_improvement_outlined,
    minutes: {'focus': 20, 'rest': 10, 'workout': 20, 'sleep': 45},
  ),
];
