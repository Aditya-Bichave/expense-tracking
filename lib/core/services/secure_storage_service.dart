import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const _hiveKeyKey = 'hive_encryption_key';
  static const _appPinKey = 'app_pin';
  static const _biometricEnabledKey = 'biometric_enabled';

  SecureStorageService(this._storage);

  Future<List<int>> getHiveKey() async {
    final keyString = await _storage.read(key: _hiveKeyKey);
    if (keyString == null) {
      return _generateAndSaveKey();
    } else {
      try {
        return base64Url.decode(keyString);
      } catch (e, s) {
        final snippet = keyString.length > 4
            ? keyString.substring(0, 4)
            : keyString;
        log.severe(
          'Hive encryption key corrupted. Key snippet: $snippet\nError: $e\n$s',
        );
        // CRITICAL: Do NOT regenerate the key automatically.
        // Doing so would render all existing encrypted data unreadable.
        // We throw an error so the app can handle it (e.g. prompt for restore/reset).
        throw HiveKeyCorruptionException(
          'Hive encryption key is corrupted and cannot be decoded.',
        );
      }
    }
  }

  Future<List<int>> _generateAndSaveKey() async {
    final key = Hive.generateSecureKey();
    await _storage.write(key: _hiveKeyKey, value: base64UrlEncode(key));
    return key;
  }

  Future<void> savePin(String pin) async {
    await _storage.write(key: _appPinKey, value: pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _appPinKey);
  }

  Future<void> deletePin() async {
    await _storage.delete(key: _appPinKey);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

class HiveKeyCorruptionException implements Exception {
  final String message;
  HiveKeyCorruptionException(this.message);
  @override
  String toString() => 'HiveKeyCorruptionException: $message';
}
