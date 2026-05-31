import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/features/routines/presentation/screens/routines_screen.dart';

/// Holds the live auth state and exposes it synchronously for the router.
///
/// Used as a [ChangeNotifier] so `GoRouter.refreshListenable` re-evaluates
/// redirects the instant auth changes, and `initialized` lets us show a
/// splash until Firebase has restored any persisted session.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      if (!_initialized) _initialized = true;
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;
  User? _user;
  bool _initialized = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  final notifier = AuthStateNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Convenience stream of the current user for widgets.
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Result of an auth action — either success or a friendly error message.
class AuthResult {
  final bool success;
  final String? error;
  const AuthResult.ok() : success = true, error = null;
  const AuthResult.fail(this.error) : success = false;
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  AuthController(this._ref);
  final Ref _ref;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirestoreSyncService get _sync => FirestoreSyncService.instance;

  Future<AuthResult> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _afterSignIn(restore: true);
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_message(e.code));
    } catch (_) {
      return const AuthResult.fail('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> signUp(
    String name,
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await cred.user?.updateDisplayName(trimmedName);
        await cred.user?.reload();
      }
      await _sync.saveUserProfile(
        displayName: trimmedName.isEmpty ? null : trimmedName,
        email: email.trim(),
      );
      // Back up any data created locally before this account existed.
      await _sync.pushAllLocal();
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_message(e.code));
    } catch (_) {
      return const AuthResult.fail('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_message(e.code));
    } catch (_) {
      return const AuthResult.fail('Could not send reset email.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Pull cloud data down and refresh the local providers that read Hive.
  Future<void> _afterSignIn({required bool restore}) async {
    if (restore) {
      await _sync.restoreFromCloud();
    }
    _ref.read(workoutSessionsProvider.notifier).refresh();
    _ref.read(routinesProvider.notifier).refresh();
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
