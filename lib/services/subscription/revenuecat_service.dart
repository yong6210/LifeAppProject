import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:life_app/core/subscriptions/revenuecat_keys.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/settings_providers.dart';

class RevenueCatState {
  const RevenueCatState({required this.customerInfo, required this.offerings});

  final CustomerInfo customerInfo;
  final Offerings offerings;

  EntitlementInfo? get activeEntitlement =>
      customerInfo.entitlements.active.values.isNotEmpty
      ? customerInfo.entitlements.active.values.first
      : null;

  bool get isPro => activeEntitlement != null;
}

class PremiumStatus {
  const PremiumStatus({
    required this.isPremium,
    required this.usesCachedValue,
    required this.hasCachedValue,
    required this.isLoading,
    required this.revenueCatAvailable,
    required this.isInGracePeriod,
    required this.gracePeriodEndsAt,
    required this.expirationDate,
    required this.isExpired,
  });

  /// Whether the user should currently see premium features unlocked.
  final bool isPremium;

  /// True when we fall back to the locally cached entitlement instead of live RevenueCat data.
  final bool usesCachedValue;

  /// Indicates whether we have a cached entitlement stored locally.
  final bool hasCachedValue;

  /// True when entitlement state is still being resolved (e.g. local cache loading).
  final bool isLoading;

  /// True when a live RevenueCat response is available for the current session.
  final bool revenueCatAvailable;

  /// True when RevenueCat reports the user is currently in billing grace period.
  final bool isInGracePeriod;

  /// End timestamp for the grace period, if available.
  final DateTime? gracePeriodEndsAt;

  /// Latest known expiration date for the entitlement.
  final DateTime? expirationDate;

  /// True when the subscription is confirmed lapsed (past expiration) per RevenueCat data.
  final bool isExpired;
}

final revenueCatControllerProvider =
    AsyncNotifierProvider<RevenueCatController, RevenueCatState?>(
      RevenueCatController.new,
    );

class RevenueCatController extends AsyncNotifier<RevenueCatState?> {
  static bool _configured = false;

  @override
  Future<RevenueCatState?> build() async {
    if (!isRevenueCatSupportedPlatform()) {
      state = const AsyncData(null);
      return null;
    }
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      final prevUid = prev?.value?.uid;
      final nextUid = next.value?.uid;
      if (prevUid != nextUid) {
        Future.microtask(() async {
          await _handleAuthChanged(nextUid);
        });
      }
    });

    final authAsync = ref.watch(authStateProvider);
    final appUserId = authAsync.value?.uid;
    final configured = await _configureIfNeeded(appUserId);
    if (!configured) {
      state = const AsyncData(null);
      return null;
    }

    try {
      final offerings = await Purchases.getOfferings();
      final customerInfo = await Purchases.getCustomerInfo();
      final stateData = RevenueCatState(
        customerInfo: customerInfo,
        offerings: offerings,
      );
      await _cachePremiumState(stateData.isPro);
      return stateData;
    } catch (error, stackTrace) {
      debugPrint('RevenueCat fetch failed: $error');
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> refreshCustomerInfo() async {
    if (!isRevenueCatSupportedPlatform()) {
      state = const AsyncData(null);
      return;
    }
    final customerInfo = await Purchases.getCustomerInfo();
    final offerings = await Purchases.getOfferings();
    final isPro = customerInfo.entitlements.active.values.isNotEmpty;
    await _cachePremiumState(isPro);
    state = AsyncData(
      RevenueCatState(customerInfo: customerInfo, offerings: offerings),
    );
  }

  Future<CustomerInfo> restorePurchases() async {
    if (!isRevenueCatSupportedPlatform()) {
      throw UnsupportedError('RevenueCat restore unsupported on this platform');
    }
    final info = await Purchases.restorePurchases();
    await refreshCustomerInfo();
    return info;
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    if (!isRevenueCatSupportedPlatform()) {
      throw UnsupportedError('RevenueCat purchase unsupported on this platform');
    }
    final info = await Purchases.purchasePackage(package);
    await refreshCustomerInfo();
    return info;
  }

  Future<bool> _configureIfNeeded(String? appUserId) async {
    if (!isRevenueCatSupportedPlatform()) {
      return false;
    }
    final apiKey = Platform.isAndroid
        ? RevenueCatKeys.androidKey
        : RevenueCatKeys.iosKey;
    if (apiKey.startsWith('REPLACE_WITH')) {
      debugPrint('RevenueCat API key is not configured; skipping setup.');
      return false;
    }

    if (!_configured) {
      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = appUserId;
      await Purchases.configure(configuration);
      _configured = true;
    } else {
      if (appUserId != null && appUserId.isNotEmpty) {
        await Purchases.logIn(appUserId);
      } else {
        await Purchases.logOut();
      }
    }
    await _setSubscriberAttributes(appUserId);
    await _cachePremiumState(
      state.value?.customerInfo.entitlements.active.values.isNotEmpty ?? false,
    );
    return true;
  }

  Future<void> _handleAuthChanged(String? appUserId) async {
    final configured = await _configureIfNeeded(appUserId);
    if (!configured) return;
    try {
      await refreshCustomerInfo();
    } catch (error) {
      debugPrint('Failed to refresh customer info after auth change: $error');
    }
  }

  Future<void> _setSubscriberAttributes(String? appUserId) async {
    if (!_configured) return;
    final attributes = <String, String>{
      'firebase_uid': appUserId ?? 'anonymous',
      'platform': Platform.operatingSystem,
    };
    try {
      await Purchases.setAttributes(attributes);
    } catch (error) {
      debugPrint('Failed to set RevenueCat attributes: $error');
    }
  }

  Future<void> _cachePremiumState(bool isPro) async {
    final repo = await ref.read(settingsRepoProvider.future);
    await repo.update((settings) {
      settings.lastKnownPremium = isPro;
    });
  }
}

