# 2. Offline-first with Hive as the source of truth

Date: 2026-11-07

## Status

Accepted.

## Context

Strivo is used in a gym, where connectivity is often poor or absent. Logging a
set must never block on the network, and data must survive an app kill
mid-session. The app also needs to back up per account and restore on a new
device.

## Decision

The local Hive store is the working source of truth. Every read and write goes
to Hive first and returns synchronously; Cloud Firestore is a per-account backup
that mirrors the same JSON shape (`toMap()`/`fromMap()` on each entity).

- Writes persist to Hive, then fire a best-effort push to Firestore. A failed
  push does not fail the user action.
- On sign-in, the cloud copy is restored into Hive for the signed-in account.
- The in-progress workout is auto-saved to a dedicated Hive box so it can be
  recovered after a crash or force-quit.

Presentation never touches Hive or Firestore directly. Repositories (interfaces
in `domain`, implementations in `data`) wrap the `HiveService` and
`FirestoreSyncService` data sources, and controllers depend only on the
interfaces.

## Consequences

- Logging is instant and fully functional offline.
- The UI layer is decoupled from storage, so repositories can be faked in tests.
- Firestore is a backup, not a live query source, so there is no real-time
  multi-device merge; last write for an account wins on restore. This is
  acceptable for a single-user training log and keeps the sync model simple.
