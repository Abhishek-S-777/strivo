import 'package:strivo/features/workout/domain/entities/workout_session.dart';

/// Persistence boundary for completed [WorkoutSession]s, the in-progress
/// workout (auto-save/restore), and the per-exercise personal-record cache.
///
/// Presentation depends on this interface only; the Hive + Firestore
/// implementation lives in the data layer. Completed sessions are saved locally
/// and pushed to the cloud explicitly via [syncToCloud] (on finish), keeping
/// writes offline-first.
abstract interface class SessionRepository {
  /// All completed and in-progress sessions, most recent first.
  List<WorkoutSession> getAll();

  /// The session with [id], or null if none is stored.
  WorkoutSession? getById(String id);

  /// All completed sessions for [routineId], most recent first.
  List<WorkoutSession> getByRoutine(String routineId);

  /// The most recent completed session for [routineId], or null.
  WorkoutSession? getLastByRoutine(String routineId);

  /// Completed sessions whose start time falls within [start]..[end].
  List<WorkoutSession> getInRange(DateTime start, DateTime end);

  /// Persist [session] locally. Does not touch the cloud (see [syncToCloud]).
  Future<void> save(WorkoutSession session);

  /// Remove the session with [id] locally and from the cloud.
  Future<void> delete(String id);

  /// Back up a finished [session] and its exercise PRs to the cloud.
  Future<void> syncToCloud(WorkoutSession session);

  // ── In-progress workout (auto-save / crash recovery) ──

  /// The auto-saved in-progress workout, or null if none.
  WorkoutSession? getActive();

  /// Auto-save the in-progress [session] locally.
  Future<void> saveActive(WorkoutSession session);

  /// Clear the auto-saved in-progress workout.
  Future<void> clearActive();

  // ── Exercise personal-record cache ──

  /// The stored PR record (maxWeight/maxVolume/...) for [exerciseId], or null.
  Map<String, dynamic>? getHistory(String exerciseId);

  /// Update the local PR record for [exerciseId].
  Future<void> updateHistory(String exerciseId, Map<String, dynamic> data);
}
