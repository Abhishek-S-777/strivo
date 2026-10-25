/// A provider-agnostic view of the signed-in user, so presentation never
/// depends on Firebase's `User` type.
class AuthUser {
  const AuthUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;
}

/// Raised by [AuthRepository] actions with a user-friendly [message] already
/// resolved from the underlying provider's error codes.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Authentication boundary for the app.
///
/// Presentation depends on this interface only; the Firebase implementation
/// lives in the data layer. The repository also remembers the last signed-in
/// email (a non-secret) so a returning user can be greeted and have the field
/// pre-filled — it never stores the password.
abstract interface class AuthRepository {
  /// The current user, or null. Available synchronously after Firebase init.
  AuthUser? get currentUser;

  /// The last signed-in email, kept for pre-fill after a dropped session.
  /// Null once the user has explicitly signed out.
  String? get rememberedEmail;

  /// Emits whenever the signed-in user changes (sign-in / sign-out).
  Stream<AuthUser?> authStateChanges();

  /// Sign in with email + password. Throws [AuthException] on failure.
  Future<void> signIn({required String email, required String password});

  /// Create an account and set the display name. Throws [AuthException].
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Send a password-reset email. Throws [AuthException] on failure.
  Future<void> sendPasswordReset(String email);

  /// Sign out and forget the remembered email.
  Future<void> signOut();
}
