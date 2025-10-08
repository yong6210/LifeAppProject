import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String? value});
}

class FlutterSecureStorageWrapper implements SecureStorage {
  const FlutterSecureStorageWrapper();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }
}

class EncryptionKeyManager {
  EncryptionKeyManager({SecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorageWrapper();

  final SecureStorage _storage;
  static const _storageKey = 'life_app_backup_key_v1';

  Future<SecretKey> obtainKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null) {
      final bytes = base64Decode(existing);
      return SecretKey(bytes);
    }

    final random = Random.secure();
    final bytes = Uint8List(32);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    await _storage.write(key: _storageKey, value: base64Encode(bytes));
    return SecretKey(bytes);
  }

  Future<void> reset() async {
    await _storage.write(key: _storageKey, value: null);
  }
}