final premiumStatusProvider = Provider<PremiumStatus>((ref) {
  final rcAsync = ref.watch(revenueCatControllerProvider);
  final settingsAsync = ref.watch(settingsFutureProvider);

  final rcState = rcAsync.maybeWhen(data: (state) => state, orElse: () => null);
  final premiumFromRc = rcAsync.maybeWhen(
    data: (state) => state?.isPro,
    orElse: () => null,
  );
  final revenueCatAvailable = rcAsync.maybeWhen(
    data: (state) => state != null,
    orElse: () => false,
  );

  final cachedPremium = settingsAsync.maybeWhen(
    data: (settings) => settings.lastKnownPremium,
    orElse: () => false,
  );
  final hasCachedValue = settingsAsync.maybeWhen(
    data: (_) => true,
    orElse: () => false,
  );
  final isLoading = settingsAsync.isLoading && !hasCachedValue;

  DateTime? graceEnds;
  DateTime? expirationDate;

  if (rcState != null) {
    final entitlement = rcState.activeEntitlement;
    expirationDate = entitlement != null
        ? _parseIso8601(entitlement.expirationDate) ??
            _latestExpiration(rcState.customerInfo.entitlements.all.values)
        : _latestExpiration(rcState.customerInfo.entitlements.all.values);
  }

  const bool isInGracePeriod = false; // Purchases SDK does not expose grace data on this channel.

  final usesCachedValue = premiumFromRc == null;
  final effectivePremium = (premiumFromRc ?? cachedPremium) || isInGracePeriod;
  final isExpired = !effectivePremium && expirationDate != null
      ? expirationDate.isBefore(DateTime.now().toUtc())
      : false;

  if (premiumFromRc != null || isInGracePeriod) {
    return PremiumStatus(
      isPremium: effectivePremium,
      usesCachedValue: usesCachedValue,
      hasCachedValue: hasCachedValue,
      isLoading: isLoading,
      revenueCatAvailable: revenueCatAvailable,
      isInGracePeriod: isInGracePeriod,
      gracePeriodEndsAt: graceEnds,
      expirationDate: expirationDate,
      isExpired: isExpired,
    );
  }

  return PremiumStatus(
    isPremium: effectivePremium,
    usesCachedValue: true,
    hasCachedValue: hasCachedValue,
    isLoading: isLoading,
    revenueCatAvailable: revenueCatAvailable,
    isInGracePeriod: isInGracePeriod,
    gracePeriodEndsAt: graceEnds,
    expirationDate: expirationDate,
    isExpired: isExpired,
  );
});

final isPremiumProvider = Provider<bool>((ref) {
  final status = ref.watch(premiumStatusProvider);
  return status.isPremium;
});

bool isRevenueCatSupportedPlatform() => Platform.isAndroid || Platform.isIOS;

DateTime? _latestExpiration(Iterable<EntitlementInfo> entitlements) {
  DateTime? latest;
  for (final entitlement in entitlements) {
    final expiration = _parseIso8601(entitlement.expirationDate);
    if (expiration == null) continue;
    if (latest == null || expiration.isAfter(latest)) {
      latest = expiration;
    }
  }
  return latest;
}

DateTime? _parseIso8601(String? isoString) {
  if (isoString == null || isoString.isEmpty) return null;
  return DateTime.tryParse(isoString)?.toUtc();
}
