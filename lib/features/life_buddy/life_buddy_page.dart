import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/life_buddy/life_buddy_models.dart';
import 'package:life_app/features/life_buddy/life_buddy_service.dart';
import 'package:life_app/features/life_buddy/life_buddy_state_controller.dart';
import 'package:life_app/features/life_buddy/life_buddy_ui_helpers.dart';
import 'package:life_app/features/life_buddy/life_buddy_quest_ui.dart';
import 'package:life_app/providers/life_buddy_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/analytics/life_buddy_analytics.dart';
import 'package:life_app/services/engagement/engagement_store.dart';
import 'package:life_app/services/life_buddy/life_buddy_quest_store.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';
import 'package:life_app/widgets/modern_animations.dart';

class LifeBuddyPage extends ConsumerWidget {
  const LifeBuddyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(lifeBuddyStateProvider);
    final buffs = ref.watch(lifeBuddyBuffsProvider);
    final service = ref.watch(lifeBuddyServiceProvider);
    final isPremium = ref.watch(
      premiumStatusProvider.select((value) => value.isPremium),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('라이프 버디')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('라이프 버디 정보를 불러오지 못했어요.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(lifeBuddyStateProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        },
        data: (state) {
          final xpNeeded = service.experienceForNextLevel(state.level);
          final xpProgress = xpNeeded <= 0
              ? 0.0
              : (state.experience / xpNeeded).clamp(0.0, 1.0);
          final slotWidgets = [
            for (final slot in DecorSlot.values)
              _DecorSlotCard(
                slot: slot,
                state: state,
                isPremiumUser: isPremium,
                service: service,
              ),
          ];
          final upcomingDecor = service.upcomingDecor(
            currentLevel: state.level,
            limit: 3,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MoodHeader(state: state),
                const SizedBox(height: 24),
                _ProgressCard(
                  level: state.level,
                  experience: state.experience,
                  xpNeeded: xpNeeded,
                  progress: xpProgress,
                ),
                const SizedBox(height: 24),
                _BuffSummary(buffs: buffs),
                const SizedBox(height: 24),
                _QuestActionCard(level: state.level),
                const SizedBox(height: 24),
                const _CoinBalanceBanner(),
                const SizedBox(height: 24),
                _UpcomingDecorCard(
                  items: upcomingDecor,
                  currentLevel: state.level,
                ),
                const SizedBox(height: 24),
                ...slotWidgets,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MoodHeader extends StatelessWidget {
  const _MoodHeader({required this.state});

  final LifeBuddyState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = describeMood(state.mood, theme);
    final color = details.color;
    return ScaleInAnimation(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AnimatedMoodAvatar(color: color, emoji: details.emoji),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    details.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMoodAvatar extends StatelessWidget {
  const _AnimatedMoodAvatar({required this.color, required this.emoji});

  final Color color;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          ),
          child: child,
        ),
        child: Text(
          emoji,
          key: ValueKey(emoji),
          style: const TextStyle(fontSize: 44),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.level,
    required this.experience,
    required this.xpNeeded,
    required this.progress,
  });

  final int level;
  final double experience;
  final double xpNeeded;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpRemaining = (xpNeeded - experience).clamp(0, xpNeeded).toInt();
    final xpLabel = xpNeeded <= 0
        ? '🎉 최고 레벨에 도달했어요!'
        : '다음 레벨까지 $xpRemaining XP';

    return SlideInAnimation(
      delay: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppTheme.accentOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '레벨 $level',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${experience.toStringAsFixed(0)} / ${xpNeeded.toStringAsFixed(0)} XP',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: progress,
                backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              xpLabel,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BuffSummary extends ConsumerWidget {
  const _BuffSummary({required this.buffs});

  final Map<LifeBuffType, double> buffs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (buffs.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '장식 아이템을 모아서 지속 버프를 활성화해 보세요.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final inventoryAsync = ref.watch(lifeBuddyInventoryProvider);
    final service = ref.watch(lifeBuddyServiceProvider);
    final ownedIds = inventoryAsync.maybeWhen(
      data: (inventory) => inventory.ownedDecorIds,
      orElse: () => const <String>{},
    );
    final contributions = <LifeBuffType, List<String>>{};
    for (final id in ownedIds) {
      final item = service.lookupDecor(id);
      if (item == null || item.buffs.isEmpty) continue;
      for (final buff in item.buffs) {
        contributions.putIfAbsent(buff.type, () => <String>[]).add(item.name);
      }
    }

    final entries = buffs.entries.map((entry) {
      final details = describeBuff(entry.key, entry.value);
      final sources =
          (contributions[entry.key] ?? const <String>[]).toSet().toList()
            ..sort();
      return _BuffChip(
        label: details.label,
        description: details.description,
        sources: sources,
      );
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '활성 버프',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '수집한 장식 보너스는 모든 라이프 버디에게 누적 적용돼요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: entries),
          ],
        ),
      ),
    );
  }
}

class _QuestActionCard extends ConsumerWidget {
  const _QuestActionCard({required this.level});

  final int level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final questStatusAsync = ref.watch(lifeBuddyQuestStatusProvider);
    final questStatus = describeQuestStatus(questStatusAsync);
    final isClaiming = ref.watch(lifeBuddyQuestClaimingProvider).value;
    final canClaim = questStatusAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '일일 퀘스트',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '루틴을 완료하면 코인을 받을 수 있어요. 현재 레벨 $level',
              style: theme.textTheme.bodySmall,
            ),
            if (questStatus.message != null) ...[
              const SizedBox(height: 6),
              QuestStatusMessage(
                message: questStatus.message!,
                showSpinner: questStatus.showSpinner,
                onRetry: questStatus.showRetry
                    ? () => ref.invalidate(lifeBuddyQuestStatusProvider)
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            QuestClaimButton(
              isClaiming: isClaiming,
              isLoadingStatus: questStatusAsync.isLoading,
              canClaim: canClaim,
              onClaim: () => _claimDailyQuest(ref, context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinBalanceBanner extends ConsumerWidget {
  const _CoinBalanceBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(lifeBuddyInventoryProvider);
    return inventoryAsync.when(
      data: (inventory) {
        final theme = Theme.of(context);
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '나의 코인 현황',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${inventory.coins}개',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      inventory.isPremiumUser ? '프리미엄 이용 중' : '프리미엄 미보유',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!inventory.isPremiumUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '프리미엄 장식은 구독 후 사용할 수 있어요.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      error: (error, stackTrace) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('인벤토리를 불러올 수 없어요.'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    ref.read(lifeBuddyInventoryProvider.notifier).refresh(),
                child: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingDecorCard extends StatelessWidget {
  const _UpcomingDecorCard({required this.items, required this.currentLevel});

  final List<DecorItem> items;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = items.isEmpty
        ? '이미 모든 장식을 해금했어요. 다음 업데이트를 기대해 주세요!'
        : '다음 레벨 업으로 해금될 장식을 미리 확인해 보세요.';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '다가오는 해금 보상',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            if (items.isNotEmpty) const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '레벨 $currentLevel 기준으로 잠금 해제할 장식이 없습니다.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ..._buildEntries(theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEntries(ThemeData theme) {
    final widgets = <Widget>[];
    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.requiresPremium) const _PremiumBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '해금 레벨 ${item.unlockLevel} • ${item.costCoins} 코인',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(item.description, style: theme.textTheme.bodySmall),
            if (index != items.length - 1) ...[
              const SizedBox(height: 12),
              Divider(
                height: 16,
                color: theme.dividerColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      );
    }
    return widgets;
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '프리미엄',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Future<void> _claimDailyQuest(WidgetRef ref, BuildContext context) async {
  final notifier = ref.read(lifeBuddyQuestClaimingProvider);
  if (notifier.value) return;
  notifier.value = true;
  try {
    final service = ref.read(lifeBuddyRemoteServiceProvider);
    final result = await service.claimDailyQuest(
      LifeBuddyQuestStore.defaultQuestId,
    );
    await ref
        .read(lifeBuddyQuestStoreProvider)
        .markClaimed(
          DateTime.now(),
          questId: LifeBuddyQuestStore.defaultQuestId,
        );
    ref.invalidate(lifeBuddyQuestStatusProvider);
    await ref
        .read(lifeBuddyInventoryProvider.notifier)
        .applyQuestReward(result.coinsRewarded);
    final inventoryCoins = ref
        .read(lifeBuddyInventoryProvider)
        .maybeWhen(data: (value) => value.coins, orElse: () => null);
    if (inventoryCoins != null) {
      await ref.read(engagementStoreProvider.notifier).setCoins(inventoryCoins);
    }
    await LifeBuddyAnalytics.logQuestClaimSuccess(
      questId: result.questId,
      coinsRewarded: result.coinsRewarded,
      source: 'life_buddy_page',
    );
    if (!context.mounted) return;
    final message = result.coinsRewarded > 0
        ? '보상으로 코인 ${result.coinsRewarded}개를 획득했어요!'
        : '퀘스트가 완료됐어요.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  } on FirebaseFunctionsException catch (error) {
    await LifeBuddyAnalytics.logQuestClaimFailure(
      questId: LifeBuddyQuestStore.defaultQuestId,
      source: 'life_buddy_page',
      errorCode: error.code,
    );
    await AnalyticsService.recordError(
      error,
      StackTrace.current,
      reason: 'life_buddy_quest_claim_failed (code: ${error.code})',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('보상을 받을 수 없어요: ${error.message ?? '알 수 없는 오류'}'),
        ),
      );
    }
  } catch (error) {
    await LifeBuddyAnalytics.logQuestClaimFailure(
      questId: LifeBuddyQuestStore.defaultQuestId,
      source: 'life_buddy_page',
      errorCode: 'unknown',
    );
    await AnalyticsService.recordError(
      error,
      StackTrace.current,
      reason: 'life_buddy_quest_claim_unknown_error',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했어요: $error')));
    }
  } finally {
    notifier.value = false;
  }
}

class _BuffChip extends StatelessWidget {
  const _BuffChip({
    required this.label,
    required this.description,
    this.sources = const <String>[],
  });

  final String label;
  final String description;
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '적용 장식: ${sources.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DecorSlotCard extends ConsumerWidget {
  const _DecorSlotCard({
    required this.slot,
    required this.state,
    required this.isPremiumUser,
    required this.service,
  });

  final DecorSlot slot;
  final LifeBuddyState state;
  final bool isPremiumUser;
  final LifeBuddyService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(lifeBuddyStateProvider.notifier);
    final equippedId = state.room.equipped[slot];
    final items = service.catalogForSlot(slot).toList()
      ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));
    final slotName = slotLabel(slot);
    final inventoryAsync = ref.watch(lifeBuddyInventoryProvider);
    final unlockingId = ref.watch(lifeBuddyUnlockingDecorProvider);

    return inventoryAsync.when(
      loading: () => _DecorSlotLoadingCard(slotName: slotName),
      error: (error, stackTrace) => _DecorSlotErrorCard(
        slotName: slotName,
        onRetry: () => ref.read(lifeBuddyInventoryProvider.notifier).refresh(),
      ),
      data: (inventory) {
        final effectivePremium = isPremiumUser || inventory.isPremiumUser;
        final ownedItemTiles = <Widget>[];
        final lockedItemTiles = <Widget>[];
        for (final item in items) {
          final meetsLevel = state.level >= item.unlockLevel;
          final isPremiumLocked = item.requiresPremium && !effectivePremium;
          final isOwned =
              item.costCoins == 0 || inventory.ownedDecorIds.contains(item.id);
          final coinsEnough = inventory.coins >= item.costCoins;
          final isUnlocking = unlockingId == item.id;

          if (isOwned) {
            final subtitle = _unlockedSubtitle(item);
            ownedItemTiles.add(
              RadioListTile<String>(
                value: item.id,
                title: Text(item.name),
                subtitle: subtitle != null ? Text(subtitle) : null,
              ),
            );
            continue;
          }

          final canAttemptUnlock = !isPremiumLocked && meetsLevel;
          final subtitle = _lockedSubtitle(
            item,
            meetsLevel: meetsLevel,
            coinsEnough: coinsEnough,
            inventoryCoins: inventory.coins,
            isPremiumLocked: isPremiumLocked,
          );

          lockedItemTiles.add(
            ListTile(
              title: Text(item.name),
              subtitle: Text(subtitle),
              enabled: false,
              trailing: isPremiumLocked
                  ? const _PremiumBadge()
                  : canAttemptUnlock
                  ? FilledButton(
                      onPressed: !coinsEnough || isUnlocking
                          ? null
                          : () => _unlockDecor(
                              ref,
                              context,
                              item: item,
                              inventory: inventory,
                            ),
                      child: isUnlocking
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('${item.costCoins} 코인으로 해금'),
                    )
                  : null,
            ),
          );
        }

        Future<void> equipById(String value) async {
          DecorItem? selected;
          for (final decor in items) {
            if (decor.id == value) {
              selected = decor;
              break;
            }
          }
          if (selected == null) return;
          await controller.equipItem(selected, isPremiumUser: effectivePremium);
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      slotName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (equippedId != null)
                      TextButton(
                        onPressed: () async {
                          await controller.unequipSlot(slot);
                        },
                        child: const Text('해제'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ownedItemTiles.isNotEmpty)
                  RadioGroup<String>(
                    groupValue: equippedId,
                    onChanged: (value) async {
                      if (value == null) return;
                      await equipById(value);
                    },
                    child: Column(children: ownedItemTiles),
                  ),
                if (lockedItemTiles.isNotEmpty) ...[
                  if (ownedItemTiles.isNotEmpty) const SizedBox(height: 12),
                  ...lockedItemTiles,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String? _unlockedSubtitle(DecorItem item) {
  if (item.description.isEmpty) return null;
  return item.description;
}

String _lockedSubtitle(
  DecorItem item, {
  required bool meetsLevel,
  required bool coinsEnough,
  required int inventoryCoins,
  required bool isPremiumLocked,
}) {
  final parts = <String>[];
  if (isPremiumLocked) {
    parts.add('프리미엄 전용 아이템입니다.');
  }
  if (!meetsLevel) {
    parts.add('레벨 ${item.unlockLevel}에서 잠금 해제');
  }
  if (meetsLevel && !isPremiumLocked) {
    if (coinsEnough) {
      parts.add('코인 ${item.costCoins}개로 해금할 수 있어요.');
    } else {
      parts.add('코인 ${item.costCoins}개 필요 (현재 $inventoryCoins개)');
    }
  }
  if (item.description.isNotEmpty) {
    parts.add(item.description);
  }
  return parts.join('\n');
}

class _DecorSlotLoadingCard extends StatelessWidget {
  const _DecorSlotLoadingCard({required this.slotName});

  final String slotName;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slotName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _DecorSlotErrorCard extends StatelessWidget {
  const _DecorSlotErrorCard({required this.slotName, required this.onRetry});

  final String slotName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slotName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text('장식 정보를 불러오지 못했어요.'),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

Future<void> _unlockDecor(
  WidgetRef ref,
  BuildContext context, {
  required DecorItem item,
  required LifeBuddyInventory inventory,
}) async {
  final unlockingNotifier = ref.read(lifeBuddyUnlockingDecorProvider.notifier);
  if (unlockingNotifier.state != null) {
    return;
  }
  unlockingNotifier.state = item.id;
  try {
    final service = ref.read(lifeBuddyRemoteServiceProvider);
    final result = await service.unlockDecor(item.id);
    if (!result.ok) {
      throw Exception('unlock_failed');
    }

    await ref
        .read(lifeBuddyInventoryProvider.notifier)
        .applyUnlock(
          decorId: result.decorId,
          remainingCoins: result.remainingCoins,
        );
    if (result.remainingCoins != null) {
      await ref
          .read(engagementStoreProvider.notifier)
          .setCoins(result.remainingCoins!);
    }
    await LifeBuddyAnalytics.logDecorUnlockSuccess(
      decorId: result.decorId,
      costCoins: item.costCoins,
      requiresPremium: item.requiresPremium,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name}을(를) 해금했어요!')));
    }
  } on FirebaseFunctionsException catch (error) {
    await LifeBuddyAnalytics.logDecorUnlockFailure(
      decorId: item.id,
      errorCode: error.code,
      costCoins: item.costCoins,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해금할 수 없어요: ${error.message ?? '알 수 없는 오류'}')),
      );
    }
  } catch (error) {
    await LifeBuddyAnalytics.logDecorUnlockFailure(
      decorId: item.id,
      errorCode: 'unknown',
      costCoins: item.costCoins,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('해금 중 오류가 발생했어요: $error')));
    }
  } finally {
    unlockingNotifier.state = null;
  }
}
