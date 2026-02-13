import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/account/profile_repository.dart';
import 'package:life_app/features/community/community_repository.dart';
import 'package:life_app/models/community_challenge.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/remote_config_providers.dart';

final communityChallengesProvider = AsyncNotifierProvider<
    CommunityChallengesNotifier, List<CommunityChallenge>>(
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

  factory ChallengeTemplateInfo.fromJson(Map<String, dynamic> json) {
    return ChallengeTemplateInfo(
      title: json['title'] as String,
      description: json['description'] as String,
      defaultDurationDays: json['defaultDurationDays'] as int,
      defaultGoalMinutes: json['defaultGoalMinutes'] as int,
    );
  }
}

final defaultTemplateCatalog = <ChallengeTemplate, ChallengeTemplateInfo>{
  ChallengeTemplate.focusSprint: const ChallengeTemplateInfo(
    title: 'Focus Sprint',
    description: 'Stay accountable with daily 25-minute focus sessions.',
    defaultDurationDays: 5,
    defaultGoalMinutes: 25,
  ),
  ChallengeTemplate.restReset: const ChallengeTemplateInfo(
    title: 'Rest Reset',
    description: 'Take a restorative break to reset energy.',
    defaultDurationDays: 7,
    defaultGoalMinutes: 10,
  ),
  ChallengeTemplate.sleepWindDown: const ChallengeTemplateInfo(
    title: 'Sleep Wind-down',
    description: 'Wind down each night with a calming routine.',
    defaultDurationDays: 10,
    defaultGoalMinutes: 15,
  ),
};

final challengeTemplatesProvider =
    FutureProvider<Map<ChallengeTemplate, ChallengeTemplateInfo>>((ref) async {
  final remoteConfig = await ref.watch(remoteConfigProvider.future);
  final jsonString = remoteConfig.challengeTemplatesJson;

  if (jsonString != null && jsonString.isNotEmpty) {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final templates = <ChallengeTemplate, ChallengeTemplateInfo>{};
      for (final entry in decoded.entries) {
        final templateKey = ChallengeTemplate.values.byName(entry.key);
        final templateInfo =
            ChallengeTemplateInfo.fromJson(entry.value as Map<String, dynamic>);
        templates[templateKey] = templateInfo;
      }
      return templates;
    } catch (_) {
      // Fallback to default if parsing fails
      return defaultTemplateCatalog;
    }
  }

  return defaultTemplateCatalog;
});

class CommunityChallengesNotifier
    extends AsyncNotifier<List<CommunityChallenge>> {
  @override
  Future<List<CommunityChallenge>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return [];

    final repo = ref.watch(communityRepositoryProvider);
    final challenges = await repo.getChallenges(user.uid).first;
    return challenges;
  }

  Future<CommunityChallenge> createChallenge({
    required ChallengeTemplate template,
    required String title,
    required String description,
    required int durationDays,
    required int goalMinutes,
    required ChallengePrivacy privacy,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) throw Exception('User not authenticated');

    final userProfile = await ref.read(userProfileProvider.future);
    final displayName = userProfile?.displayName ?? 'You';
    final avatarUrl = userProfile?.avatarUrl;
    final premiumTier = userProfile?.premiumTier ?? 'free';

    final repo = ref.read(communityRepositoryProvider);
    final now = DateTime.now();
    final start = now;
    final end = start.add(Duration(days: durationDays));
    final inviteCode =
        privacy == ChallengePrivacy.codeInvite ? _generateInviteCode() : null;

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
      ownerId: user.uid,
      members: [
        ChallengeMember(
          id: user.uid,
          displayName: displayName,
          avatarUrl: avatarUrl,
          premiumTier: premiumTier,
          focusMinutes: 0,
          joinedAt: start,
        ),
      ],
      inviteCode: inviteCode,
    );

    await repo.createChallenge(challenge);
    ref.invalidateSelf();
    return challenge;
  }

  Future<void> join(String challengeId, ChallengeMember member) async {
    final repo = ref.read(communityRepositoryProvider);
    await repo.joinChallenge(challengeId, member);
    ref.invalidateSelf();
  }

  Future<void> leave(String challengeId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) throw Exception('User not authenticated');

    final repo = ref.read(communityRepositoryProvider);
    await repo.leaveChallenge(challengeId, user.uid);
    ref.invalidateSelf();
  }

  Future<void> updateProgress({
    required String challengeId,
    required int focusMinutes,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) throw Exception('User not authenticated');

    final repo = ref.read(communityRepositoryProvider);
    await repo.updateProgress(
      challengeId: challengeId,
      memberId: user.uid,
      focusMinutes: focusMinutes,
    );
    ref.invalidateSelf();
  }

  Future<bool> joinByInviteCode(String code) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) throw Exception('User not authenticated');

    final repo = ref.read(communityRepositoryProvider);
    final normalizedCode = code.trim().toUpperCase();
    final targetChallenge = await repo.getChallengeByInviteCode(normalizedCode);

    if (targetChallenge == null) {
      return false;
    }

    final userProfile = await ref.read(userProfileProvider.future);
    final displayName = userProfile?.displayName ?? 'You';
    final avatarUrl = userProfile?.avatarUrl;
    final premiumTier = userProfile?.premiumTier ?? 'free';

    final member = ChallengeMember(
      id: user.uid,
      displayName: displayName,
      avatarUrl: avatarUrl,
      premiumTier: premiumTier,
      joinedAt: DateTime.now(),
    );

    await join(targetChallenge.id, member);
    return true;
  }
}

String _generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random();
  return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
}
