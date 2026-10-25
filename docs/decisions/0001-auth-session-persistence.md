# 1. Auth session persistence without storing a password

- Status: accepted
- Date: 2026-10-25

## Context

Strivo gates the whole app behind Firebase Authentication (email/password). On
some Android devices — confirmed on Samsung S-series Ultra, in release builds —
Firebase Auth's own persisted session (kept in Android `SharedPreferences`) is
dropped when the app is killed, so the user is signed out on every cold start.
This is a known FlutterFire issue ([#17971]) that the maintainers closed as
*won't fix*. It is device-specific: Hive data survives the kill on the same
devices, and emulators / debug builds are unaffected.

An earlier workaround stored the user's email **and password** in an
AES-encrypted Hive box (key in the platform keystore via `flutter_secure_storage`)
and silently re-authenticated on launch. It worked, but storing a recoverable
password on the device is a finding any security review would flag, and this is a
portfolio codebase that should pass such a review.

## Options considered

1. **Keep storing the password** and silently re-auth. Zero friction, but keeps a
   reversible credential on the device. Rejected.
2. **Token-based silent re-auth** — mint a custom/refresh token from a backend and
   store only that. Strongest, but requires a backend service we do not have in
   this pass. Deferred.
3. **Remember the email only, re-ask for the password.** Store the last
   signed-in email (not a secret) and, when there is no live session on launch,
   show a "Welcome back" screen with the email pre-filled so the user types just
   their password. Chosen.

## Decision

Adopt option 3.

- `AuthRepository` persists only the last signed-in email (via
  `SettingsRepository`); it never stores a password. The email is cleared on
  explicit sign-out.
- The silent-re-auth path and `CredentialStore` are removed, and the
  `flutter_secure_storage` dependency is dropped.
- The router sends an unauthenticated user with a remembered email to a
  `WelcomeBackScreen` (password-only, email shown), and a brand-new or
  signed-out user to the full auth screen. "Use a different account" routes to
  the full auth screen.

## Consequences

- No reversible secret is stored on the device; the change passes a security
  review on this point.
- Behaviour change on affected devices only: after a cold start that dropped the
  Firebase session, the user re-enters their password on the Welcome-back screen
  instead of being signed in silently. Unaffected devices are unchanged
  (Firebase restores the session and the user lands straight in the app).
- Re-authentication now needs the password, so there is no fully-offline cold
  start for a user whose session was dropped — matching normal app behaviour.

[#17971]: https://github.com/firebase/flutterfire/issues/17971
