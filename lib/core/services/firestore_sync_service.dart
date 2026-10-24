import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/logging/app_logger.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';

/// Provider for the current Firebase Auth user
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Whether Firebase is available and user is signed in
final isCloudSyncEnabledProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseUserProvider);
  return user.whenOrNull(data: (u) => u != null) ?? false;
});

/// Firestore sync service — manages cloud backup of workouts/routines
class FirestoreSyncService {
  FirestoreSyncService._() : _db = FirebaseFirestore.instance;
  static FirestoreSyncService? _instance;
  final FirebaseFirestore _db;

  // Singleton accessor; a factory constructor is intentionally not used so
  // callers read as `FirestoreSyncService.instance`.
  // ignore: prefer_constructors_over_static_methods
  static FirestoreSyncService get instance {
    return _instance ??= FirestoreSyncService._();
  }

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // ── Session Sync ──────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _sessionsRef {
    if (_userId == null) throw StateError('User not signed in');
    return _db.collection('users').doc(_userId).collection('sessions');
  }

  /// Upload a completed workout session to Firestore
  Future<void> syncSession(WorkoutSession session) async {
    if (_userId == null) return;
    try {
      await _sessionsRef.doc(session.id).set(
        {...session.toMap(), 'syncedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      AppLogger.debug('Synced session: ${session.name}');
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to sync session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetch all sessions from Firestore
  Future<List<WorkoutSession>> fetchSessions() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _sessionsRef
          .orderBy('startTime', descending: true)
          .limit(100)
          .get();
      return snapshot.docs
          .map((doc) => WorkoutSession.fromMap(doc.data()))
          .toList();
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to fetch sessions',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Delete a session from Firestore
  Future<void> deleteSession(String sessionId) async {
    if (_userId == null) return;
    try {
      await _sessionsRef.doc(sessionId).delete();
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to delete session from cloud',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ── Routine Sync ──────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _routinesRef {
    if (_userId == null) throw StateError('User not signed in');
    return _db.collection('users').doc(_userId).collection('routines');
  }

  /// Upload a routine to Firestore
  Future<void> syncRoutine(Routine routine) async {
    if (_userId == null) return;
    try {
      await _routinesRef.doc(routine.id).set(
        {...routine.toMap(), 'syncedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      AppLogger.debug('Synced routine: ${routine.name}');
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to sync routine',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetch all routines from Firestore
  Future<List<Routine>> fetchRoutines() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _routinesRef.get();
      return snapshot.docs.map((doc) => Routine.fromMap(doc.data())).toList();
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to fetch routines',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Delete a routine from Firestore
  Future<void> deleteRoutine(String routineId) async {
    if (_userId == null) return;
    try {
      await _routinesRef.doc(routineId).delete();
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to delete routine from cloud',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ── Program Sync ──────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _programsRef {
    if (_userId == null) throw StateError('User not signed in');
    return _db.collection('users').doc(_userId).collection('programs');
  }

  Future<void> syncProgram(Program program) async {
    if (_userId == null) return;
    try {
      await _programsRef.doc(program.id).set(
        {...program.toMap(), 'syncedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      AppLogger.debug('Synced program: ${program.name}');
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to sync program',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Program>> fetchPrograms() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _programsRef.get();
      return snapshot.docs.map((doc) => Program.fromMap(doc.data())).toList();
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to fetch programs',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<void> deleteProgram(String programId) async {
    if (_userId == null) return;
    try {
      await _programsRef.doc(programId).delete();
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to delete program from cloud',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ── Exercise Library Sync (custom exercises only) ─────────────

  CollectionReference<Map<String, dynamic>> get _exercisesRef {
    if (_userId == null) throw StateError('User not signed in');
    return _db.collection('users').doc(_userId).collection('exercises');
  }

  /// Back up a *custom* exercise. Built-in (seeded) exercises ship with the
  /// app and don't need per-user storage, so only user-created ones are
  /// persisted to the cloud — surviving uninstall and reaching new devices.
  Future<void> syncExercise(Exercise exercise) async {
    if (_userId == null || !exercise.isCustom) return;
    try {
      await _exercisesRef.doc(exercise.id).set(
        {...exercise.toMap(), 'syncedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      AppLogger.debug('Synced exercise: ${exercise.name}');
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to sync exercise',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetch the user's custom exercises from Firestore.
  Future<List<Exercise>> fetchExercises() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _exercisesRef.get();
      return snapshot.docs.map((doc) => Exercise.fromMap(doc.data())).toList();
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to fetch exercises',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // ── Exercise History (PR Tracking) ────────────────────────────

  CollectionReference<Map<String, dynamic>> get _exerciseHistoryRef {
    if (_userId == null) throw StateError('User not signed in');
    return _db.collection('users').doc(_userId).collection('exercise_history');
  }

  /// Update exercise PR records in Firestore
  Future<void> updateExerciseHistory({
    required String exerciseId,
    required double maxWeight,
    required double maxVolume,
    required DateTime lastPerformed,
  }) async {
    if (_userId == null) return;
    try {
      await _exerciseHistoryRef.doc(exerciseId).set({
        'exerciseId': exerciseId,
        'maxWeight': maxWeight,
        'maxVolume': maxVolume,
        'lastPerformed': lastPerformed.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to update exercise history',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ── User Profile ──────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> get _userDoc {
    if (_userId == null) throw StateError('User not signed in');
    return _db.collection('users').doc(_userId);
  }

  /// Save user preferences to Firestore
  Future<void> savePreferences(Map<String, dynamic> prefs) async {
    if (_userId == null) return;
    try {
      await _userDoc.set({
        'preferences': prefs,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to save preferences',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetch user preferences from Firestore
  Future<Map<String, dynamic>?> fetchPreferences() async {
    if (_userId == null) return null;
    try {
      final doc = await _userDoc.get();
      return doc.data()?['preferences'] as Map<String, dynamic>?;
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to fetch preferences',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Create/update the user's profile document.
  Future<void> saveUserProfile({
    String? displayName,
    String? email,
  }) async {
    if (_userId == null) return;
    try {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) data['displayName'] = displayName;
      if (email != null) data['email'] = email;
      await _userDoc.set(data, SetOptions(merge: true));
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to save user profile',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ── Bulk sync (sign-in / sign-up) ────────────────────────────────

  /// Pull all cloud data into local Hive. Returns the merged counts.
  ///
  /// If a *different* user previously synced on this device, local training
  /// data is wiped first so accounts never mix. Same-account re-login merges
  /// (cloud wins on id collisions, local-only records are preserved).
  Future<({int sessions, int routines})> restoreFromCloud() async {
    final uid = _userId;
    if (uid == null) return (sessions: 0, routines: 0);

    final lastUid = HiveService.getSetting('last_synced_uid');
    if (lastUid != null && lastUid != uid) {
      await HiveService.clearUserData();
    }

    final sessions = await fetchSessions();
    for (final s in sessions) {
      await HiveService.saveSession(s);
    }

    final routines = await fetchRoutines();
    for (final r in routines) {
      await HiveService.saveRoutine(r);
    }

    final programs = await fetchPrograms();
    for (final pr in programs) {
      await HiveService.saveProgram(pr);
    }

    // Restore the user's custom exercises (built-ins come from the app seed).
    final exercises = await fetchExercises();
    for (final ex in exercises) {
      await HiveService.saveExercise(ex);
    }

    // Safety net: re-add any exercise embedded in restored
    // sessions/routines/programs that isn't in the local library — e.g.
    // customs created before cloud exercise-sync existed — so the picker and
    // history keep resolving them.
    await _restoreEmbeddedExercises(sessions, routines, programs);

    // Rebuild local exercise-history (PR cache) from restored sessions so PR
    // detection keeps working offline.
    _rebuildExerciseHistory(sessions);

    await HiveService.saveSetting('last_synced_uid', uid);
    AppLogger.debug(
      'Restored ${sessions.length} sessions, ${routines.length} routines, '
      '${programs.length} programs from cloud',
    );
    return (sessions: sessions.length, routines: routines.length);
  }

  /// Push all local data up to the cloud (used after first sign-up so any
  /// pre-existing local data is backed up).
  Future<void> pushAllLocal() async {
    final uid = _userId;
    if (uid == null) return;
    for (final s in HiveService.getAllSessions()) {
      await syncSession(s);
    }
    for (final r in HiveService.getAllRoutines()) {
      await syncRoutine(r);
    }
    for (final pr in HiveService.getAllPrograms()) {
      await syncProgram(pr);
    }
    for (final ex in HiveService.getAllExercises().where((e) => e.isCustom)) {
      await syncExercise(ex);
    }
    await HiveService.saveSetting('last_synced_uid', uid);
  }

  /// Re-add any exercise embedded in the given records whose id is missing
  /// from the local library, so it resolves in the picker/history again.
  /// Unknown ids are marked custom (they aren't built-ins) so they also get
  /// backed up on the next sync.
  Future<void> _restoreEmbeddedExercises(
    List<WorkoutSession> sessions,
    List<Routine> routines,
    List<Program> programs,
  ) async {
    final known = HiveService.getAllExercises().map((e) => e.id).toSet();
    final seen = <String>{};
    final toAdd = <Exercise>[];

    void consider(Exercise e) {
      if (known.contains(e.id) || !seen.add(e.id)) return;
      toAdd.add(e.isCustom ? e : e.copyWith(isCustom: true));
    }

    for (final s in sessions) {
      for (final we in s.exercises) {
        consider(we.exercise);
      }
    }
    for (final r in routines) {
      for (final re in r.exercises) {
        consider(re.exercise);
      }
    }
    for (final p in programs) {
      for (final d in p.days) {
        for (final pe in d.exercises) {
          consider(pe.exercise);
        }
      }
    }

    for (final e in toAdd) {
      await HiveService.saveExercise(e);
    }
  }

  void _rebuildExerciseHistory(List<WorkoutSession> sessions) {
    final maxWeight = <String, double>{};
    final maxVolume = <String, double>{};
    final lastDate = <String, DateTime>{};
    final names = <String, String>{};

    for (final session in sessions) {
      for (final we in session.exercises) {
        for (final s in we.sets.where((s) => s.isCompleted && !s.isWarmup)) {
          final id = we.exercise.id;
          maxWeight[id] = (maxWeight[id] ?? 0) < s.weight
              ? s.weight
              : (maxWeight[id] ?? 0);
          maxVolume[id] = (maxVolume[id] ?? 0) < s.volume
              ? s.volume
              : (maxVolume[id] ?? 0);
          names[id] = we.exercise.name;
          final prev = lastDate[id];
          if (prev == null || session.startTime.isAfter(prev)) {
            lastDate[id] = session.startTime;
          }
        }
      }
    }

    for (final id in maxWeight.keys) {
      unawaited(
        HiveService.updateExerciseHistory(id, {
          'maxWeight': maxWeight[id],
          'maxVolume': maxVolume[id],
          'lastPerformed': lastDate[id]?.toIso8601String(),
          'exerciseName': names[id],
        }),
      );
    }
  }
}

/// Provider for the Firestore sync service
final firestoreSyncProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService.instance;
});
