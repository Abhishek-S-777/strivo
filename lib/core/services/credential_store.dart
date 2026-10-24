import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:strivo/core/logging/app_logger.dart';

/// Securely persists the last successful login so the app can silently
/// re-authenticate when Firebase Auth's own session storage is dropped by the
/// OS on app kill.
///
/// This is a workaround for a known, Firebase-`wontfix` bug where Firebase
/// Auth's session (kept in Android SharedPreferences) is not restored on
/// certain devices in release builds — notably Samsung S-series Ultra phones
/// (flutterfire issue #17971). Hive's own file storage *does* survive the kill
/// on those devices, so the credentials live in an AES-encrypted Hive box. The
/// 256-bit encryption key is held in the platform keystore via
/// flutter_secure_storage. If the key (or box) can't be read the store fails
/// closed — `read()` returns null and the app falls back to the normal login
/// screen, never worse than before.
class CredentialStore {
  CredentialStore._();

  static const String _boxName = 'auth_creds';
  static const String _keyName = 'auth_creds_key';
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  /// Returns the box encryption key, creating and persisting one when
  /// [create] is true and none exists yet. Returns null if the keystore is
  /// unavailable.
  static Future<List<int>?> _encryptionKey({bool create = false}) async {
    try {
      final existing = await _secure.read(key: _keyName);
      if (existing != null) return base64Decode(existing);
      if (!create) return null;
      final key = Hive.generateSecureKey();
      await _secure.write(key: _keyName, value: base64Encode(key));
      return key;
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'CredentialStore: keystore unavailable',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<Box<dynamic>?> _openBox({bool create = false}) async {
    final key = await _encryptionKey(create: create);
    if (key == null) return null;
    try {
      if (Hive.isBoxOpen(_boxName)) return Hive.box<dynamic>(_boxName);
      return await Hive.openBox<dynamic>(
        _boxName,
        encryptionCipher: HiveAesCipher(key),
      );
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'CredentialStore: open failed',
        error: e,
        stackTrace: stackTrace,
      );
      // A leftover box encrypted with a now-lost key can't be reopened; on a
      // save we can safely discard and recreate it with the current key.
      if (create) {
        try {
          await Hive.deleteBoxFromDisk(_boxName);
          return await Hive.openBox<dynamic>(
            _boxName,
            encryptionCipher: HiveAesCipher(key),
          );
        } on Object catch (e2, stackTrace2) {
          AppLogger.warning(
            'CredentialStore: recreate failed',
            error: e2,
            stackTrace: stackTrace2,
          );
        }
      }
      return null;
    }
  }

  /// Save the credentials of a successful login.
  static Future<void> save(String email, String password) async {
    final box = await _openBox(create: true);
    if (box == null) return;
    await box.put('email', email);
    await box.put('password', password);
  }

  /// Read stored credentials, or null if none are available.
  static Future<({String email, String password})?> read() async {
    final box = await _openBox();
    if (box == null) return null;
    final email = box.get('email') as String?;
    final password = box.get('password') as String?;
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  /// Forget the stored credentials (called on sign-out).
  static Future<void> clear() async {
    try {
      final box = await _openBox();
      await box?.clear();
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'CredentialStore: clear failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
