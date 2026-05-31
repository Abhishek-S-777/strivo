import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/exercise_set.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';

// ── Workout Sessions Provider ──
final workoutSessionsProvider =
    StateNotifierProvider<WorkoutSessionsNotifier, List<WorkoutSession>>((ref) {
  return WorkoutSessionsNotifier();
});

class WorkoutSessionsNotifier extends StateNotifier<List<WorkoutSession>> {
  WorkoutSessionsNotifier() : super([]) {
    _loadSessions();
  }

  void _loadSessions() {
    state = HiveService.getAllSessions();
  }

  Future<void> saveSession(WorkoutSession session) async {
    await HiveService.saveSession(session);
    _loadSessions();
  }

  Future<void> deleteSession(String id) async {
    await HiveService.deleteSession(id);
    _loadSessions();
    FirestoreSyncService.instance.deleteSession(id);
  }

  void refresh() => _loadSessions();

  WorkoutSession? getLastSessionForRoutine(String routineId) {
    return HiveService.getLastSessionByRoutine(routineId);
  }

  List<WorkoutSession> getSessionsInRange(DateTime start, DateTime end) {
    return HiveService.getSessionsInRange(start, end);
  }
}

// ── Active Workout Provider ──
final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, WorkoutSession?>((ref) {
  return ActiveWorkoutNotifier(ref);
});

class ActiveWorkoutNotifier extends StateNotifier<WorkoutSession?> {
  final Ref _ref;
  Timer? _autoSaveTimer;

