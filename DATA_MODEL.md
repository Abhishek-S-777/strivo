# Strivo — Data Model

Strivo is **offline-first**. The local Hive store is the working source of truth;
Cloud Firestore is a per-user backup that syncs across devices. The two share the
exact same JSON shape (`toMap()`/`fromMap()` on each entity), so a record can move
between them losslessly.

## Local (Hive)

| Box | Key | Value (JSON) |
| --- | --- | --- |
| `workout_sessions` | sessionId | `WorkoutSession` (embeds exercises → sets; may carry `programId`/`programWeek`/`programDayName`) |
| `routines` | routineId | `Routine` (embeds routine exercises) |
| `programs` | programId | `Program` (embeds days → exercises → per-week `SetTarget`s + position pointer) |
| `exercises` | exerciseId | `Exercise` (template library, seeded + custom) |
| `active_workout` | `"current"` | in-progress `WorkoutSession` (auto-saved every 10s) |
| `exercise_history` | exerciseId | PR cache `{maxWeight, maxVolume, lastPerformed, exerciseName}` |
| `settings` | key | string (e.g. `last_synced_uid`, `weight_unit`) |
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
  ├─ programs/{programId}         ← multi-week structured plans
  │     id, name, durationWeeks (0 = ongoing rotation),
  │     days:[ { name, exercises:[ { exercise,
  │              weeklyTargets:[{sets,repsMin,repsMax,rpe}] } ] } ],
  │     currentWeek, currentDayIndex, isComplete, syncedAt
  │
  ├─ exercises/{exerciseId}       ← user's CUSTOM exercises only
  │     id, name, primaryMuscle, secondaryMuscle, equipment,
  │     notes, isCustom (true), alternativeIds:[…], syncedAt
  │
  └─ exercise_history/{exerciseId}← PR cache for fast lookups
        exerciseId, maxWeight, maxVolume, lastPerformed, updatedAt
```

The **active program** selection (`active_program_id`) is device-local (in
`settings`), so each device can run its own active plan; the programs
themselves sync. Programs prescribe sets/reps/RPE per week; **weight is not
prescribed** — logging pre-fills load from the lifter's last performance.

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

- **Sign in:** `restoreFromCloud()` pulls sessions, routines, programs, and the
  user's custom exercises into Hive. If a *different* uid synced on this device
  before, local training data is wiped first (tracked via
  `settings/last_synced_uid`) so accounts never mix. As a safety net, any
  exercise embedded in a restored session/routine/program that isn't already in
  the local library is re-added (covers customs created before exercise-sync
  existed).
- **Sign up:** `pushAllLocal()` backs up anything created locally (incl. custom
  exercises), then writes the profile doc.
- **During use:** finishing a workout, saving/deleting a routine, saving a
  program, and creating a custom exercise each fire a background sync (no-op
  when signed out).

### Exercise library: bundled vs. custom

The exercise library is **seeded into Hive on launch** from a versioned list in
`HiveService` (`exerciseSeedVersion`). Bumping that version re-seeds — it
overwrites only the built-in `ex_*` ids (so new exercises / edited metadata /
populated alternatives reach existing installs) and never touches user-custom
exercises. **Built-ins are NOT stored per user** (they ship with the app);
**only custom exercises sync** to `users/{uid}/exercises`. Each exercise can
carry `alternativeIds` — substitutes shown when the required machine/setup
isn't available.
