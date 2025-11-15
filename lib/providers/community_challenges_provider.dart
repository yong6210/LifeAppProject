import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/models/community_challenge.dart';

final communityChallengesProvider =
    NotifierProvider<CommunityChallengesNotifier, List<CommunityChallenge>>(
      CommunityChallengesNotifier.new,
    );

class ChallengeTemplateInfo {
  const ChallengeTemplateInfo({
    required this.title,
    required this.description,
    required this.defaultDurationDays,
    required this.defaultGoalMinutes,
  });

  final String title;
  final String description;
  final int defaultDurationDays;
  final int defaultGoalMinutes;
}

// TODO(challenges-data): Fetch template catalog from backend/config store.
// 템플릿 제목과 설명이 코드에 고정되어 있어 서버나 로컬 저장소의 최신 설정을 반영하지 못합니다.
// TODO(l10n): Localize challenge template copy via l10n bundle.
// 영문 텍스트가 직접 하드코딩되어 다국어 지원이 되지 않습니다.
const templateCatalog = <ChallengeTemplate, ChallengeTemplateInfo>{
  ChallengeTemplate.focusSprint: ChallengeTemplateInfo(
    title: 'Focus Sprint',
    description: 'Stay accountable with daily 25-minute focus sessions.',
    defaultDurationDays: 5,
    defaultGoalMinutes: 25,
  ),
  ChallengeTemplate.restReset: ChallengeTemplateInfo(
    title: 'Rest Reset',
    description: 'Take a restorative break to reset energy.',
    defaultDurationDays: 7,
    defaultGoalMinutes: 10,
  ),
  ChallengeTemplate.sleepWindDown: ChallengeTemplateInfo(
    title: 'Sleep Wind-down',
    description: 'Wind down each night with a calming routine.',
    defaultDurationDays: 10,
    defaultGoalMinutes: 15,
  ),
};

class CommunityChallengesNotifier extends Notifier<List<CommunityChallenge>> {
  @override
  List<CommunityChallenge> build() => _seedChallenges();

  CommunityChallenge createChallenge({
    required ChallengeTemplate template,
    required String title,
    required String description,
    required int durationDays,
    required int goalMinutes,
    required ChallengePrivacy privacy,
    String ownerId = 'owner',
  }) {
    final now = DateTime.now();
    final start = now;
    final end = start.add(Duration(days: durationDays));
    final inviteCode = privacy == ChallengePrivacy.codeInvite
        ? _generateInviteCode()
        : null;
    final challenge = CommunityChallenge(
      id: 'challenge_${now.millisecondsSinceEpoch}',
      title: title,
      description: description,
      template: template,
      startDate: start,
      endDate: end,
      goalMinutesPerDay: goalMinutes,
      privacy: privacy,
      status: ChallengeStatus.active,
      // TODO(profile-data): Replace default "owner" identifier with the
      // authenticated user's persisted id once challenge creation is wired to the
      // account repository.
      // 현재는 하드코딩된 식별자라 백엔드/로컬 사용자 데이터와 동기화되지 않습니다.
      ownerId: ownerId,
      members: [
        ChallengeMember(
          id: ownerId,
          // TODO(profile-data): Populate displayName from the current account
          // profile (and localize if needed) rather than the inline "You"
          // placeholder.
          // 현재는 영어 문구가 고정되어 있어 사용자 프로필 이름이나 번역을 반영하지
          // 못합니다.
          displayName: 'You',
          focusMinutes: 0,
          joinedAt: start,
        ),
      ],
      inviteCode: inviteCode,
    );
    state = [challenge, ...state];
    return challenge;
  }

  void join(String challengeId, ChallengeMember member) {
    state = state
        .map((challenge) {
          if (challenge.id != challengeId) return challenge;
          if (challenge.members.any((existing) => existing.id == member.id)) {
            return challenge;
          }
          return challenge.copyWith(members: [...challenge.members, member]);
        })
        .toList(growable: false);
  }

  void leave(String challengeId, String memberId) {
    state = state
        .map((challenge) {
          if (challenge.id != challengeId) return challenge;
          return challenge.copyWith(
            members: challenge.members
                .where((member) => member.id != memberId)
                .toList(),
          );
        })
        .toList(growable: false);
  }

