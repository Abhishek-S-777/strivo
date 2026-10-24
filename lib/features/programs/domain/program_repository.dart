import 'package:strivo/features/programs/domain/entities/program.dart';

/// Persistence boundary for multi-week [Program]s.
///
/// Presentation depends on this interface only; the Hive + Firestore
/// implementation lives in the data layer. The active-program pointer is
/// device-local (not synced), while the programs themselves are backed up.
abstract interface class ProgramRepository {
  /// All stored programs, most recently updated first.
  List<Program> getAll();

  /// The program with [id], or null if none is stored.
  Program? getById(String id);

  /// Persist [program] locally and back it up to the cloud.
  Future<void> save(Program program);

  /// Remove the program with [id] locally and from the cloud.
  Future<void> delete(String id);

  /// The id of the active program, or null if none is selected.
  String? getActiveId();

  /// Set (or clear, when null) the active-program pointer. Device-local.
  Future<void> setActiveId(String? id);
}
