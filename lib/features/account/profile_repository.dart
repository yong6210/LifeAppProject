import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/providers/auth_providers.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.timezone,
    this.premiumTier = 'free',
  });

  final String uid;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String? timezone;
  final String premiumTier;

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String,
      email: data['email'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      timezone: data['timezone'] as String?,
      premiumTier: data['premiumTier'] as String? ?? 'free',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'timezone': timezone,
      'premiumTier': premiumTier,
    };
  }
}

class ProfileRepository {
  ProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;
  static const String _usersPath = 'users';

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(_usersPath).doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  Future<void> createUserProfile(UserProfile profile) async {
    await _firestore
        .collection(_usersPath)
        .doc(profile.uid)
        .set(profile.toFirestore());
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(FirebaseFirestore.instance);
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) {
    return null;
  }
  return ref.watch(profileRepositoryProvider).getUserProfile(user.uid);
});
