# 3. Owner-only Firestore security rules

Date: 2026-11-07

## Status

Accepted.

## Context

Each account's data (profile, sessions, routines, programs, exercises) lives
under `users/{uid}` in Cloud Firestore. The app ships its Firebase config
(`firebase_options.dart`, `google-services.json`) in the repository, which is
expected for a Firebase client app: these identify the project but are not
secrets. Access control must therefore be enforced by security rules on the
server, not by hiding the config.

## Decision

Firestore rules allow a signed-in user to read and write only their own document
subtree, and deny everything else:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Consequences

- A leaked client config cannot be used to read or write another user's data;
  an authenticated request is scoped to its own `uid`.
- There is no cross-user or public data, which matches the single-user training
  log model.
- The API key should additionally be restricted in the Google Cloud console and
  App Check enabled to limit abuse of the project's quotas (tracked separately).
