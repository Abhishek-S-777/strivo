import 'package:strivo/features/workout/domain/entities/exercise.dart';

/// Persistence boundary for the exercise library (built-in + user-custom).
///
/// Presentation depends on this interface only; the Hive + Firestore
/// implementation lives in the data layer. Built-in exercises ship with the app
/// (seeded on first launch); only custom exercises are backed up to the cloud.
abstract interface class ExerciseRepository {
  /// All exercises in the library, sorted by name.
  List<Exercise> getAll();

  /// Persist [exercise] locally, backing up custom ones to the cloud.
  Future<void> save(Exercise exercise);
}
