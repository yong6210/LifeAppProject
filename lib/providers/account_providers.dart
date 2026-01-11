import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/services/account/account_deletion_service.dart';
import 'package:life_app/services/backup/encryption_key_manager.dart';

final accountDeletionControllerProvider =
    AsyncNotifierProvider<AccountDeletionController, AccountDeletionResult?>(
      AccountDeletionController.new,
    );

class AccountDeletionController extends AsyncNotifier<AccountDeletionResult?> {
  @override
  Future<AccountDeletionResult?> build() async => null;

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    try {
      final auth = ref.read(firebaseAuthProvider);
      if (auth == null) {
        throw UnsupportedError(
          'Firebase Auth is unavailable on this platform.',
        );
      }
      final service = AccountDeletionService(
        auth: auth,
        firestore: FirebaseFirestore.instance,
        keyManager: EncryptionKeyManager(),
      );
      final result = await service.deleteAccount();
      await auth.signOut();
      state = AsyncData(result);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }
}
