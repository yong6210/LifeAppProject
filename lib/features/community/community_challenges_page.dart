import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/community_challenge.dart';
import 'package:life_app/providers/community_challenges_provider.dart';
import 'package:life_app/services/engagement/engagement_store.dart';
import 'package:life_app/services/engagement/reward_store.dart';

class CommunityChallengesPage extends ConsumerWidget {
  const CommunityChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(communityChallengesProvider);
    final engagementState = ref.watch(engagementStoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tr('community_title')),
        actions: [
          IconButton(
            tooltip: context.l10n.tr('community_join_button'),
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => _showJoinSheet(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          engagementState.when(
            data: (state) => _EngagementCard(state: state),
            loading: () => const _EngagementShimmer(),
            error: (error, _) => _EngagementError(message: '$error'),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.tr('community_my_challenges'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...challenges.map(
            (challenge) => _ChallengeCard(challenge: challenge),
          ),
          if (challenges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(context.l10n.tr('community_empty_state')),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'community_fab',
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.tr('community_new_challenge')),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final templates = ChallengeTemplate.values;
    ChallengeTemplateInfo infoFor(ChallengeTemplate template) =>
        templateCatalog[template]!;
    var selectedTemplate = templates.first;
    final titleController = TextEditingController(
      text: infoFor(selectedTemplate).title,
    );
    final descriptionController = TextEditingController(
      text: infoFor(selectedTemplate).description,
    );
    var durationDays = infoFor(selectedTemplate).defaultDurationDays;
    var goalMinutes = infoFor(selectedTemplate).defaultGoalMinutes;
    var privacy = ChallengePrivacy.private;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final templateInfo = infoFor(selectedTemplate);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('community_create_title'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.tr('community_create_description'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: templates.map((template) {
                      final info = infoFor(template);
                      final selected = template == selectedTemplate;
                      return ChoiceChip(
                        label: Text(l10n.tr(_templateNameKey(template))),
                        selected: selected,
                        onSelected: (value) {
                          if (!value) return;
                          setState(() {
                            selectedTemplate = template;
                            durationDays = info.defaultDurationDays;
                            goalMinutes = info.defaultGoalMinutes;
                            titleController.text = info.title;
                            descriptionController.text = info.description;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.tr('community_create_name_label'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.tr('community_create_description_label'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SliderRow(
                    label: l10n.tr('community_create_duration_label', {
                      'days': '$durationDays',
                    }),
                    value: durationDays.toDouble(),
                    min: 3,
                    max: 30,
                    divisions: 27,
                    onChanged: (value) =>
                        setState(() => durationDays = value.round()),
                  ),
                  _SliderRow(
                    label: l10n.tr('community_create_goal_label', {
                      'minutes': '$goalMinutes',
                    }),
                    value: goalMinutes.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    onChanged: (value) =>
                        setState(() => goalMinutes = (value / 5).round() * 5),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ChallengePrivacy>(
                    initialValue: privacy,
                    decoration: InputDecoration(
                      labelText: l10n.tr('community_privacy_label'),
                    ),
                    items: ChallengePrivacy.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(l10n.tr(_privacyLabelKey(value))),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => privacy = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final newChallenge = ref
                            .read(communityChallengesProvider.notifier)
                            .createChallenge(
                              template: selectedTemplate,
                              title: titleController.text.trim().isEmpty
                                  ? templateInfo.title
                                  : titleController.text.trim(),
                              description:
                                  descriptionController.text.trim().isEmpty
                                  ? templateInfo.description
                                  : descriptionController.text.trim(),
                              durationDays: durationDays,
                              goalMinutes: goalMinutes,
                              privacy: privacy,
                            );
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.tr('community_create_success')),
                            action: newChallenge.inviteCode != null
                                ? SnackBarAction(
                                    label: l10n.tr('community_copy_invite'),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: newChallenge.inviteCode!,
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                      child: Text(l10n.tr('community_create_submit')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showJoinSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr('community_join_title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tr('community_join_description'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.tr('community_join_placeholder'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final member = ChallengeMember(
                      id: 'friend_${DateTime.now().millisecondsSinceEpoch}',
                      displayName: l10n.tr('community_join_you'),
                      joinedAt: DateTime.now(),
                    );
                    final success = ref
                        .read(communityChallengesProvider.notifier)
                        .joinByInviteCode(controller.text, member);
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? l10n.tr('community_join_success')
                              : l10n.tr('community_join_error'),
                        ),
                      ),
                    );
                  },
                  child: Text(l10n.tr('community_join_submit')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EngagementCard extends ConsumerWidget {
  const _EngagementCard({required this.state});

  final UserEngagementState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.tr('community_balance_title'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  l10n.tr('community_coin_balance', {
                    'coins': '${state.coins}',
                  }),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Chip(
                  avatar: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    l10n.tr('community_streak_days', {
                      'days': '${state.streakDays}',
                    }),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.card_giftcard, size: 18),
                  label: Text(
                    l10n.tr('community_premium_passes', {
                      'count': '${state.premiumWeekPasses}',
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.dailyQuestCompleted
                        ? null
                        : () async {
                            await ref
                                .read(engagementStoreProvider.notifier)
                                .completeDailyQuest();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.tr('community_daily_reward'),
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      state.dailyQuestCompleted
                          ? l10n.tr('community_daily_completed')
                          : l10n.tr('community_daily_complete'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _SpendCoinsButton(state: state),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendCoinsButton extends ConsumerWidget {
  const _SpendCoinsButton({required this.state});

  final UserEngagementState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rewardAsync = ref.watch(rewardStoreProvider);
    return FilledButton.icon(
      onPressed: () => _showStoreSheet(context, ref, l10n, rewardAsync),
      icon: const Icon(Icons.shopping_bag_outlined),
      label: Text(l10n.tr('community_store_button')),
    );
  }

  Future<void> _showStoreSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AsyncValue<RewardState> rewardAsync,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final rewardState = rewardAsync.asData?.value;
        final premiumUntil = rewardState?.premiumActiveUntil;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr('community_store_button'),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _RewardTile(
                icon: Icons.music_note,
                title: l10n.tr('community_store_music_pack'),
                price: 200,
                coinLabel: l10n.tr('community_coin_label'),
                unlockedLabel: l10n.tr('community_item_unlocked'),
                isUnlocked: rewardState?.musicUnlocked ?? false,
                onPurchase: () async {
                  final success = await ref
                      .read(engagementStoreProvider.notifier)
                      .spendCoins(200);
                  if (!sheetContext.mounted) return success;
                  if (success) {
                    await ref
                        .read(rewardStoreProvider.notifier)
                        .unlockMusicPack();
                  }
                  return success;
                },
                successMessage: l10n.tr('community_purchase_music'),
                failureMessage: l10n.tr('community_purchase_insufficient'),
              ),
              _RewardTile(
                icon: Icons.workspace_premium_outlined,
                title: l10n.tr('community_store_premium_month'),
                price: 0,
                coinLabel: l10n.tr('community_coin_label'),
                subtitle: premiumUntil == null
                    ? l10n.tr('community_premium_passes', {
                        'count': '${state.premiumWeekPasses}',
                      })
                    : l10n.tr('community_premium_active_until', {
                        'date': DateFormat.yMd().add_Hm().format(
                          premiumUntil.toLocal(),
                        ),
                      }),
                isUnlocked: (rewardState?.premiumActive ?? false),
                onPurchase: () async {
                  if (state.premiumWeekPasses <= 0) {
                    return false;
                  }
                  await ref
                      .read(engagementStoreProvider.notifier)
                      .consumePremiumPass();
                  await ref
                      .read(rewardStoreProvider.notifier)
                      .activatePremiumForDays(7);
                  return true;
                },
                successMessage: l10n.tr('community_purchase_premium_month'),
                failureMessage: l10n.tr('community_purchase_insufficient'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.icon,
    required this.title,
    required this.price,
    required this.coinLabel,
    required this.successMessage,
    required this.failureMessage,
    required this.onPurchase,
    this.isUnlocked = false,
    this.unlockedLabel,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final int price;
  final String coinLabel;
  final String successMessage;
  final String failureMessage;
  final bool Function()? onPurchaseDeprecated = null;
  final Future<bool> Function() onPurchase;
  final bool isUnlocked;
  final String? unlockedLabel;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle ??
            (isUnlocked
                ? (unlockedLabel ?? l10n.tr('community_item_unlocked'))
                : '$price $coinLabel'),
      ),
      trailing: isUnlocked
          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
          : FilledButton(
              onPressed: () async {
                final success = await onPurchase();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? successMessage : failureMessage),
                  ),
                );
              },
              child: Text(l10n.tr('community_buy')),
            ),
    );
  }
}

class _EngagementShimmer extends StatelessWidget {
  const _EngagementShimmer();

  @override
  Widget build(BuildContext context) {
    return const Card(child: SizedBox(height: 120));
  }
}

class _EngagementError extends StatelessWidget {
  const _EngagementError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('community_balance_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge});

  final CommunityChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final members = challenge.members;
    final focusAverage = members.isEmpty
        ? 0
        : (members.map((m) => m.focusMinutes).reduce((a, b) => a + b) /
                  members.length)
              .round();
    final remainingDays = challenge.endDate.difference(DateTime.now()).inDays;
    final statusLabel = switch (challenge.status) {
      ChallengeStatus.active => l10n.tr('community_status_active'),
      ChallengeStatus.upcoming => l10n.tr('community_status_upcoming'),
      ChallengeStatus.completed => l10n.tr('community_status_completed'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForTemplate(challenge.template)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(statusLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    l10n.tr('community_goal_minutes', {
                      'minutes': '${challenge.goalMinutesPerDay}',
                    }),
                  ),
                ),
                Chip(
                  label: Text(
                    l10n.tr('community_days_remaining', {
                      'days': '${remainingDays.clamp(0, 99)}',
                    }),
                  ),
                ),
                Chip(label: Text(l10n.tr(_privacyLabelKey(challenge.privacy)))),
                Chip(
                  label: Text(
                    l10n.tr('community_member_count', {
                      'count': '${members.length}',
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tr('community_focus_average', {'minutes': '$focusAverage'}),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _MemberAvatars(members: members),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(communityChallengesProvider.notifier)
                          .leave(challenge.id, 'owner');
                    },
                    child: Text(l10n.tr('community_leave')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(communityChallengesProvider.notifier)
                          .updateProgress(
                            challengeId: challenge.id,
                            memberId: 'owner',
                            focusMinutes:
                                challenge.members
                                    .firstWhere((m) => m.id == 'owner')
                                    .focusMinutes +
                                15,
                          );
                    },
                    child: Text(l10n.tr('community_log_focus_action')),
                  ),
                ),
              ],
            ),
            if (challenge.inviteCode != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: challenge.inviteCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.tr('community_copy_invite_success')),
                    ),
                  );
                },
                icon: const Icon(Icons.share),
                label: Text(
                  l10n.tr('community_invite_code', {
                    'code': challenge.inviteCode!,
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForTemplate(ChallengeTemplate template) {
    switch (template) {
      case ChallengeTemplate.focusSprint:
        return Icons.bolt;
      case ChallengeTemplate.restReset:
        return Icons.self_improvement;
      case ChallengeTemplate.sleepWindDown:
        return Icons.nightlight_round;
    }
  }
}

class _MemberAvatars extends StatelessWidget {
  const _MemberAvatars({required this.members});

  final List<ChallengeMember> members;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: members
          .map(
            (member) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    member.displayName.characters.first.toUpperCase(),
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(member.displayName, style: theme.textTheme.bodySmall),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

String _templateNameKey(ChallengeTemplate template) {
  switch (template) {
    case ChallengeTemplate.focusSprint:
      return 'community_template_focus';
    case ChallengeTemplate.restReset:
      return 'community_template_rest';
    case ChallengeTemplate.sleepWindDown:
      return 'community_template_sleep';
  }
}

String _privacyLabelKey(ChallengePrivacy privacy) {
  switch (privacy) {
    case ChallengePrivacy.private:
      return 'community_privacy_private';
    case ChallengePrivacy.codeInvite:
      return 'community_privacy_code';
    case ChallengePrivacy.public:
      return 'community_privacy_public';
  }
}
