import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/exercise_repository.dart';

/// [ExerciseRepository] backed by Hive (local) with Firestore cloud backup for
/// custom exercises.
class ExerciseRepositoryImpl implements ExerciseRepository {
  const ExerciseRepositoryImpl(this._sync);

  final FirestoreSyncService _sync;

  @override
  List<Exercise> getAll() => HiveService.getAllExercises();

  @override
  Future<void> save(Exercise exercise) async {
    await HiveService.saveExercise(exercise);
    // Built-ins ship with the app; only custom exercises need cloud backup.
    if (exercise.isCustom) {
      unawaited(_sync.syncExercise(exercise));
    }
  }
}

/// Supplies the app-wide [ExerciseRepository] implementation.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepositoryImpl(ref.watch(firestoreSyncProvider));
});