  ActiveWorkoutNotifier(this._ref) : super(null) {
    // Restore active workout if app was killed
    final saved = HiveService.getActiveWorkout();
    if (saved != null && !saved.isCompleted) {
      state = saved;
      _startAutoSave();
    }
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (state != null) {
        HiveService.saveActiveWorkout(state!);
      }
    });
  }

  /// Start a new workout (empty or from routine)
  void startWorkout({Routine? routine}) {
    final now = DateTime.now();

    List<WorkoutExercise> exercises = [];

    if (routine != null) {
      // Pre-fill from routine template
      final lastSession =
          HiveService.getLastSessionByRoutine(routine.id);

      exercises = routine.exercises.map((re) {
        // Try to get previous sets for this exercise
        List<ExerciseSet> sets = [];
        if (lastSession != null) {
          final prevExercise = lastSession.exercises
              .where((e) => e.exercise.id == re.exercise.id)
              .firstOrNull;
          if (prevExercise != null) {
            // Pre-fill with previous session's data
            sets = List.generate(
              re.targetSets,
              (i) => i < prevExercise.sets.length
                  ? ExerciseSet.fromPrevious(
                      prevExercise.sets[i], i + 1)
                  : ExerciseSet.empty(i + 1),
            );
          }
        }
        if (sets.isEmpty) {
          sets = List.generate(
            re.targetSets,
            (i) => ExerciseSet.empty(i + 1),
          );
        }

        return WorkoutExercise(
          id: IdGenerator.generate(),
          exercise: re.exercise,
          sets: sets,
          order: re.order,
          restSeconds: re.restSeconds ?? 90,
          notes: re.notes,
        );
      }).toList();
    }

    state = WorkoutSession(
      id: IdGenerator.generate(),
      routineId: routine?.id,
      routineName: routine?.name,
      name: routine?.name ?? 'Quick Workout',
      exercises: exercises,
      startTime: now,
    );

    _startAutoSave();
    HiveService.saveActiveWorkout(state!);
  }

  /// Add exercise to active workout
  void addExercise(Exercise exercise, {int targetSets = 3}) {
    if (state == null) return;

    // Check previous history for this exercise
    final sessions = HiveService.getAllSessions();
    WorkoutExercise? prevExercise;
    for (final session in sessions) {
      final found = session.exercises
          .where((e) => e.exercise.id == exercise.id)
          .firstOrNull;
      if (found != null) {
        prevExercise = found;
        break;
      }
    }

    List<ExerciseSet> sets;
    if (prevExercise != null) {
      sets = List.generate(
        targetSets,
        (i) => i < prevExercise!.sets.length
            ? ExerciseSet.fromPrevious(prevExercise.sets[i], i + 1)
            : ExerciseSet.empty(i + 1),
      );
    } else {
      sets = List.generate(targetSets, (i) => ExerciseSet.empty(i + 1));
    }

    final newExercise = WorkoutExercise(
      id: IdGenerator.generate(),
      exercise: exercise,
      sets: sets,
      order: state!.exercises.length,
      restSeconds: 90,
    );

    state = state!.copyWith(
      exercises: [...state!.exercises, newExercise],
    );
  }

  /// Remove exercise from workout
  void removeExercise(String workoutExerciseId) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: state!.exercises
          .where((e) => e.id != workoutExerciseId)
          .toList(),
    );
  }

  /// Update a set in an exercise
  void updateSet(String workoutExerciseId, String setId, ExerciseSet newSet) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: state!.exercises.map((we) {
        if (we.id != workoutExerciseId) return we;
        return we.copyWith(
          sets: we.sets.map((s) => s.id == setId ? newSet : s).toList(),
        );
      }).toList(),
    );
  }

  /// Toggle set completion
  void toggleSetCompletion(String workoutExerciseId, String setId) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: state!.exercises.map((we) {
        if (we.id != workoutExerciseId) return we;
        return we.copyWith(
          sets: we.sets.map((s) {
            if (s.id != setId) return s;
            return s.copyWith(isCompleted: !s.isCompleted);
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Add a set to an exercise (duplicates last set)
  void addSet(String workoutExerciseId) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: state!.exercises.map((we) {
        if (we.id != workoutExerciseId) return we;
        final lastSet = we.sets.isNotEmpty ? we.sets.last : null;
        final newSet = lastSet != null
            ? ExerciseSet.fromPrevious(lastSet, we.sets.length + 1)
            : ExerciseSet.empty(we.sets.length + 1);
        return we.copyWith(sets: [...we.sets, newSet]);
      }).toList(),
    );
  }

  /// Remove last set from an exercise
  void removeSet(String workoutExerciseId, String setId) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: state!.exercises.map((we) {
        if (we.id != workoutExerciseId) return we;
        return we.copyWith(
          sets: we.sets.where((s) => s.id != setId).toList(),
        );
      }).toList(),
    );
  }

  /// Update exercise notes
  void updateExerciseNotes(String workoutExerciseId, String notes) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: state!.exercises.map((we) {
        if (we.id != workoutExerciseId) return we;
        return we.copyWith(notes: notes);
      }).toList(),
    );
  }

  /// Reorder exercises
  void reorderExercises(int oldIndex, int newIndex) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    final exercise = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, exercise);
    state = state!.copyWith(
      exercises: exercises
          .asMap()
          .entries
          .map((e) => e.value.copyWith(order: e.key))
          .toList(),
    );
  }

  /// Finish workout
  Future<WorkoutSession?> finishWorkout() async {
    if (state == null) return null;

    // Check for PRs
    final session = _checkForPRs(state!);

    final completed = session.copyWith(
      endTime: DateTime.now(),
      isCompleted: true,
    );

    // Save to sessions
    await _ref.read(workoutSessionsProvider.notifier).saveSession(completed);

    // Update exercise history
    _updateExerciseHistory(completed);

    // Update routine usage count
    if (completed.routineId != null) {
      final routine = HiveService.getRoutine(completed.routineId!);
      if (routine != null) {
        final updated = routine.copyWith(
          timesUsed: routine.timesUsed + 1,
          updatedAt: DateTime.now(),
        );
        await HiveService.saveRoutine(updated);
        FirestoreSyncService.instance.syncRoutine(updated);
      }
    }

    // Clear active workout
    await HiveService.clearActiveWorkout();
    _autoSaveTimer?.cancel();
    state = null;

    // Sync to Firestore in background (fire-and-forget)
    _syncToCloud(completed);

    return completed;
  }

  /// Background sync to Firestore
  void _syncToCloud(WorkoutSession session) {
    try {
      final syncService = FirestoreSyncService.instance;
      syncService.syncSession(session);

      // Also sync exercise PRs
      for (final we in session.exercises) {
        final bestSet = we.bestSet;
        if (bestSet != null) {
          syncService.updateExerciseHistory(
            exerciseId: we.exercise.id,
            maxWeight: we.maxWeight,
            maxVolume: we.totalVolume,
            lastPerformed: session.startTime,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Cloud sync skipped: $e');
    }
  }

  /// Discard workout
  Future<void> discardWorkout() async {
    await HiveService.clearActiveWorkout();
    _autoSaveTimer?.cancel();
    state = null;
  }

  /// Check if any sets are personal records
  WorkoutSession _checkForPRs(WorkoutSession session) {
    return session.copyWith(
      exercises: session.exercises.map((we) {
        // Get exercise history
        final history = HiveService.getExerciseHistory(we.exercise.id);
        double maxWeight = 0;
        double maxVolume = 0;

        if (history != null) {
          maxWeight = (history['maxWeight'] as num?)?.toDouble() ?? 0;
          maxVolume = (history['maxVolume'] as num?)?.toDouble() ?? 0;
        }

        return we.copyWith(
          sets: we.sets.map((s) {
            if (!s.isCompleted || s.isWarmup) return s;
            final isPR = s.weight > maxWeight ||
                s.volume > maxVolume;
            return s.copyWith(isPR: isPR);
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Update exercise history after completing workout
  void _updateExerciseHistory(WorkoutSession session) {
    for (final we in session.exercises) {
      final existing = HiveService.getExerciseHistory(we.exercise.id);
      double maxWeight = (existing?['maxWeight'] as num?)?.toDouble() ?? 0;
      double maxVolume = (existing?['maxVolume'] as num?)?.toDouble() ?? 0;

      for (final s in we.sets.where((s) => s.isCompleted && !s.isWarmup)) {
        if (s.weight > maxWeight) maxWeight = s.weight;
        if (s.volume > maxVolume) maxVolume = s.volume;
      }

      HiveService.updateExerciseHistory(we.exercise.id, {
        'maxWeight': maxWeight,
        'maxVolume': maxVolume,
        'lastPerformed': session.startTime.toIso8601String(),
        'exerciseName': we.exercise.name,
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

// ── Rest Timer Provider ──
final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;

  const RestTimerState({
    this.totalSeconds = 90,
    this.remainingSeconds = 0,
    this.isRunning = false,
  });

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  double get progress {
    if (totalSeconds == 0) return 0;
    return remainingSeconds / totalSeconds;
  }

  String get displayTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier() : super(const RestTimerState());

  void startTimer(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 0) {
        _timer?.cancel();
        state = state.copyWith(isRunning: false, remainingSeconds: 0);
        return;
      }
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    });
  }

  void stopTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
  }

  void addTime(int seconds) {
    state = state.copyWith(
      remainingSeconds: state.remainingSeconds + seconds,
      totalSeconds: state.totalSeconds + seconds,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Workout Duration Timer ──
final workoutDurationProvider = StreamProvider<Duration>((ref) {
  final workout = ref.watch(activeWorkoutProvider);
  if (workout == null) return const Stream.empty();

  return Stream.periodic(const Duration(seconds: 1), (_) {
    return DateTime.now().difference(workout.startTime);
  });
});

// ── Exercise Library Provider ──
final exerciseLibraryProvider =
    StateNotifierProvider<ExerciseLibraryNotifier, List<Exercise>>((ref) {
  return ExerciseLibraryNotifier();
});

class ExerciseLibraryNotifier extends StateNotifier<List<Exercise>> {
  ExerciseLibraryNotifier() : super([]) {
    state = HiveService.getAllExercises();
  }

  Future<void> addExercise(Exercise exercise) async {
    await HiveService.saveExercise(exercise);
    state = HiveService.getAllExercises();
  }

  List<Exercise> searchExercises(String query) {
    if (query.isEmpty) return state;
    final lower = query.toLowerCase();
    return state
        .where((e) =>
            e.name.toLowerCase().contains(lower) ||
            e.primaryMuscle.displayName.toLowerCase().contains(lower) ||
            e.equipment.displayName.toLowerCase().contains(lower))
        .toList();
  }

  List<Exercise> filterByMuscle(MuscleGroup muscle) {
    return state.where((e) => e.primaryMuscle == muscle).toList();
  }
}
