import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/core/firebase/firebase_initializer.dart';
import 'package:life_app/features/account/profile_repository.dart';
import 'package:life_app/services/analytics/analytics_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (!FirebaseInitializer.isAvailable || Firebase.apps.isEmpty) {
    return null;
  }
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) {
    return Stream<User?>.value(null);
  }
  return auth.authStateChanges();
});

class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    await FirebaseInitializer.ensureInitialized();
    final auth = ref.read(firebaseAuthProvider);
    if (auth == null) {
      return null;
    }
    final user = auth.currentUser;
    await AnalyticsService.setUserId(
      user?.uid,
      isAnonymous: user?.isAnonymous ?? true,
    );
    return user;
  }

  Future<UserCredential> signInAnonymously() async {
    state = const AsyncLoading();
    final auth = ref.read(firebaseAuthProvider);
    if (auth == null) {
      final error = UnsupportedError(
        'Firebase Auth is unavailable on this platform.',
      );
      state = AsyncError(error, StackTrace.current);
      throw error;
    }
    final profileRepo = ref.read(profileRepositoryProvider);

    final credential = await auth.signInAnonymously();
    final user = credential.user;

    if (user != null) {
      // Create a profile only if one doesn't already exist
      final existingProfile = await profileRepo.getUserProfile(user.uid);
      if (existingProfile == null) {
        final newProfile = UserProfile(
          uid: user.uid,
          displayName: 'Anonymous User', // Default display name
        );
        await profileRepo.createUserProfile(newProfile);
      }
    }

    state = AsyncData(user);
    await AnalyticsService.setUserId(
      user?.uid,
      isAnonymous: user?.isAnonymous ?? true,
    );
    ref.invalidate(userProfileProvider);
    return credential;
  }

  Future<void> signOut() async {
    final auth = ref.read(firebaseAuthProvider);
    if (auth == null) {
      state = const AsyncData(null);
      return;
    }
    await auth.signOut();
    state = const AsyncData(null);
    await AnalyticsService.setUserId(null);
    ref.invalidate(userProfileProvider);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);
