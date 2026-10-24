import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/settings/settings_repository.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/programs/presentation/providers/program_providers.dart';
import 'package:strivo/features/routines/data/routine_repository_impl.dart';
import 'package:strivo/features/routines/domain/routine_repository.dart';
import 'package:strivo/features/workout/data/exercise_repository_impl.dart';
import 'package:strivo/features/workout/data/session_repository_impl.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/exercise_set.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/domain/exercise_repository.dart';
import 'package:strivo/features/workout/domain/session_repository.dart';

// ── Default Rest Timer (user setting) ──
final defaultRestSecondsProvider =
    StateNotifierProvider<DefaultRestNotifier, int>((ref) {
      return DefaultRestNotifier(ref.watch(settingsRepositoryProvider));
    });

class DefaultRestNotifier extends StateNotifier<int> {
  DefaultRestNotifier(this._settings)
    : super(
        int.tryParse(_settings.getString('default_rest_seconds') ?? '') ?? 90,
      );

  final SettingsRepository _settings;

  void setSeconds(int seconds) {
    unawaited(_settings.setString('default_rest_seconds', seconds.toString()));
    state = seconds;
  }
}

// ── Workout Sessions Provider ──
final workoutSessionsProvider =
    StateNotifierProvider<WorkoutSessionsNotifier, List<WorkoutSession>>((ref) {
      return WorkoutSessionsNotifier(ref.watch(sessionRepositoryProvider));
    });

class WorkoutSessionsNotifier extends StateNotifier<List<WorkoutSession>> {
  WorkoutSessionsNotifier(this._repo) : super([]) {
    _loadSessions();
  }

  final SessionRepository _repo;

  void _loadSessions() {
    state = _repo.getAll();
  }

  Future<void> saveSession(WorkoutSession session) async {
    await _repo.save(session);
    _loadSessions();
  }

  Future<void> deleteSession(String id) async {
    await _repo.delete(id);
    _loadSessions();
  }

  void refresh() => _loadSessions();

  WorkoutSession? getLastSessionForRoutine(String routineId) {
    return _repo.getLastByRoutine(routineId);
  }

  WorkoutSession? getLastSessionForProgramDay(
    String programId,
    String dayName,
  ) {
    return _repo
        .getAll()
        .where(
          (s) =>
              s.isCompleted &&
              s.programId == programId &&
              s.programDayName == dayName,
        )
        .firstOrNull;
  }

  List<WorkoutSession> getSessionsInRange(DateTime start, DateTime end) {
    return _repo.getInRange(start, end);
  }
}

// ── Active Workout Provider ──
final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, WorkoutSession?>((ref) {
      return ActiveWorkoutNotifier(ref);
    });

class ActiveWorkoutNotifier extends StateNotifier<WorkoutSession?> {
  ActiveWorkoutNotifier(this._ref)
    : _sessions = _ref.read(sessionRepositoryProvider),
      _routines = _ref.read(routineRepositoryProvider),
      super(null) {
    // Restore active workout if app was killed
    final saved = _sessions.getActive();
    if (saved != null && !saved.isCompleted) {
      state = saved;
      _startAutoSave();
    }
  }

