import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/models/community_challenge.dart';

class CommunityRepository {
  CommunityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _challengesPath = 'challenges';

  Stream<List<CommunityChallenge>> getChallenges(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection(_challengesPath)
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommunityChallenge.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Future<CommunityChallenge?> getChallengeByInviteCode(String code) async {
    final snapshot = await _firestore
        .collection(_challengesPath)
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return CommunityChallenge.fromFirestore(doc.id, doc.data());
    }
    return null;
  }

  Future<void> createChallenge(CommunityChallenge challenge) async {
    await _firestore
        .collection(_challengesPath)
        .doc(challenge.id)
        .set(challenge.toFirestore());
  }

  Future<void> joinChallenge(String challengeId, ChallengeMember member) async {
    await _firestore.collection(_challengesPath).doc(challengeId).update({
      'members': FieldValue.arrayUnion([member.toFirestore()]),
      'memberIds': FieldValue.arrayUnion([member.id]),
    });
  }

  Future<void> leaveChallenge(String challengeId, String memberId) async {
    final docRef = _firestore.collection(_challengesPath).doc(challengeId);
    final doc = await docRef.get();
    if (doc.exists) {
      final challenge = CommunityChallenge.fromFirestore(doc.id, doc.data()!);
      final updatedMembers =
          challenge.members.where((m) => m.id != memberId).toList();
      await docRef.update({
        'members': updatedMembers.map((m) => m.toFirestore()).toList(),
        'memberIds': FieldValue.arrayRemove([memberId]),
      });
    }
  }

  Future<void> updateProgress({
    required String challengeId,
    required String memberId,
    int? focusMinutes,
  }) async {
    final docRef = _firestore.collection(_challengesPath).doc(challengeId);
    final doc = await docRef.get();
    if (doc.exists) {
      final challenge = CommunityChallenge.fromFirestore(doc.id, doc.data()!);
      final updatedMembers = challenge.members.map((member) {
        if (member.id == memberId) {
          return member.copyWith(
            focusMinutes: focusMinutes ?? member.focusMinutes,
          );
        }
        return member;
      }).toList();
      await docRef.update({
        'members': updatedMembers.map((m) => m.toFirestore()).toList(),
      });
    }
  }
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(firestoreProvider));
});