  void updateProgress({
    required String challengeId,
    required String memberId,
    int? focusMinutes,
    int? restMinutes,
    bool? completed,
  }) {
    state = state
        .map((challenge) {
          if (challenge.id != challengeId) return challenge;
          return challenge.copyWith(
            members: challenge.members
                .map(
                  (member) => member.id == memberId
                      ? member.copyWith(
                          focusMinutes: focusMinutes ?? member.focusMinutes,
                          restMinutes: restMinutes ?? member.restMinutes,
                          completed: completed ?? member.completed,
                        )
                      : member,
                )
                .toList(),
          );
        })
        .toList(growable: false);
  }

  bool joinByInviteCode(String code, ChallengeMember member) {
    final normalized = code.trim().toUpperCase();
    final target = state.firstWhere(
      (challenge) => challenge.inviteCode?.toUpperCase() == normalized,
      orElse: () => CommunityChallenge(
        id: '',
        title: '',
        description: '',
        template: ChallengeTemplate.focusSprint,
        startDate: DateTime.utc(1970),
        endDate: DateTime.utc(1970),
        goalMinutesPerDay: 0,
        privacy: ChallengePrivacy.private,
        status: ChallengeStatus.upcoming,
        ownerId: '',
        members: const <ChallengeMember>[],
      ),
    );
    if (target.id.isEmpty) {
      return false;
    }
    join(target.id, member);
    return true;
  }
}

// TODO(challenges-data): Replace seeded challenges with repository-backed feed.
// 현재는 목업 데이터만 반환하여 DB/로컬 스토리지의 실제 커뮤니티 챌린지를 불러오지 못합니다.
// TODO(l10n): Externalize seeded challenge strings for translation.
// 챌린지 제목과 설명이 영어 문구로 고정되어 있어 i18n 리소스를 사용할 수 없습니다.
List<CommunityChallenge> _seedChallenges() {
  final now = DateTime.now();
  final random = Random(now.millisecondsSinceEpoch);
  Duration days(int value) => Duration(days: value);
  CommunityChallenge build(
    String id,
    String title,
    String description,
    ChallengeTemplate template,
    int daysLength,
    int goal,
  ) {
    final start = now.subtract(Duration(days: random.nextInt(3)));
    final end = start.add(days(daysLength));
    return CommunityChallenge(
      id: id,
      title: title,
      description: description,
      template: template,
      startDate: start,
      endDate: end,
      goalMinutesPerDay: goal,
      privacy: ChallengePrivacy.private,
      status: ChallengeStatus.active,
      ownerId: 'owner',
      members: [
        // TODO(challenges-data): Populate participant list from actual member profiles.
        // 시드 데이터가 고정된 닉네임과 진행도로 채워져 있어 사용자/친구 목록과 일치하지 않습니다.
        // TODO(l10n): Localize participant display labels such as "You".
        // 영어 닉네임이 고정되어 다른 언어 사용자에게 자연스럽지 않습니다.
        ChallengeMember(id: 'owner', displayName: 'You', focusMinutes: 60),
        ChallengeMember(
          id: 'friend_1',
          displayName: 'Mina',
          focusMinutes: 45 + random.nextInt(20),
        ),
        ChallengeMember(
          id: 'friend_2',
          displayName: 'Alex',
          focusMinutes: 40 + random.nextInt(25),
        ),
      ],
      inviteCode: template == ChallengeTemplate.sleepWindDown
          ? _generateInviteCode()
          : null,
    );
  }

  return [
    build(
      'challenge_focus',
      'Focus Sprint',
      'Stay accountable with a 25-minute focus session for five days.',
      ChallengeTemplate.focusSprint,
      5,
      25,
    ),
    build(
      'challenge_rest',
      'Rest Reset',
      'Take a guided stretch break each afternoon for a week.',
      ChallengeTemplate.restReset,
      7,
      10,
    ),
    build(
      'challenge_sleep',
      'Sleep Wind-down',
      'Wind down with a 15-minute sleep routine and log notes nightly.',
      ChallengeTemplate.sleepWindDown,
      10,
      15,
    ).copyWith(status: ChallengeStatus.upcoming),
  ];
}

String _generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random();
  return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
}
