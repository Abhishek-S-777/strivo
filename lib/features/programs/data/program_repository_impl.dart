import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/programs/domain/program_repository.dart';

/// [ProgramRepository] backed by Hive (local) with Firestore cloud backup.
///
/// Writes land in Hive synchronously-awaited, then fan out to Firestore in the
/// background so the UI never blocks on the network (offline-first).
class ProgramRepositoryImpl implements ProgramRepository {
  const ProgramRepositoryImpl(this._sync);

  final FirestoreSyncService _sync;

  @override
  List<Program> getAll() => HiveService.getAllPrograms();

  @override
  Program? getById(String id) => HiveService.getProgram(id);

  @override
  Future<void> save(Program program) async {
    await HiveService.saveProgram(program);
    unawaited(_sync.syncProgram(program));
  }

  @override
  Future<void> delete(String id) async {
    await HiveService.deleteProgram(id);
    unawaited(_sync.deleteProgram(id));
  }

  @override
  String? getActiveId() => HiveService.getActiveProgramId();

  @override
  Future<void> setActiveId(String? id) => HiveService.setActiveProgramId(id);
}

/// Supplies the app-wide [ProgramRepository] implementation.
final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepositoryImpl(ref.watch(firestoreSyncProvider));
});
