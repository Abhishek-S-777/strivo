import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/features/routines/domain/routine_repository.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';

/// [RoutineRepository] backed by Hive (local) with Firestore cloud backup.
///
/// Writes land in Hive synchronously-awaited, then fan out to Firestore in the
/// background so the UI never blocks on the network (offline-first).
class RoutineRepositoryImpl implements RoutineRepository {
  const RoutineRepositoryImpl(this._sync);

  final FirestoreSyncService _sync;

  @override
  List<Routine> getAll() => HiveService.getAllRoutines();

  @override
  Routine? getById(String id) => HiveService.getRoutine(id);

  @override
  Future<void> save(Routine routine) async {
    await HiveService.saveRoutine(routine);
    unawaited(_sync.syncRoutine(routine));
  }

  @override
  Future<void> delete(String id) async {
    await HiveService.deleteRoutine(id);
    unawaited(_sync.deleteRoutine(id));
  }
}

/// Supplies the app-wide [RoutineRepository] implementation.
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepositoryImpl(ref.watch(firestoreSyncProvider));
});
