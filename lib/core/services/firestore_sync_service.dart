import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';

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
  static FirestoreSyncService? _instance;
  final FirebaseFirestore _db;

  FirestoreSyncService._() : _db = FirebaseFirestore.instance;

  static FirestoreSyncService get instance {
    _instance ??= FirestoreSyncService._();
    return _instance!;
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
      debugPrint('☁️ Synced session: ${session.name}');
    } catch (e) {
      debugPrint('⚠️ Failed to sync session: $e');
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
    } catch (e) {
      debugPrint('⚠️ Failed to fetch sessions: $e');
      return [];
    }
  }

  /// Delete a session from Firestore
  Future<void> deleteSession(String sessionId) async {
    if (_userId == null) return;
    try {
      await _sessionsRef.doc(sessionId).delete();
    } catch (e) {
      debugPrint('⚠️ Failed to delete session from cloud: $e');
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
      debugPrint('☁️ Synced routine: ${routine.name}');
    } catch (e) {
      debugPrint('⚠️ Failed to sync routine: $e');
    }
  }

  /// Fetch all routines from Firestore
  Future<List<Routine>> fetchRoutines() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _routinesRef.get();
      return snapshot.docs
          .map((doc) => Routine.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Failed to fetch routines: $e');
      return [];
    }
  }

  /// Delete a routine from Firestore
  Future<void> deleteRoutine(String routineId) async {
    if (_userId == null) return;
    try {
      await _routinesRef.doc(routineId).delete();
    } catch (e) {
      debugPrint('⚠️ Failed to delete routine from cloud: $e');
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
    } catch (e) {
      debugPrint('⚠️ Failed to update exercise history: $e');
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
    } catch (e) {
      debugPrint('⚠️ Failed to save preferences: $e');
    }
  }

  /// Fetch user preferences from Firestore
  Future<Map<String, dynamic>?> fetchPreferences() async {
    if (_userId == null) return null;
    try {
      final doc = await _userDoc.get();
      return doc.data()?['preferences'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch preferences: $e');
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
    } catch (e) {
      debugPrint('⚠️ Failed to save user profile: $e');
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

    // Rebuild local exercise-history (PR cache) from restored sessions so PR
    // detection keeps working offline.
    _rebuildExerciseHistory(sessions);

    await HiveService.saveSetting('last_synced_uid', uid);
    debugPrint(
        '☁️ Restored ${sessions.length} sessions, ${routines.length} routines from cloud');
    return (sessions: sessions.length, routines: routines.length);
  }

  /// Push all local data up to the cloud (used after first sign-up so any
  /// pre-existing local data is backed up).
  Future<void> pushAllLocal() async {
    if (_userId == null) return;
    for (final s in HiveService.getAllSessions()) {
      await syncSession(s);
    }
    for (final r in HiveService.getAllRoutines()) {
      await syncRoutine(r);
    }
    await HiveService.saveSetting('last_synced_uid', _userId!);
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
          maxVolume[id] =
              (maxVolume[id] ?? 0) < s.volume ? s.volume : (maxVolume[id] ?? 0);
          names[id] = we.exercise.name;
          final prev = lastDate[id];
          if (prev == null || session.startTime.isAfter(prev)) {
            lastDate[id] = session.startTime;
          }
        }
      }
    }

    for (final id in maxWeight.keys) {
      HiveService.updateExerciseHistory(id, {
        'maxWeight': maxWeight[id],
        'maxVolume': maxVolume[id],
        'lastPerformed': lastDate[id]?.toIso8601String(),
        'exerciseName': names[id],
      });
    }
  }
}

/// Provider for the Firestore sync service
final firestoreSyncProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService.instance;
});
