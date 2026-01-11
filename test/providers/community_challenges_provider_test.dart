import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/account/profile_repository.dart';
import 'package:life_app/features/community/community_repository.dart';
import 'package:life_app/models/community_challenge.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/community_challenges_provider.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);

  final auth.User? _user;

  @override
  Future<auth.User?> build() async => _user;
}

class _FakeCommunityRepository implements CommunityRepository {
  int getChallengesCallCount = 0;
  String? lastGetChallengesUserId;
  Stream<List<CommunityChallenge>> Function(String userId)? onGetChallenges;

  CommunityChallenge? createdChallenge;
  String? leaveChallengeId;
  String? leaveMemberId;
  _UpdateProgressCall? updateProgressCall;

  @override
  Stream<List<CommunityChallenge>> getChallenges(String userId) {
    getChallengesCallCount += 1;
    lastGetChallengesUserId = userId;
    return onGetChallenges?.call(userId) ??
        Stream.value(const <CommunityChallenge>[]);
  }

  @override
  Future<CommunityChallenge?> getChallengeByInviteCode(String code) async {
    return null;
  }

  @override
  Future<void> createChallenge(CommunityChallenge challenge) async {
    createdChallenge = challenge;
  }

  @override
  Future<void> joinChallenge(String challengeId, ChallengeMember member) async {}

  @override
  Future<void> leaveChallenge(String challengeId, String memberId) async {
    leaveChallengeId = challengeId;
    leaveMemberId = memberId;
  }

  @override
  Future<void> updateProgress({
    required String challengeId,
    required String memberId,
    int? focusMinutes,
  }) async {
    updateProgressCall = _UpdateProgressCall(
      challengeId: challengeId,
      memberId: memberId,
      focusMinutes: focusMinutes,
    );
  }
}

class _UpdateProgressCall {
  const _UpdateProgressCall({
    required this.challengeId,
    required this.memberId,
    required this.focusMinutes,
  });

  final String challengeId;
  final String memberId;
  final int? focusMinutes;
}

void main() {
  group('CommunityChallengesNotifier', () {
    late ProviderContainer container;
    late _FakeCommunityRepository fakeRepository;
    late auth.User mockUser;

    setUp(() {
      fakeRepository = _FakeCommunityRepository();
      mockUser = MockUser(uid: 'test_user_id');

      container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(fakeRepository),
          authControllerProvider.overrideWith(
            () => _FakeAuthController(mockUser),
          ),
          userProfileProvider.overrideWith(
            (ref) => const UserProfile(
              uid: 'test_user_id',
              displayName: 'Tester',
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('build returns empty list when user is not logged in', () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(fakeRepository),
          authControllerProvider.overrideWith(
            () => _FakeAuthController(null),
          ),
          userProfileProvider.overrideWith((ref) => null),
        ],
      );

      await container.read(authControllerProvider.future);
      final result = await container.read(communityChallengesProvider.future);

      expect(result, isEmpty);
      expect(fakeRepository.getChallengesCallCount, 0);
    });

    test(
      'build calls repository and returns challenges when user is logged in',
      () async {
        final challenges = [
          CommunityChallenge(
            id: 'c1',
            title: 'Test Challenge',
            description: '',
            template: ChallengeTemplate.focusSprint,
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            goalMinutesPerDay: 1,
            privacy: ChallengePrivacy.private,
            status: ChallengeStatus.active,
            ownerId: 'test_user_id',
            members: [],
          ),
        ];
        fakeRepository.onGetChallenges = (userId) {
          return Stream.value(challenges);
        };

        await container.read(authControllerProvider.future);
        final result = await container.read(communityChallengesProvider.future);

        expect(result, challenges);
        expect(fakeRepository.getChallengesCallCount, 1);
        expect(fakeRepository.lastGetChallengesUserId, 'test_user_id');
      },
    );

    test('createChallenge calls repository with correct data', () async {
      await container.read(authControllerProvider.future);
      await container.read(communityChallengesProvider.future);
      final notifier = container.read(communityChallengesProvider.notifier);

      await notifier.createChallenge(
        template: ChallengeTemplate.focusSprint,
        title: 'New Sprint',
        description: 'A test sprint',
        durationDays: 7,
        goalMinutes: 30,
        privacy: ChallengePrivacy.private,
      );

      final created = fakeRepository.createdChallenge;
      expect(created, isNotNull);
      expect(created?.title, 'New Sprint');
      expect(created?.ownerId, 'test_user_id');
      expect(created?.members.first.id, 'test_user_id');
    });

    test('leave calls repository with correct challengeId', () async {
      await container.read(authControllerProvider.future);
      await container.read(communityChallengesProvider.future);
      final notifier = container.read(communityChallengesProvider.notifier);

      await notifier.leave('challenge_to_leave');

      expect(fakeRepository.leaveChallengeId, 'challenge_to_leave');
      expect(fakeRepository.leaveMemberId, 'test_user_id');
    });

    test('updateProgress calls repository with correct data', () async {
      await container.read(authControllerProvider.future);
      await container.read(communityChallengesProvider.future);
      final notifier = container.read(communityChallengesProvider.notifier);

      await notifier.updateProgress(
        challengeId: 'challenge_to_update',
        focusMinutes: 50,
      );

      final call = fakeRepository.updateProgressCall;
      expect(call, isNotNull);
      expect(call?.challengeId, 'challenge_to_update');
      expect(call?.memberId, 'test_user_id');
      expect(call?.focusMinutes, 50);
    });
  });
}