  final Ref _ref;
  final SessionRepository _sessions;
  final RoutineRepository _routines;
  Timer? _autoSaveTimer;

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (state != null) {
        unawaited(_sessions.saveActive(state!));
      }
    });
  }

  /// Start a new workout (empty or from routine)
  void startWorkout({Routine? routine}) {
    final now = DateTime.now();
    final defaultRest = _ref.read(defaultRestSecondsProvider);

    var exercises = <WorkoutExercise>[];

    if (routine != null) {
      // Pre-fill from routine template
      final lastSession = _sessions.getLastByRoutine(routine.id);

      exercises = routine.exercises.map((re) {
        // Try to get previous sets for this exercise
        var sets = <ExerciseSet>[];
        if (lastSession != null) {
          final prevExercise = lastSession.exercises
              .where((e) => e.exercise.id == re.exercise.id)
              .firstOrNull;
          if (prevExercise != null) {
            // Pre-fill with previous session's data
            sets = List.generate(
              re.targetSets,
              (i) => i < prevExercise.sets.length
                  ? ExerciseSet.fromPrevious(prevExercise.sets[i], i + 1)
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
          restSeconds: re.restSeconds ?? defaultRest,
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
    unawaited(_sessions.saveActive(state!));
  }

  /// Start the active program's current day. Prescribes this week's
  /// sets/reps/RPE from the program, and pre-fills the load from the lifter's
  /// most recent performance of each exercise so they progress on weight.
  void startProgramDay(Program program) {
    final day = program.currentDay;
    if (day == null) return;
    final now = DateTime.now();
    final week = program.currentWeek;
    final defaultRest = _ref.read(defaultRestSecondsProvider);

    final exercises = day.exercises.asMap().entries.map((entry) {
      final pe = entry.value;
      final target = pe.targetForWeek(week);
      final lastWeight = _lastWeightFor(pe.exercise.id);
      final sets = List.generate(
        target.sets.clamp(1, 20),
        (i) => ExerciseSet(
          id: IdGenerator.generate(),
          setNumber: i + 1,
          weight: lastWeight,
          reps: target.repsMin,
          rpe: target.rpe,
        ),
      );
      return WorkoutExercise(
        id: IdGenerator.generate(),
        exercise: pe.exercise,
        sets: sets,
        order: entry.key,
        restSeconds: defaultRest,
      );
    }).toList();

    state = WorkoutSession(
      id: IdGenerator.generate(),
      name: day.name,
      exercises: exercises,
      startTime: now,
      programId: program.id,
      programWeek: week,
      programDayName: day.name,
    );

    _startAutoSave();
    unawaited(_sessions.saveActive(state!));
  }

  /// Most recent working-set weight (kg) used for an exercise, for pre-fill.
  double _lastWeightFor(String exerciseId) {
    for (final session in _sessions.getAll()) {
      final we = session.exercises
          .where((e) => e.exercise.id == exerciseId)
          .firstOrNull;
      if (we == null) continue;
      final done = we.sets.where((s) => s.isCompleted && !s.isWarmup).toList();
      final pool = done.isNotEmpty ? done : we.sets;
      if (pool.isNotEmpty) {
        return pool.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
      }
    }
    return 0;
  }

  /// Add exercise to active workout
  void addExercise(Exercise exercise, {int targetSets = 3}) {
    if (state == null) return;

    // Check previous history for this exercise
    final sessions = _sessions.getAll();
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
      restSeconds: _ref.read(defaultRestSecondsProvider),
    );

    state = state!.copyWith(
      exercises: [...state!.exercises, newExercise],
    );
  }

  /// Swap an exercise for an alternative mid-workout (e.g. the machine is
  /// taken). Keeps the set/rep structure but re-prefills the load from the
  /// alternative's own history and clears completion/PR flags (it's a new lift).
  void replaceExercise(String workoutExerciseId, Exercise newExercise) {
    if (state == null) return;
    final lastWeight = _lastWeightFor(newExercise.id);
    state = state!.copyWith(
      exercises: state!.exercises.map((we) {
        if (we.id != workoutExerciseId) return we;
        final sets = we.sets
            .map(
              (s) => s.copyWith(
                weight: lastWeight > 0 ? lastWeight : s.weight,
                isCompleted: false,
                isPR: false,
              ),
            )
            .toList();
        return we.copyWith(exercise: newExercise, sets: sets);
      }).toList(),
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
      final routine = _routines.getById(completed.routineId!);
      if (routine != null) {
        final updated = routine.copyWith(
          timesUsed: routine.timesUsed + 1,
          updatedAt: DateTime.now(),
        );
        await _routines.save(updated);
      }
    }

    // Advance the program pointer if this came from a program day.
    if (completed.programId != null) {
      await _ref.read(programsProvider.notifier).advance(completed.programId!);
    }

    // Clear active workout
    await _sessions.clearActive();
    _autoSaveTimer?.cancel();
    state = null;

    // Back up to Firestore in the background (fire-and-forget).
    unawaited(_sessions.syncToCloud(completed));

    return completed;
  }

  /// Discard workout
  Future<void> discardWorkout() async {
    await _sessions.clearActive();
    _autoSaveTimer?.cancel();
    state = null;
  }

  /// Check if any sets are personal records
  WorkoutSession _checkForPRs(WorkoutSession session) {
    return session.copyWith(
      exercises: session.exercises.map((we) {
        // Get exercise history
        final history = _sessions.getHistory(we.exercise.id);
        double maxWeight = 0;
        double maxVolume = 0;

        if (history != null) {
          maxWeight = (history['maxWeight'] as num?)?.toDouble() ?? 0;
          maxVolume = (history['maxVolume'] as num?)?.toDouble() ?? 0;
        }

        return we.copyWith(
          sets: we.sets.map((s) {
            if (!s.isCompleted || s.isWarmup) return s;
            final isPR = s.weight > maxWeight || s.volume > maxVolume;
            return s.copyWith(isPR: isPR);
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Update exercise history after completing workout
  void _updateExerciseHistory(WorkoutSession session) {
    for (final we in session.exercises) {
      final existing = _sessions.getHistory(we.exercise.id);
      var maxWeight = (existing?['maxWeight'] as num?)?.toDouble() ?? 0;
      var maxVolume = (existing?['maxVolume'] as num?)?.toDouble() ?? 0;

      for (final s in we.sets.where((s) => s.isCompleted && !s.isWarmup)) {
        if (s.weight > maxWeight) maxWeight = s.weight;
        if (s.volume > maxVolume) maxVolume = s.volume;
      }

      unawaited(
        _sessions.updateHistory(we.exercise.id, {
          'maxWeight': maxWeight,
          'maxVolume': maxVolume,
          'lastPerformed': session.startTime.toIso8601String(),
          'exerciseName': we.exercise.name,
        }),
      );
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
  const RestTimerState({
    this.totalSeconds = 90,
    this.remainingSeconds = 0,
    this.isRunning = false,
  });
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;

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
  RestTimerNotifier() : super(const RestTimerState());
  Timer? _timer;

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
      return ExerciseLibraryNotifier(ref.watch(exerciseRepositoryProvider));
    });

class ExerciseLibraryNotifier extends StateNotifier<List<Exercise>> {
  ExerciseLibraryNotifier(this._repo) : super([]) {
    state = _repo.getAll();
  }

  final ExerciseRepository _repo;

  Future<void> addExercise(Exercise exercise) async {
    await _repo.save(exercise);
    state = _repo.getAll();
  }

  /// Resolve a list of exercise ids against the current library (used for an
  /// exercise's alternatives). Unknown ids are skipped.
  List<Exercise> resolveByIds(List<String> ids) {
    final byId = {for (final e in state) e.id: e};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  List<Exercise> searchExercises(String query) {
    if (query.isEmpty) return state;
    final lower = query.toLowerCase();
    return state
        .where(
          (e) =>
              e.name.toLowerCase().contains(lower) ||
              e.primaryMuscle.displayName.toLowerCase().contains(lower) ||
              e.equipment.displayName.toLowerCase().contains(lower),
        )
        .toList();
  }

  List<Exercise> filterByMuscle(MuscleGroup muscle) {
    return state.where((e) => e.primaryMuscle == muscle).toList();
  }
}
