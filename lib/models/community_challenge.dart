import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory ChallengeMember.fromFirestore(Map<String, dynamic> data) {
    return ChallengeMember(
      id: data['id'] as String,
      displayName: data['displayName'] as String,
      focusMinutes: data['focusMinutes'] as int? ?? 0,
      restMinutes: data['restMinutes'] as int? ?? 0,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
      completed: data['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'displayName': displayName,
      'focusMinutes': focusMinutes,
      'restMinutes': restMinutes,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      'completed': completed,
    };
  }

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
    this.memberIds = const [],
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
  final List<String> memberIds;

  factory CommunityChallenge.fromFirestore(String id, Map<String, dynamic> data) {
    return CommunityChallenge(
      id: id,
      title: data['title'] as String,
      description: data['description'] as String,
      template: ChallengeTemplate.values.byName(data['template'] as String),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      goalMinutesPerDay: data['goalMinutesPerDay'] as int,
      privacy: ChallengePrivacy.values.byName(data['privacy'] as String),
      status: ChallengeStatus.values.byName(data['status'] as String),
      ownerId: data['ownerId'] as String,
      members: (data['members'] as List<dynamic>)
          .map((memberData) =>
              ChallengeMember.fromFirestore(memberData as Map<String, dynamic>))
          .toList(),
      inviteCode: data['inviteCode'] as String?,
      memberIds: List<String>.from(data['memberIds'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'template': template.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'goalMinutesPerDay': goalMinutesPerDay,
      'privacy': privacy.name,
      'status': status.name,
      'ownerId': ownerId,
      'members': members.map((member) => member.toFirestore()).toList(),
      'inviteCode': inviteCode,
      'memberIds': members.map((m) => m.id).toList(),
    };
  }

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
      memberIds: members?.map((m) => m.id).toList() ?? memberIds,
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
        memberIds,
      ];
}
