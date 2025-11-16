import 'package:equatable/equatable.dart';

enum ChallengePrivacy { private, codeInvite, public }

enum ChallengeStatus { upcoming, active, completed }

enum ChallengeTemplate { focusSprint, restReset, sleepWindDown }

class ChallengeMember extends Equatable {
  const ChallengeMember({
    required this.id,
    required this.displayName,
    this.focusMinutes = 0,
    this.restMinutes = 0,
    this.joinedAt,
    this.completed = false,
  });

  final String id;
  final String displayName;
  final int focusMinutes;
  final int restMinutes;
  final DateTime? joinedAt;
  final bool completed;

  ChallengeMember copyWith({
    int? focusMinutes,
    int? restMinutes,
    bool? completed,
  }) {
    return ChallengeMember(
      id: id,
      displayName: displayName,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      restMinutes: restMinutes ?? this.restMinutes,
      joinedAt: joinedAt,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    focusMinutes,
    restMinutes,
    joinedAt,
    completed,
  ];
}

class CommunityChallenge extends Equatable {
  const CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.template,
    required this.startDate,
    required this.endDate,
    required this.goalMinutesPerDay,
    required this.privacy,
    required this.status,
    required this.ownerId,
    required this.members,
    this.inviteCode,
  });

  final String id;
  final String title;
  final String description;
  final ChallengeTemplate template;
  final DateTime startDate;
  final DateTime endDate;
  final int goalMinutesPerDay;
  final ChallengePrivacy privacy;
  final ChallengeStatus status;
  final String ownerId;
  final List<ChallengeMember> members;
  final String? inviteCode;

  CommunityChallenge copyWith({
    ChallengeStatus? status,
    List<ChallengeMember>? members,
    String? inviteCode,
  }) {
    return CommunityChallenge(
      id: id,
      title: title,
      description: description,
      template: template,
      startDate: startDate,
      endDate: endDate,
      goalMinutesPerDay: goalMinutesPerDay,
      privacy: privacy,
      status: status ?? this.status,
      ownerId: ownerId,
      members: members ?? this.members,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }

  /// Checks if the given userId is the owner of this challenge
  bool isOwnedBy(String userId) => ownerId == userId;

  bool get isActive => status == ChallengeStatus.active;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    template,
    startDate,
    endDate,
    goalMinutesPerDay,
    privacy,
    status,
    ownerId,
    members,
    inviteCode,
  ];
}
