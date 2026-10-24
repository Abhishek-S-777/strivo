import 'package:strivo/features/workout/domain/entities/routine.dart';

/// Persistence boundary for workout [Routine] templates.
///
/// Presentation depends on this interface only; the Hive + Firestore
/// implementation lives in the data layer.
abstract interface class RoutineRepository {
  /// All stored routines, most recently updated first.
  List<Routine> getAll();

  /// The routine with [id], or null if none is stored.
  Routine? getById(String id);

  /// Persist [routine] locally and back it up to the cloud.
  Future<void> save(Routine routine);

  /// Remove the routine with [id] locally and from the cloud.
  Future<void> delete(String id);
}
