import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';

/// Hive box names
class HiveBoxes {
  static const String sessions = 'workout_sessions';
  static const String routines = 'routines';
  static const String exercises = 'exercises';
  static const String activeWorkout = 'active_workout';
  static const String settings = 'settings';
  static const String exerciseHistory = 'exercise_history';
  static const String programs = 'programs';
}

class HiveService {
  /// Bump when the bundled exercise library changes (new exercises, edited
  /// metadata, or populated alternatives). On launch, a higher version than
  /// what's stored re-seeds the built-in exercises — overwriting only the
  /// known `ex_*` seed ids and leaving the user's custom exercises untouched.
  static const int exerciseSeedVersion = 3;

  static late Box<String> _sessionsBox;
  static late Box<String> _routinesBox;
  static late Box<String> _exercisesBox;
  static late Box<String> _activeWorkoutBox;
  static late Box<String> _settingsBox;
  static late Box<String> _exerciseHistoryBox;
  static late Box<String> _programsBox;

  static Future<void> init() async {
    _sessionsBox = await Hive.openBox<String>(HiveBoxes.sessions);
    _routinesBox = await Hive.openBox<String>(HiveBoxes.routines);
    _exercisesBox = await Hive.openBox<String>(HiveBoxes.exercises);
    _activeWorkoutBox = await Hive.openBox<String>(HiveBoxes.activeWorkout);
    _settingsBox = await Hive.openBox<String>(HiveBoxes.settings);
    _exerciseHistoryBox = await Hive.openBox<String>(HiveBoxes.exerciseHistory);
    _programsBox = await Hive.openBox<String>(HiveBoxes.programs);

    // Seed (or re-seed) the built-in exercise library. Runs on first launch
    // and whenever [exerciseSeedVersion] is bumped, so existing installs pick
    // up newly bundled exercises without losing their custom ones.
    final storedSeed =
        int.tryParse(_settingsBox.get('exercise_seed_version') ?? '') ?? 0;
    if (_exercisesBox.isEmpty || storedSeed < exerciseSeedVersion) {
      await _seedDefaultExercises();
      await _settingsBox.put('exercise_seed_version', '$exerciseSeedVersion');
    }
  }

  // ── Sessions ──
  static Future<void> saveSession(WorkoutSession session) async {
    await _sessionsBox.put(session.id, jsonEncode(session.toMap()));
  }

  static Future<void> deleteSession(String id) async {
    await _sessionsBox.delete(id);
  }

