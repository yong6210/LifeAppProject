import 'package:intl/intl.dart';

import 'package:life_app/features/journal/journal_entry.dart';

class LifeBuddyComment {
  const LifeBuddyComment({required this.ruleId, required this.message});

  final String ruleId;
  final String message;
}

class LifeBuddyCommentEngine {
  const LifeBuddyCommentEngine();

  LifeBuddyComment? generate(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return const LifeBuddyComment(
        ruleId: 'comment_empty',
        message: '오늘 하루를 남기면 내가 바로 이야기를 이어갈게. 지금 한 줄만 남겨볼까?',
      );
    }

    final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    final latest = sorted.first;
    final recent = sorted.take(3).toList();
    final mood = latest.mood.trim();
    final notes = latest.notes?.toLowerCase().trim() ?? '';
    final positiveMoods = {'좋아요', '뿌듯해요', '설레요'};
    final negativeMoods = {'피곤해요', '무기력해요', '걱정돼요'};

    LifeBuddyComment? match;

    if (sorted.length == 1) {
      return const LifeBuddyComment(
        ruleId: 'rule_32_first_entry',
        message: '첫 저널이라 설렘 반 긴장 반이지? 친구한테 말하듯 편하게 남겨줘도 괜찮아 😊',
      );
    }

    final hasThreePositive =
        recent.length >= 3 &&
        _allSatisfy(recent, (entry) => positiveMoods.contains(entry.mood));
    final hasThreeNegative =
        recent.length >= 3 &&
        _allSatisfy(recent, (entry) => negativeMoods.contains(entry.mood));

    if (hasThreePositive) {
      match = const LifeBuddyComment(
        ruleId: 'rule_6_three_positive',
        message: '요즘 에너지 최고! 연속 3일 긍정 모드 달성, 하이파이브 🙌',
      );
    } else if (hasThreeNegative) {
      match = const LifeBuddyComment(
        ruleId: 'rule_39_three_negative',
        message: '3일째 마음이 무겁네. 내일은 회복 하루로 두고 루틴을 가볍게 만들어둘게.',
      );
    }

    if (match != null) {
      return match;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final latestDate = DateFormat('yyyy-MM-dd').format(latest.date);
    final isToday = today == latestDate;

    if (_containsAny(notes, ['야근', '야간', 'overtime'])) {
      return const LifeBuddyComment(
        ruleId: 'rule_25_overtime',
        message: '야근했구나… 오늘은 휴식이 우선이야. 수면 루틴에 딥 릴랙스 사운드를 넣어둘게.',
      );
    }

    if (_containsAny(notes, ['혼자', '외롭', 'lonely'])) {
      return const LifeBuddyComment(
        ruleId: 'rule_26_lonely',
        message: '혼자라는 느낌이 들었구나. 내가 오늘은 특별히 오래 곁을 지켜줄게.',
      );
    }

    if (_containsAny(notes, ['시험', '면접', '면접준비', 'interview', 'exam'])) {
      return const LifeBuddyComment(
        ruleId: 'rule_27_exam',
        message: '중요한 일정 앞두고 떨리는 건 당연해. 준비 루틴을 조금 더 세분화해볼게. 넌 할 수 있어!',
      );
    }

    if (_containsAny(notes, ['시간 부족', '상황이 바빠', '시간없', 'time shortage'])) {
      return const LifeBuddyComment(
        ruleId: 'rule_35_time_short',
        message: '시간이 늘 빠듯했지? 내일은 가장 부담 큰 루틴부터 함께 정리해볼게.',
      );
    }

    if (_containsAny(notes, ['감사', '고마워', 'thank'])) {
      return const LifeBuddyComment(
        ruleId: 'rule_24_gratitude',
        message: '고마운 마음을 남겨줘서 나도 뿌듯해. 감사 루틴을 일주일에 한 번 넣어볼까?',
      );
    }

    if (notes.length >= 80 && mood == '무기력해요') {
      return const LifeBuddyComment(
        ruleId: 'rule_14_long_entry',
        message: '마음속 이야기를 털어줘서 고마워. 오늘은 루틴을 단순하게 정리해둘게.',
      );
    }

    if (mood == '무기력해요') {
      return const LifeBuddyComment(
        ruleId: 'rule_10_no_workout',
        message: '기운이 빠진 날이네… 내일은 가벼운 스트레칭 루틴으로 몸을 먼저 깨워보자.',
      );
    }

    if (mood == '피곤해요') {
      return const LifeBuddyComment(
        ruleId: 'rule_9_focus_failed',
        message: '오늘은 집중이 쉽지 않았구나. 남은 밤은 편하게 쉬고 내일은 짧은 세션으로 시작해보자.',
      );
    }

    if (mood == '걱정돼요') {
      return const LifeBuddyComment(
        ruleId: 'rule_11_sleep_missed',
        message: '걱정이 많았구나. 잠들기 전 5분 숨 고르기 루틴을 함께 추가해볼게.',
      );
    }

    if (positiveMoods.contains(mood)) {
      return const LifeBuddyComment(
        ruleId: 'rule_5_short_positive',
        message: '짧지만 강렬하네! 한 줄로도 오늘의 빛이 다 느껴졌어 😎',
      );
    }

    if (!isToday) {
      return const LifeBuddyComment(
        ruleId: 'rule_31_no_entry_today',
        message: '오늘은 기록 대신 휴식을 택했구나. 내일 다시 만나서 이야기를 들려줘!',
      );
    }

    return const LifeBuddyComment(
      ruleId: 'comment_fallback',
      message: '오늘 이야기 고마워. 내일도 네 곁에서 루틴을 부드럽게 조정해 줄게.',
    );
  }

  bool _containsAny(String source, Iterable<String> needles) {
    for (final needle in needles) {
      if (needle.isEmpty) continue;
      if (source.contains(needle.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  bool _allSatisfy(
    List<JournalEntry> entries,
    bool Function(JournalEntry entry) test,
  ) {
    if (entries.isEmpty) return false;
    for (final entry in entries) {
      if (!test(entry)) return false;
    }
    return true;
  }
}
