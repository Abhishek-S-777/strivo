# Strivo — Data Model

Strivo is **offline-first**. The local Hive store is the working source of truth;
Cloud Firestore is a per-user backup that syncs across devices. The two share the
exact same JSON shape (`toMap()`/`fromMap()` on each entity), so a record can move
between them losslessly.

## Local (Hive)

| Box | Key | Value (JSON) |
| --- | --- | --- |
| `workout_sessions` | sessionId | `WorkoutSession` (embeds exercises → sets) |
| `routines` | routineId | `Routine` (embeds routine exercises) |
| `exercises` | exerciseId | `Exercise` (template library, seeded + custom) |
| `active_workout` | `"current"` | in-progress `WorkoutSession` (auto-saved every 10s) |
| `exercise_history` | exerciseId | PR cache `{maxWeight, maxVolume, lastPerformed, exerciseName}` |
| `settings` | key | string (e.g. `last_synced_uid`) |
| `progress_photos` | photoId | `ProgressPhoto` (image stored on disk, path referenced) |

## Cloud (Firestore)

```
users/{uid}                       ← profile + preferences
  ├─ displayName, email, createdAt, updatedAt
  ├─ preferences: { ... }
  │
  ├─ sessions/{sessionId}         ← one doc per completed workout
  │     id, name, routineId, routineName,
  │     startTime, endTime, isCompleted, notes,
  │     exercises: [ { exercise, sets:[{weight,reps,rpe,isPR,...}], ... } ],
  │     totalVolume, totalSets, totalExercises, duration,   (denormalized)
  │     syncedAt (server timestamp)
  │
  ├─ routines/{routineId}         ← reusable templates
  │     id, name, description, color, timesUsed,
  │     createdAt, updatedAt, exercises:[...], syncedAt
  │
  └─ exercise_history/{exerciseId}← PR cache for fast lookups
        exerciseId, maxWeight, maxVolume, lastPerformed, updatedAt
```

### Why this shape

- **Denormalized sessions.** A workout is read and written as a single document
  (exercises and sets embedded). A typical session is a few KB — far under the 1 MB
  doc limit — so there are **no fan-out reads**: opening history = 1 read per session,
  not 1 + N×sets. Comparison/analytics run locally over Hive, so Firestore reads stay
  minimal (≈ last 100 sessions pulled once on sign-in).
- **Everything under `users/{uid}`** so one recursive security rule
  (`firestore.rules`) makes all data strictly owner-only.
- **No composite indexes needed** (`firestore.indexes.json` is empty): the only
  server query is `sessions.orderBy(startTime desc).limit(100)`, satisfied by the
  automatic single-field index.
- **`syncedAt`** server timestamps are written on every upload to enable future
  incremental/delta sync without a schema change.

### Sync lifecycle

- **Sign in:** `restoreFromCloud()` pulls sessions + routines into Hive. If a
  *different* uid synced on this device before, local training data is wiped first
  (tracked via `settings/last_synced_uid`) so accounts never mix.
- **Sign up:** `pushAllLocal()` backs up anything created locally, then writes the
  profile doc.
- **During use:** finishing a workout, saving/deleting a routine, and deleting a
  session each fire a background sync (no-op when signed out).