  static List<WorkoutSession> getAllSessions() {
    return _sessionsBox.values
        .map(
          (json) =>
              WorkoutSession.fromMap(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  static WorkoutSession? getSession(String id) {
    final json = _sessionsBox.get(id);
    if (json == null) return null;
    return WorkoutSession.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  static List<WorkoutSession> getSessionsByRoutine(String routineId) {
    return getAllSessions()
        .where((s) => s.routineId == routineId && s.isCompleted)
        .toList();
  }

  static WorkoutSession? getLastSessionByRoutine(String routineId) {
    final sessions = getSessionsByRoutine(routineId);
    return sessions.isNotEmpty ? sessions.first : null;
  }

  static List<WorkoutSession> getSessionsInRange(DateTime start, DateTime end) {
    return getAllSessions()
        .where(
          (s) =>
              s.startTime.isAfter(start) &&
              s.startTime.isBefore(end) &&
              s.isCompleted,
        )
        .toList();
  }

  // ── Routines ──
  static Future<void> saveRoutine(Routine routine) async {
    await _routinesBox.put(routine.id, jsonEncode(routine.toMap()));
  }

  static Future<void> deleteRoutine(String id) async {
    await _routinesBox.delete(id);
  }

  static List<Routine> getAllRoutines() {
    return _routinesBox.values
        .map(
          (json) => Routine.fromMap(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Routine? getRoutine(String id) {
    final json = _routinesBox.get(id);
    if (json == null) return null;
    return Routine.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  // ── Exercises (template library) ──
  static Future<void> saveExercise(Exercise exercise) async {
    await _exercisesBox.put(exercise.id, jsonEncode(exercise.toMap()));
  }

  static List<Exercise> getAllExercises() {
    return _exercisesBox.values
        .map(
          (json) => Exercise.fromMap(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<Exercise> getExercisesByMuscle(MuscleGroup muscle) {
    return getAllExercises().where((e) => e.primaryMuscle == muscle).toList();
  }

  // ── Active Workout (auto-save) ──
  static Future<void> saveActiveWorkout(WorkoutSession session) async {
    await _activeWorkoutBox.put('current', jsonEncode(session.toMap()));
  }

  static WorkoutSession? getActiveWorkout() {
    final json = _activeWorkoutBox.get('current');
    if (json == null) return null;
    return WorkoutSession.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  static Future<void> clearActiveWorkout() async {
    await _activeWorkoutBox.delete('current');
  }

  static bool hasActiveWorkout() {
    return _activeWorkoutBox.containsKey('current');
  }

  // ── Exercise History (for PR tracking) ──
  static Future<void> updateExerciseHistory(
    String exerciseId,
    Map<String, dynamic> data,
  ) async {
    await _exerciseHistoryBox.put(exerciseId, jsonEncode(data));
  }

  static Map<String, dynamic>? getExerciseHistory(String exerciseId) {
    final json = _exerciseHistoryBox.get(exerciseId);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  // ── Programs ──
  static Future<void> saveProgram(Program program) async {
    await _programsBox.put(program.id, jsonEncode(program.toMap()));
  }

  static Future<void> deleteProgram(String id) async {
    await _programsBox.delete(id);
  }

  static List<Program> getAllPrograms() {
    return _programsBox.values
        .map(
          (json) => Program.fromMap(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Program? getProgram(String id) {
    final json = _programsBox.get(id);
    if (json == null) return null;
    return Program.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  static String? getActiveProgramId() => _settingsBox.get('active_program_id');

  static Future<void> setActiveProgramId(String? id) async {
    if (id == null) {
      await _settingsBox.delete('active_program_id');
    } else {
      await _settingsBox.put('active_program_id', id);
    }
  }

  // ── Settings ──
  static Future<void> saveSetting(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  static String? getSetting(String key) {
    return _settingsBox.get(key);
  }

  // ── Account lifecycle ──
  /// Wipes all per-user training data. Used when a *different* account signs
  /// in on this device so cloud data can be restored cleanly without mixing.
  /// Settings (preferences) and the seeded exercise library are preserved.
  static Future<void> clearUserData() async {
    await _sessionsBox.clear();
    await _routinesBox.clear();
    await _exerciseHistoryBox.clear();
    await _activeWorkoutBox.clear();
    await _programsBox.clear();
    await _settingsBox.delete('active_program_id');
  }

  // ── Seed Data ──
  /// Writes the built-in exercise library, keyed by stable `ex_*` ids. Re-run
  /// on a seed-version bump: it overwrites only these known ids (refreshing
  /// metadata / alternatives) and never deletes or touches user-custom
  /// exercises, which use random ids.
  static Future<void> _seedDefaultExercises() async {
    final exercises = [
      // Chest
      const Exercise(
        id: 'ex_bench_press',
        name: 'Bench Press',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_incline_bench',
        name: 'Incline Bench Press',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_db_bench',
        name: 'Dumbbell Bench Press',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_incline_db',
        name: 'Incline Dumbbell Press',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_cable_fly',
        name: 'Cable Fly',
        primaryMuscle: MuscleGroup.chest,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_chest_dip',
        name: 'Chest Dip',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_pec_deck',
        name: 'Pec Deck',
        primaryMuscle: MuscleGroup.chest,
        equipment: Equipment.machine,
      ),
      // Back
      const Exercise(
        id: 'ex_deadlift',
        name: 'Deadlift',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.legs,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_barbell_row',
        name: 'Barbell Row',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_pullup',
        name: 'Pull Up',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_lat_pulldown',
        name: 'Lat Pulldown',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_cable_row',
        name: 'Seated Cable Row',
        primaryMuscle: MuscleGroup.back,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_db_row',
        name: 'Dumbbell Row',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_tbar_row',
        name: 'T-Bar Row',
        primaryMuscle: MuscleGroup.back,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_face_pull',
        name: 'Face Pull',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.cable,
      ),
      // Shoulders
      const Exercise(
        id: 'ex_ohp',
        name: 'Overhead Press',
        primaryMuscle: MuscleGroup.shoulders,
        secondaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_db_shoulder_press',
        name: 'Dumbbell Shoulder Press',
        primaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_lateral_raise',
        name: 'Lateral Raise',
        primaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_front_raise',
        name: 'Front Raise',
        primaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_rear_delt_fly',
        name: 'Rear Delt Fly',
        primaryMuscle: MuscleGroup.shoulders,
        secondaryMuscle: MuscleGroup.back,
        equipment: Equipment.dumbbell,
      ),
      // Biceps
      const Exercise(
        id: 'ex_barbell_curl',
        name: 'Barbell Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_db_curl',
        name: 'Dumbbell Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_hammer_curl',
        name: 'Hammer Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_preacher_curl',
        name: 'Preacher Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_cable_curl',
        name: 'Cable Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.cable,
      ),
      // Triceps
      const Exercise(
        id: 'ex_tricep_pushdown',
        name: 'Tricep Pushdown',
        primaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_skull_crusher',
        name: 'Skull Crusher',
        primaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_overhead_extension',
        name: 'Overhead Tricep Extension',
        primaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_close_grip_bench',
        name: 'Close Grip Bench Press',
        primaryMuscle: MuscleGroup.triceps,
        secondaryMuscle: MuscleGroup.chest,
        equipment: Equipment.barbell,
      ),
      // Legs
      const Exercise(
        id: 'ex_squat',
        name: 'Squat',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_front_squat',
        name: 'Front Squat',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_leg_press',
        name: 'Leg Press',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_romanian_dl',
        name: 'Romanian Deadlift',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_leg_curl',
        name: 'Leg Curl',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_leg_extension',
        name: 'Leg Extension',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_calf_raise',
        name: 'Calf Raise',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_lunge',
        name: 'Lunge',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_bulgarian_split',
        name: 'Bulgarian Split Squat',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_hack_squat',
        name: 'Hack Squat',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.machine,
      ),
      // Glutes
      const Exercise(
        id: 'ex_hip_thrust',
        name: 'Hip Thrust',
        primaryMuscle: MuscleGroup.glutes,
        secondaryMuscle: MuscleGroup.legs,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_cable_kickback',
        name: 'Cable Kickback',
        primaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.cable,
      ),
      // Core
      const Exercise(
        id: 'ex_plank',
        name: 'Plank',
        primaryMuscle: MuscleGroup.core,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_cable_crunch',
        name: 'Cable Crunch',
        primaryMuscle: MuscleGroup.core,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_hanging_leg_raise',
        name: 'Hanging Leg Raise',
        primaryMuscle: MuscleGroup.core,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_ab_wheel',
        name: 'Ab Wheel Rollout',
        primaryMuscle: MuscleGroup.core,
        equipment: Equipment.other,
      ),

      // ── Jeff Nippard 12-Week program movements ──
      // Upper (Strength)
      const Exercise(
        id: 'ex_incline_machine_press_45',
        name: '45° Incline Machine Press',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_bottom_half_db_flye',
        name: 'Bottom-Half DB Flye',
        primaryMuscle: MuscleGroup.chest,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_dual_handle_lat_pulldown',
        name: 'Dual-Handle Lat Pulldown',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_lean_in_db_lateral_raise',
        name: 'Lean-In DB Lateral Raise',
        primaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_single_arm_db_row',
        name: 'Single-Arm DB Row',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_db_skull_crusher',
        name: 'DB Skull Crusher',
        primaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_incline_db_stretch_curl',
        name: 'Incline DB Stretch Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.dumbbell,
      ),
      // Lower (Strength)
      const Exercise(
        id: 'ex_nordic_ham_curl',
        name: 'Nordic Ham Curl',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_high_bar_back_squat',
        name: 'High-Bar Back Squat',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_snatch_grip_rdl',
        name: 'Snatch-Grip RDL',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.back,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_sissy_squat',
        name: 'Sissy Squat',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_leg_press_calf_press',
        name: 'Leg Press Calf Press',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_machine_crunch',
        name: 'Machine Crunch',
        primaryMuscle: MuscleGroup.core,
        equipment: Equipment.machine,
      ),
      // Pull (Hypertrophy)
      const Exercise(
        id: 'ex_incline_chest_supported_db_row',
        name: 'Incline Chest-Supported DB Row',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_reverse_pec_deck',
        name: 'Reverse Pec Deck',
        primaryMuscle: MuscleGroup.shoulders,
        secondaryMuscle: MuscleGroup.back,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_db_shrug',
        name: 'DB Shrug',
        primaryMuscle: MuscleGroup.back,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_db_preacher_curl',
        name: 'DB Preacher Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.dumbbell,
      ),
      // Push (Hypertrophy)
      const Exercise(
        id: 'ex_low_to_high_cable_crossover',
        name: 'Low-to-High Cable Crossover',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_bench_dip',
        name: 'Bench Dip',
        primaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_modified_candlestick',
        name: 'Modified Candlestick',
        primaryMuscle: MuscleGroup.core,
        equipment: Equipment.bodyweight,
      ),
      // Legs (Hypertrophy)
      const Exercise(
        id: 'ex_db_walking_lunge',
        name: 'DB Walking Lunge',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_goblet_squat',
        name: 'Goblet Squat',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_lateral_band_walk',
        name: 'Lateral Band Walk',
        primaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.band,
      ),

      // ── Alternative exercises (substitutes referenced by alternativeIds) ──
      // Chest
      const Exercise(
        id: 'ex_incline_db_press_45',
        name: '45° Incline DB Press',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_incline_barbell_press_45',
        name: '45° Incline Barbell Press',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_cable_crossover_ladder',
        name: 'Cable Crossover Ladder',
        primaryMuscle: MuscleGroup.chest,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_machine_chest_press',
        name: 'Machine Chest Press',
        primaryMuscle: MuscleGroup.chest,
        secondaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_bottom_half_seated_cable_flye',
        name: 'Bottom-Half Seated Cable Flye',
        primaryMuscle: MuscleGroup.chest,
        equipment: Equipment.cable,
      ),
      // Back
      const Exercise(
        id: 'ex_wide_grip_lat_pulldown',
        name: 'Wide-Grip Lat Pulldown',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_wide_grip_pullup',
        name: 'Wide-Grip Pull-Up',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_neutral_grip_pullup',
        name: 'Neutral-Grip Pull-Up',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_neutral_grip_lat_pulldown',
        name: 'Neutral-Grip Lat Pulldown',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_smith_machine_row',
        name: 'Smith Machine Row',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_pendlay_deficit_row',
        name: 'Pendlay Deficit Row',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_chest_supported_tbar_row',
        name: 'Chest-Supported T-Bar Row',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_chest_supported_machine_row',
        name: 'Chest-Supported Machine Row',
        primaryMuscle: MuscleGroup.back,
        secondaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_cable_paused_shrug_in',
        name: 'Cable Paused Shrug-In',
        primaryMuscle: MuscleGroup.back,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_machine_shrug',
        name: 'Machine Shrug',
        primaryMuscle: MuscleGroup.back,
        equipment: Equipment.machine,
      ),
      // Shoulders
      const Exercise(
        id: 'ex_high_cable_cuffed_lateral_raise',
        name: 'High-Cable Cuffed Lateral Raise',
        primaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_high_cable_lateral_raise',
        name: 'High-Cable Lateral Raise',
        primaryMuscle: MuscleGroup.shoulders,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_one_arm_cable_rear_delt_flye',
        name: '1-Arm 45° Cable Rear Delt Flye',
        primaryMuscle: MuscleGroup.shoulders,
        secondaryMuscle: MuscleGroup.back,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_cable_shoulder_press',
        name: 'Cable Shoulder Press',
        primaryMuscle: MuscleGroup.shoulders,
        secondaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_machine_shoulder_press',
        name: 'Machine Shoulder Press',
        primaryMuscle: MuscleGroup.shoulders,
        secondaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.machine,
      ),
      // Triceps
      const Exercise(
        id: 'ex_overhead_cable_triceps_ext_rope',
        name: 'Overhead Cable Triceps Extension (Rope)',
        primaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_overhead_cable_triceps_ext_bar',
        name: 'Overhead Cable Triceps Extension (Bar)',
        primaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_db_triceps_kickback',
        name: 'DB Triceps Kickback',
        primaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_cable_triceps_kickback',
        name: 'Cable Triceps Kickback',
        primaryMuscle: MuscleGroup.triceps,
        equipment: Equipment.cable,
      ),
      // Biceps
      const Exercise(
        id: 'ex_seated_super_bayesian_cable_curl',
        name: 'Seated Super-Bayesian High Cable Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_bayesian_cable_curl',
        name: 'Bayesian Cable Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_ez_bar_curl',
        name: 'EZ-Bar Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_ez_bar_cable_curl',
        name: 'EZ-Bar Cable Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_ez_bar_preacher_curl',
        name: 'EZ-Bar Preacher Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.barbell,
      ),
      const Exercise(
        id: 'ex_machine_preacher_curl',
        name: 'Machine Preacher Curl',
        primaryMuscle: MuscleGroup.biceps,
        equipment: Equipment.machine,
      ),
      // Legs
      const Exercise(
        id: 'ex_seated_leg_curl',
        name: 'Seated Leg Curl',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_lying_leg_curl',
        name: 'Lying Leg Curl',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_smith_machine_squat',
        name: 'Smith Machine Squat',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_db_rdl',
        name: 'DB RDL',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_reverse_nordic',
        name: 'Reverse Nordic',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_smith_machine_static_lunge',
        name: 'Smith Machine Static Lunge',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_db_step_up',
        name: 'DB Step-Up',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.dumbbell,
      ),
      const Exercise(
        id: 'ex_walking_lunge',
        name: 'Walking Lunge',
        primaryMuscle: MuscleGroup.legs,
        secondaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_seated_calf_raise',
        name: 'Seated Calf Raise',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.machine,
      ),
      const Exercise(
        id: 'ex_standing_calf_raise',
        name: 'Standing Calf Raise',
        primaryMuscle: MuscleGroup.legs,
        equipment: Equipment.machine,
      ),
      // Glutes
      const Exercise(
        id: 'ex_cable_hip_abduction',
        name: 'Cable Hip Abduction',
        primaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.cable,
      ),
      const Exercise(
        id: 'ex_machine_hip_abduction',
        name: 'Machine Hip Abduction',
        primaryMuscle: MuscleGroup.glutes,
        equipment: Equipment.machine,
      ),
      // Core
      const Exercise(
        id: 'ex_decline_weighted_crunch',
        name: 'Decline Weighted Crunch',
        primaryMuscle: MuscleGroup.core,
        equipment: Equipment.bodyweight,
      ),
      const Exercise(
        id: 'ex_lying_leg_raise',
        name: 'Lying Leg Raise',
        primaryMuscle: MuscleGroup.core,
        equipment: Equipment.bodyweight,
      ),
    ];

    // Per-exercise alternatives (Nippard 12-week program). Applied via copyWith
    // so the substitutes live as normal library exercises and each base lift
    // points at them by id. Dual-Handle Lat Pulldown unions the Upper-day and
    // Pull-day alternatives since alternatives are a library-level property.
    const altMap = <String, List<String>>{
      'ex_incline_machine_press_45': [
        'ex_incline_db_press_45',
        'ex_incline_barbell_press_45',
      ],
      'ex_bottom_half_db_flye': ['ex_pec_deck', 'ex_cable_crossover_ladder'],
      'ex_dual_handle_lat_pulldown': [
        'ex_wide_grip_lat_pulldown',
        'ex_wide_grip_pullup',
        'ex_neutral_grip_pullup',
        'ex_neutral_grip_lat_pulldown',
      ],
      'ex_lean_in_db_lateral_raise': [
        'ex_high_cable_cuffed_lateral_raise',
        'ex_high_cable_lateral_raise',
      ],
      'ex_single_arm_db_row': [
        'ex_smith_machine_row',
        'ex_pendlay_deficit_row',
      ],
      'ex_db_skull_crusher': [
        'ex_overhead_cable_triceps_ext_rope',
        'ex_overhead_cable_triceps_ext_bar',
      ],
      'ex_incline_db_stretch_curl': [
        'ex_seated_super_bayesian_cable_curl',
        'ex_bayesian_cable_curl',
      ],
      'ex_nordic_ham_curl': ['ex_seated_leg_curl', 'ex_lying_leg_curl'],
      'ex_high_bar_back_squat': [
        'ex_bulgarian_split',
        'ex_smith_machine_squat',
      ],
      'ex_snatch_grip_rdl': ['ex_db_rdl', 'ex_romanian_dl'],
      'ex_sissy_squat': ['ex_reverse_nordic', 'ex_leg_extension'],
      'ex_leg_press_calf_press': [
        'ex_seated_calf_raise',
        'ex_standing_calf_raise',
      ],
      'ex_machine_crunch': ['ex_decline_weighted_crunch', 'ex_cable_crunch'],
      'ex_incline_chest_supported_db_row': [
        'ex_chest_supported_tbar_row',
        'ex_chest_supported_machine_row',
      ],
      'ex_reverse_pec_deck': [
        'ex_face_pull',
        'ex_one_arm_cable_rear_delt_flye',
      ],
      'ex_db_shrug': ['ex_cable_paused_shrug_in', 'ex_machine_shrug'],
      'ex_db_curl': ['ex_ez_bar_curl', 'ex_ez_bar_cable_curl'],
      'ex_db_preacher_curl': [
        'ex_ez_bar_preacher_curl',
        'ex_machine_preacher_curl',
      ],
      'ex_db_bench': ['ex_machine_chest_press', 'ex_bench_press'],
      'ex_db_shoulder_press': [
        'ex_cable_shoulder_press',
        'ex_machine_shoulder_press',
      ],
      'ex_low_to_high_cable_crossover': [
        'ex_bottom_half_seated_cable_flye',
        'ex_bottom_half_db_flye',
      ],
      'ex_bench_dip': ['ex_db_triceps_kickback', 'ex_cable_triceps_kickback'],
      'ex_modified_candlestick': ['ex_hanging_leg_raise', 'ex_lying_leg_raise'],
      'ex_db_walking_lunge': ['ex_smith_machine_static_lunge', 'ex_leg_press'],
      'ex_goblet_squat': ['ex_db_step_up', 'ex_walking_lunge'],
      'ex_lateral_band_walk': [
        'ex_cable_hip_abduction',
        'ex_machine_hip_abduction',
      ],
    };

    for (final exercise in exercises) {
      final alts = altMap[exercise.id];
      final toSave = alts != null
          ? exercise.copyWith(alternativeIds: alts)
          : exercise;
      await _exercisesBox.put(toSave.id, jsonEncode(toSave.toMap()));
    }
  }
}
