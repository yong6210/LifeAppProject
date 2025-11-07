import 'package:flutter/material.dart';
import 'package:life_app/features/life_buddy/life_buddy_models.dart';

class LifeBuddyMoodDetails {
  const LifeBuddyMoodDetails({
    required this.title,
    required this.description,
    required this.color,
    required this.emoji,
  });

  final String title;
  final String description;
  final Color color;
  final String emoji;
}

LifeBuddyMoodDetails describeMood(LifeBuddyMood mood, ThemeData theme) {
  switch (mood) {
    case LifeBuddyMood.depleted:
      return const LifeBuddyMoodDetails(
        title: '지친 상태',
        description: '휴식과 수면을 챙겨 라이프 버디의 컨디션을 회복시켜 주세요.',
        color: Colors.redAccent,
        emoji: '😴',
      );
    case LifeBuddyMood.low:
      return const LifeBuddyMoodDetails(
        title: '살짝 저조해요',
        description: '수면 비중을 조금 더 늘리면 활력이 돌아올 거예요.',
        color: Colors.deepOrange,
        emoji: '🥱',
      );
    case LifeBuddyMood.steady:
      return LifeBuddyMoodDetails(
        title: '안정적이에요',
        description: '현재 루틴을 유지하면 좋은 컨디션을 지속할 수 있어요.',
        color: theme.colorScheme.primary,
        emoji: '🙂',
      );
    case LifeBuddyMood.thriving:
      return const LifeBuddyMoodDetails(
        title: '매우 활기차요',
        description: '집중과 휴식의 균형이 잘 맞춰졌어요. 계속 이어가 볼까요?',
        color: Colors.teal,
        emoji: '😄',
      );
    case LifeBuddyMood.radiant:
      return const LifeBuddyMoodDetails(
        title: '빛이 나요',
        description: '완벽한 루틴 덕분에 라이프 버디가 최고 컨디션이에요!',
        color: Colors.purple,
        emoji: '🤩',
      );
  }
}

class LifeBuddyBuffDetails {
  const LifeBuddyBuffDetails({required this.label, required this.description});

  final String label;
  final String description;
}

LifeBuddyBuffDetails describeBuff(LifeBuffType type, double value) {
  final percent = (value * 100).toStringAsFixed(0);
  switch (type) {
    case LifeBuffType.focusXpMultiplier:
      return LifeBuddyBuffDetails(
        label: '집중 XP +$percent%',
        description: '집중 세션 경험치가 증가합니다.',
      );
    case LifeBuffType.restRecoveryMultiplier:
      return LifeBuddyBuffDetails(
        label: '휴식 회복 +$percent%',
        description: '짧은 휴식으로도 더 빠르게 회복합니다.',
      );
    case LifeBuffType.sleepQualityBonus:
      return LifeBuddyBuffDetails(
        label: '수면 품질 +$percent%',
        description: '수면 분석과 기상 상태가 개선됩니다.',
      );
  }
}

String slotLabel(DecorSlot slot) {
  switch (slot) {
    case DecorSlot.bed:
      return '침대';
    case DecorSlot.desk:
      return '책상';
    case DecorSlot.lighting:
      return '조명';
    case DecorSlot.wall:
      return '벽 장식';
    case DecorSlot.floor:
      return '바닥';
    case DecorSlot.accent:
      return '악세서리';
  }
}
