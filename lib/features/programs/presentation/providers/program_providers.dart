import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';

/// The id of the user's active program (device-local; programs themselves sync).
final activeProgramIdProvider =
    StateNotifierProvider<ActiveProgramIdNotifier, String?>((ref) {
      return ActiveProgramIdNotifier();
    });

class ActiveProgramIdNotifier extends StateNotifier<String?> {
  ActiveProgramIdNotifier() : super(HiveService.getActiveProgramId());

  Future<void> set(String? id) async {
    await HiveService.setActiveProgramId(id);
    state = id;
  }
}

final programsProvider = StateNotifierProvider<ProgramsNotifier, List<Program>>(
  (ref) {
    return ProgramsNotifier(ref);
  },
);

class ProgramsNotifier extends StateNotifier<List<Program>> {
  ProgramsNotifier(this._ref) : super(HiveService.getAllPrograms());
  final Ref _ref;

  Future<void> save(Program program) async {
    await HiveService.saveProgram(program);
    state = HiveService.getAllPrograms();
    unawaited(FirestoreSyncService.instance.syncProgram(program));
  }

  Future<void> delete(String id) async {
    await HiveService.deleteProgram(id);
    if (_ref.read(activeProgramIdProvider) == id) {
      await _ref.read(activeProgramIdProvider.notifier).set(null);
    }
    state = HiveService.getAllPrograms();
    unawaited(FirestoreSyncService.instance.deleteProgram(id));
  }

  void refresh() => state = HiveService.getAllPrograms();

  /// Advance a program's pointer after its current day was completed.
  Future<Program?> advance(String id) async {
    final program = HiveService.getProgram(id);
    if (program == null) return null;
    final next = program.advanced();
    await save(next);
    return next;
  }

  Future<void> restart(String id) async {
    final program = HiveService.getProgram(id);
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
