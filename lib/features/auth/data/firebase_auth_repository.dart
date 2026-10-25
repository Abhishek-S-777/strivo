import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/settings/settings_repository.dart';
import 'package:strivo/features/auth/domain/auth_repository.dart';

/// [AuthRepository] backed by Firebase Auth.
///
/// The last signed-in email is persisted via [SettingsRepository] purely for
/// UI pre-fill; no password is ever stored on the device.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._settings);

  final FirebaseAuth _auth;
  final SettingsRepository _settings;

  static const String _rememberedEmailKey = 'remembered_email';

  @override
  AuthUser? get currentUser => _toAuthUser(_auth.currentUser);

  @override
  String? get rememberedEmail {
    final value = _settings.getString(_rememberedEmailKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAuthUser);

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final trimmed = email.trim();
    try {
      await _auth.signInWithEmailAndPassword(
        email: trimmed,
        password: password,
      );
      await _settings.setString(_rememberedEmailKey, trimmed);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    } on Object {
      throw const AuthException('Something went wrong. Please try again.');
    }
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmed = email.trim();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: trimmed,
        password: password,
      );
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await cred.user?.updateDisplayName(trimmedName);
        await cred.user?.reload();
      }
      await _settings.setString(_rememberedEmailKey, trimmed);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    } on Object {
      throw const AuthException('Something went wrong. Please try again.');
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    } on Object {
      throw const AuthException('Could not send reset email.');
    }
  }

  @override
  Future<void> signOut() async {
    await _settings.setString(_rememberedEmailKey, '');
    await _auth.signOut();
  }

  AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  String _message(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No connection. Check your network and retry.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this project yet.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Supplies the app-wide [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    ref.watch(settingsRepositoryProvider),
  );
});
