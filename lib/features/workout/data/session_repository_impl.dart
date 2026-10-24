import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/domain/session_repository.dart';

/// [SessionRepository] backed by Hive (local) with Firestore cloud backup.
class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._sync);

  final FirestoreSyncService _sync;

  @override
  List<WorkoutSession> getAll() => HiveService.getAllSessions();

  @override
  WorkoutSession? getById(String id) => HiveService.getSession(id);

  @override
  List<WorkoutSession> getByRoutine(String routineId) =>
      HiveService.getSessionsByRoutine(routineId);

  @override
  WorkoutSession? getLastByRoutine(String routineId) =>
      HiveService.getLastSessionByRoutine(routineId);

  @override
  List<WorkoutSession> getInRange(DateTime start, DateTime end) =>
      HiveService.getSessionsInRange(start, end);

  @override
  Future<void> save(WorkoutSession session) => HiveService.saveSession(session);

  @override
  Future<void> delete(String id) async {
    await HiveService.deleteSession(id);
    unawaited(_sync.deleteSession(id));
  }

  @override
  Future<void> syncToCloud(WorkoutSession session) async {
    unawaited(_sync.syncSession(session));
    // Also back up each exercise's PR record for cross-device history.
    for (final we in session.exercises) {
      if (we.bestSet != null) {
        unawaited(
          _sync.updateExerciseHistory(
            exerciseId: we.exercise.id,
            maxWeight: we.maxWeight,
            maxVolume: we.totalVolume,
            lastPerformed: session.startTime,
          ),
        );
      }
    }
  }

  @override
  WorkoutSession? getActive() => HiveService.getActiveWorkout();

  @override
  Future<void> saveActive(WorkoutSession session) =>
      HiveService.saveActiveWorkout(session);

  @override
  Future<void> clearActive() => HiveService.clearActiveWorkout();

  @override
  Map<String, dynamic>? getHistory(String exerciseId) =>
      HiveService.getExerciseHistory(exerciseId);

  @override
  Future<void> updateHistory(String exerciseId, Map<String, dynamic> data) =>
      HiveService.updateExerciseHistory(exerciseId, data);
}

/// Supplies the app-wide [SessionRepository] implementation.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(ref.watch(firestoreSyncProvider));
});
