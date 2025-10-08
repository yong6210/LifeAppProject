import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/core/firebase/firestore_paths.dart';
import 'package:life_app/models/change_log.dart';
import 'package:life_app/models/daily_summary_local.dart';
import 'package:life_app/models/routine.dart';
import 'package:life_app/models/session.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/backup/encryption_key_manager.dart';
import 'package:life_app/services/db.dart';

class AccountDeletionResult {
  const AccountDeletionResult({
    required this.firebaseAccountDeleted,
    required this.requiresReauthentication,
  });

  final bool firebaseAccountDeleted;
  final bool requiresReauthentication;
}

class AccountDeletionService {
  AccountDeletionService({
    required this.auth,
    required this.firestore,
    required this.keyManager,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final EncryptionKeyManager keyManager;

  Future<AccountDeletionResult> deleteAccount() async {
    final user = auth.currentUser;
    final uid = user?.uid;

    if (uid != null) {
      await _deleteRemoteData(uid);
    }

    await _wipeLocalData();

    bool firebaseDeleted = false;
    bool requiresReauth = false;

    if (user != null && !user.isAnonymous) {
      try {
        await user.delete();
        firebaseDeleted = true;
      } on FirebaseAuthException catch (error) {
        if (error.code == 'requires-recent-login') {
          requiresReauth = true;
        } else {
          rethrow;
        }
      }
    } else {
      firebaseDeleted = true;
    }

    await AnalyticsService.logEvent('account_delete', {
      'had_remote_data': uid != null,
      'firebase_deleted': firebaseDeleted,
      'requires_reauth': requiresReauth,
    });

    return AccountDeletionResult(
      firebaseAccountDeleted: firebaseDeleted,
      requiresReauthentication: requiresReauth,
    );
  }

  Future<void> _deleteRemoteData(String uid) async {
    final batch = firestore.batch();

    try {
      final settingsDoc = firestore.doc(FirestorePaths.settingsDoc(uid));
      batch.delete(settingsDoc);
    } catch (error) {
      debugPrint('Failed to queue settings deletion: $error');
    }

    final summariesRef = firestore.collection(
      '${FirestorePaths.userDoc(uid)}/daily_summaries',
    );
    try {
      final snapshots = await summariesRef.get();
      for (final doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
    } catch (error) {
      debugPrint('Failed to list daily summaries for deletion: $error');
    }

    try {
      final userDoc = firestore.doc(FirestorePaths.userDoc(uid));
      batch.delete(userDoc);
    } catch (error) {
      debugPrint('Failed to queue user doc deletion: $error');
    }

    try {
      await batch.commit();
    } catch (error, stack) {
      debugPrint('Remote account data deletion failed: $error');
      await AnalyticsService.recordError(
        error,
        stack,
        reason: 'remote_account_deletion_failed',
      );
    }
  }

  Future<void> _wipeLocalData() async {
    final isar = await DB.instance();
    await isar.writeTxn(() async {
      await isar.sessions.clear();
      await isar.routines.clear();
      await isar.dailySummaryLocals.clear();
      await isar.settings.clear();
      await isar.changeLogs.clear();
    });

    await keyManager.reset();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timer_state_v2');
  }
}
