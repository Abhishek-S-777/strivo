import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/sync/cloud_sync_repository.dart';
import 'package:strivo/features/auth/data/firebase_auth_repository.dart';
import 'package:strivo/features/auth/domain/auth_repository.dart';
import 'package:strivo/features/programs/presentation/providers/program_providers.dart';
import 'package:strivo/features/routines/presentation/providers/routine_providers.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';

/// Holds the live auth state and exposes it synchronously for the router.
///
/// Used as a [ChangeNotifier] so `GoRouter.refreshListenable` re-evaluates
/// redirects the instant auth changes, and [initialized] lets us show a splash
/// until Firebase has restored any persisted session.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(this._repo) {
    // Firebase.initializeApp() has already completed (awaited in main), so the
    // native SDK has usually restored any persisted session by now; seed
    // synchronously to avoid a login flash for returning users.
    _user = _repo.currentUser;
    if (_user != null) _initialized = true;

    // The first stream event reflects the real restored state; mark initialized
    // then so an unauthenticated start waits for it rather than flashing.
    _sub = _repo.authStateChanges().listen((user) {
      _user = user;
      _initialized = true;
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription<AuthUser?> _sub;
  AuthUser? _user;
  bool _initialized = false;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;

  /// The last signed-in email (for the "welcome back" pre-fill), or null.
  String? get rememberedEmail => _repo.rememberedEmail;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  final notifier = AuthStateNotifier(ref.read(authRepositoryProvider));
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Convenience stream of the current user for widgets.
final currentUserProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Result of an auth action — either success or a friendly error message.
class AuthResult {
  const AuthResult.ok() : success = true, error = null;
  const AuthResult.fail(this.error) : success = false;
  final bool success;
  final String? error;
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  AuthController(this._ref);
  final Ref _ref;

  AuthRepository get _auth => _ref.read(authRepositoryProvider);
  CloudSyncRepository get _sync => _ref.read(cloudSyncRepositoryProvider);

  Future<AuthResult> signIn(String email, String password) async {
    try {
      await _auth.signIn(email: email, password: password);
      await _afterSignIn();
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(e.message);
    }
  }

  Future<AuthResult> signUp(
    String name,
    String email,
    String password,
  ) async {
    try {
      await _auth.signUp(name: name, email: email, password: password);
      final trimmedName = name.trim();
      await _sync.saveUserProfile(
        displayName: trimmedName.isEmpty ? null : trimmedName,
        email: email.trim(),
      );
      // Back up any data created locally before this account existed.
      await _sync.pushAllLocal();
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(e.message);
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(e.message);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Pull cloud data down and refresh the local providers that read Hive.
  Future<void> _afterSignIn() async {
    await _sync.restoreFromCloud();
    _ref.read(workoutSessionsProvider.notifier).refresh();
    _ref.read(routinesProvider.notifier).refresh();
    _ref.read(programsProvider.notifier).refresh();
  }
}
