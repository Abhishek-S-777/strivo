import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/features/routines/data/routine_repository_impl.dart';
import 'package:strivo/features/routines/domain/routine_repository.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';

/// The user's saved routines, kept in sync with the [RoutineRepository].
final routinesProvider = StateNotifierProvider<RoutinesNotifier, List<Routine>>(
  (ref) {
    return RoutinesNotifier(ref.watch(routineRepositoryProvider));
  },
);

class RoutinesNotifier extends StateNotifier<List<Routine>> {
  RoutinesNotifier(this._repo) : super(_repo.getAll());

  final RoutineRepository _repo;

  Future<void> saveRoutine(Routine routine) async {
    await _repo.save(routine);
    state = _repo.getAll();
  }

  Future<void> deleteRoutine(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();
}
