# 4. Firebase configuration in the repo, and hardening

Date: 2026-11-07

## Status

Accepted.

## Context

A Firebase client app needs `firebase_options.dart` and, on Android,
`google-services.json`. Both are committed to this repository. They contain the
project id, app id, and a Firebase API key. These identify the project to
Google's servers; they are not secrets and cannot, on their own, grant access to
user data. For a client-side app there is no way to hide them — they ship inside
the installed binary regardless. Access control therefore has to be enforced on
the server.

## Decision

Commit the Firebase config and rely on server-side controls:

- **Security rules are the access control.** All user data lives under
  `users/{uid}`, and `firestore.rules` grants read/write only to the
  authenticated owner of that subtree (recursive match), denying everything else
  by default. See [0003-owner-only-firestore-rules.md](0003-owner-only-firestore-rules.md).
- **Restrict the API key** in the Google Cloud console: limit the Android key to
  the app's package name and SHA-1, and restrict it to the Firebase APIs the app
  actually calls.
- **Enable App Check** (Play Integrity on Android) and enforce it for Firestore,
  so requests must come from a genuine, unmodified build of the app.

The console steps (key restriction, App Check enforcement) are applied by the
project owner; this repository carries the rules and documents the steps.

## Consequences

- The committed config is safe to publish; a copy cannot read or write another
  user's data because rules scope every request to its own `uid`.
- API-key restriction and App Check reduce abuse of the project's quotas from
  outside the real app.
- A contributor running against their own Firebase project reproduces this by
  deploying `firestore.rules` and applying the same console settings.
