import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/features/programs/data/program_repository_impl.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/programs/domain/program_repository.dart';

/// The id of the user's active program (device-local; programs themselves sync).
final activeProgramIdProvider =
    StateNotifierProvider<ActiveProgramIdNotifier, String?>((ref) {
      return ActiveProgramIdNotifier(ref.watch(programRepositoryProvider));
    });

class ActiveProgramIdNotifier extends StateNotifier<String?> {
  ActiveProgramIdNotifier(this._repo) : super(_repo.getActiveId());

  final ProgramRepository _repo;

  Future<void> set(String? id) async {
    await _repo.setActiveId(id);
    state = id;
  }
}

final programsProvider = StateNotifierProvider<ProgramsNotifier, List<Program>>(
  (ref) {
    return ProgramsNotifier(ref);
  },
);

class ProgramsNotifier extends StateNotifier<List<Program>> {
  ProgramsNotifier(this._ref)
    : _repo = _ref.read(programRepositoryProvider),
      super(_ref.read(programRepositoryProvider).getAll());

  final Ref _ref;
  final ProgramRepository _repo;

  Future<void> save(Program program) async {
    await _repo.save(program);
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    if (_ref.read(activeProgramIdProvider) == id) {
      await _ref.read(activeProgramIdProvider.notifier).set(null);
    }
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();

  /// Advance a program's pointer after its current day was completed.
  Future<Program?> advance(String id) async {
    final program = _repo.getById(id);
    if (program == null) return null;
    final next = program.advanced();
    await save(next);
    return next;
  }

  Future<void> restart(String id) async {
    final program = _repo.getById(id);
    if (program == null) return;
    await save(program.restarted());
  }
}

/// The currently active [Program], or null. Reacts to both the program list
/// and the active-id selection.
final activeProgramProvider = Provider<Program?>((ref) {
  final id = ref.watch(activeProgramIdProvider);
  final programs = ref.watch(programsProvider);
  if (id == null) return null;
  for (final p in programs) {
    if (p.id == id) return p;
  }
  return null;
});
