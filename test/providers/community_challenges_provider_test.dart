import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/community/community_repository.dart';
import 'package:life_app/models/community_challenge.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/community_challenges_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'community_challenges_provider_test.mocks.dart';

@GenerateMocks([CommunityRepository, auth.User])
void main() {
  group('CommunityChallengesNotifier', () {
    late ProviderContainer container;
    late MockCommunityRepository mockRepository;
    late MockUser mockUser;

    setUp(() {
      mockRepository = MockCommunityRepository();
      mockUser = MockUser();
      
      // Mock the user's UID
      when(mockUser.uid).thenReturn('test_user_id');

      container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(mockRepository),
          authControllerProvider.overrideWith((ref) => Stream.value(mockUser)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('build returns empty list when user is not logged in', () async {
      // Override auth to be logged out for this specific test
      container.dispose();
      container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(mockRepository),
          authControllerProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );

      // We need to listen to the provider to trigger the build method
      final listener = container.listen(communityChallengesProvider, (_, __) {});
      
      // Wait for the future to complete
      await expectLater(listener.read(), completion(isEmpty));

      verifyNever(mockRepository.getChallenges(any));
    });

    test('build calls repository and returns challenges when user is logged in', () async {
      final challenges = [
        CommunityChallenge(id: 'c1', title: 'Test Challenge', description: '', template: ChallengeTemplate.focusSprint, startDate: DateTime.now(), endDate: DateTime.now(), goalMinutesPerDay: 1, privacy: ChallengePrivacy.private, status: ChallengeStatus.active, ownerId: 'test_user_id', members: [])
      ];
      when(mockRepository.getChallenges('test_user_id')).thenAnswer((_) => Stream.value(challenges));

      final result = await container.read(communityChallengesProvider.future);
      
      expect(result, challenges);
      verify(mockRepository.getChallenges('test_user_id')).called(1);
    });

    test('createChallenge calls repository with correct data', () async {
      final notifier = container.read(communityChallengesProvider.notifier);
      
      await notifier.createChallenge(
        template: ChallengeTemplate.focusSprint,
        title: 'New Sprint',
        description: 'A test sprint',
        durationDays: 7,
        goalMinutes: 30,
        privacy: ChallengePrivacy.private,
      );

      final captured = verify(mockRepository.createChallenge(captureAny)).captured.single as CommunityChallenge;
      expect(captured.title, 'New Sprint');
      expect(captured.ownerId, 'test_user_id');
      expect(captured.members.first.id, 'test_user_id');
    });

     test('leave calls repository with correct challengeId', () async {
      final notifier = container.read(communityChallengesProvider.notifier);
      
      await notifier.leave('challenge_to_leave');

      verify(mockRepository.leaveChallenge('challenge_to_leave', 'test_user_id')).called(1);
    });

    test('updateProgress calls repository with correct data', () async {
      final notifier = container.read(communityChallengesProvider.notifier);
      
      await notifier.updateProgress(
        challengeId: 'challenge_to_update',
        focusMinutes: 50,
      );

      verify(mockRepository.updateProgress(
        challengeId: 'challenge_to_update',
        memberId: 'test_user_id',
        focusMinutes: 50,
      )).called(1);
    });
  });
}
