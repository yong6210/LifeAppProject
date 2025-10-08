import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/core/firebase/firebase_initializer.dart';
import 'package:life_app/services/analytics/analytics_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    await FirebaseInitializer.ensureInitialized();
    final auth = ref.read(firebaseAuthProvider);
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
    final credential = await auth.signInAnonymously();
    state = AsyncData(credential.user);
    await AnalyticsService.setUserId(
      credential.user?.uid,
      isAnonymous: credential.user?.isAnonymous ?? true,
    );
    return credential;
  }

  Future<void> signOut() async {
    final auth = ref.read(firebaseAuthProvider);
    await auth.signOut();
    state = const AsyncData(null);
    await AnalyticsService.setUserId(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);
