import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';

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

    // Seed default exercises if first launch
    if (_exercisesBox.isEmpty) {
      await _seedDefaultExercises();
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
        .map((json) => WorkoutSession.fromMap(
            jsonDecode(json) as Map<String, dynamic>))
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

  static List<WorkoutSession> getSessionsInRange(
      DateTime start, DateTime end) {
    return getAllSessions()
        .where((s) =>
            s.startTime.isAfter(start) &&
            s.startTime.isBefore(end) &&
            s.isCompleted)
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
        .map((json) =>
            Routine.fromMap(jsonDecode(json) as Map<String, dynamic>))
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
        .map((json) =>
            Exercise.fromMap(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<Exercise> getExercisesByMuscle(MuscleGroup muscle) {
    return getAllExercises()
        .where((e) => e.primaryMuscle == muscle)
        .toList();
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
      String exerciseId, Map<String, dynamic> data) async {
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
        .map((json) =>
            Program.fromMap(jsonDecode(json) as Map<String, dynamic>))
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
  static Future<void> _seedDefaultExercises() async {
    final exercises = [
      // Chest
      const Exercise(id: 'ex_bench_press', name: 'Bench Press', primaryMuscle: MuscleGroup.chest, secondaryMuscle: MuscleGroup.triceps, equipment: Equipment.barbell),
      const Exercise(id: 'ex_incline_bench', name: 'Incline Bench Press', primaryMuscle: MuscleGroup.chest, secondaryMuscle: MuscleGroup.shoulders, equipment: Equipment.barbell),
      const Exercise(id: 'ex_db_bench', name: 'Dumbbell Bench Press', primaryMuscle: MuscleGroup.chest, secondaryMuscle: MuscleGroup.triceps, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_incline_db', name: 'Incline Dumbbell Press', primaryMuscle: MuscleGroup.chest, secondaryMuscle: MuscleGroup.shoulders, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_cable_fly', name: 'Cable Fly', primaryMuscle: MuscleGroup.chest, equipment: Equipment.cable),
      const Exercise(id: 'ex_chest_dip', name: 'Chest Dip', primaryMuscle: MuscleGroup.chest, secondaryMuscle: MuscleGroup.triceps, equipment: Equipment.bodyweight),
      const Exercise(id: 'ex_pec_deck', name: 'Pec Deck', primaryMuscle: MuscleGroup.chest, equipment: Equipment.machine),
      // Back
      const Exercise(id: 'ex_deadlift', name: 'Deadlift', primaryMuscle: MuscleGroup.back, secondaryMuscle: MuscleGroup.legs, equipment: Equipment.barbell),
      const Exercise(id: 'ex_barbell_row', name: 'Barbell Row', primaryMuscle: MuscleGroup.back, secondaryMuscle: MuscleGroup.biceps, equipment: Equipment.barbell),
      const Exercise(id: 'ex_pullup', name: 'Pull Up', primaryMuscle: MuscleGroup.back, secondaryMuscle: MuscleGroup.biceps, equipment: Equipment.bodyweight),
      const Exercise(id: 'ex_lat_pulldown', name: 'Lat Pulldown', primaryMuscle: MuscleGroup.back, secondaryMuscle: MuscleGroup.biceps, equipment: Equipment.cable),
      const Exercise(id: 'ex_cable_row', name: 'Seated Cable Row', primaryMuscle: MuscleGroup.back, equipment: Equipment.cable),
      const Exercise(id: 'ex_db_row', name: 'Dumbbell Row', primaryMuscle: MuscleGroup.back, secondaryMuscle: MuscleGroup.biceps, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_tbar_row', name: 'T-Bar Row', primaryMuscle: MuscleGroup.back, equipment: Equipment.barbell),
      const Exercise(id: 'ex_face_pull', name: 'Face Pull', primaryMuscle: MuscleGroup.back, secondaryMuscle: MuscleGroup.shoulders, equipment: Equipment.cable),
      // Shoulders
      const Exercise(id: 'ex_ohp', name: 'Overhead Press', primaryMuscle: MuscleGroup.shoulders, secondaryMuscle: MuscleGroup.triceps, equipment: Equipment.barbell),
      const Exercise(id: 'ex_db_shoulder_press', name: 'Dumbbell Shoulder Press', primaryMuscle: MuscleGroup.shoulders, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_lateral_raise', name: 'Lateral Raise', primaryMuscle: MuscleGroup.shoulders, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_front_raise', name: 'Front Raise', primaryMuscle: MuscleGroup.shoulders, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_rear_delt_fly', name: 'Rear Delt Fly', primaryMuscle: MuscleGroup.shoulders, secondaryMuscle: MuscleGroup.back, equipment: Equipment.dumbbell),
      // Biceps
      const Exercise(id: 'ex_barbell_curl', name: 'Barbell Curl', primaryMuscle: MuscleGroup.biceps, equipment: Equipment.barbell),
      const Exercise(id: 'ex_db_curl', name: 'Dumbbell Curl', primaryMuscle: MuscleGroup.biceps, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_hammer_curl', name: 'Hammer Curl', primaryMuscle: MuscleGroup.biceps, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_preacher_curl', name: 'Preacher Curl', primaryMuscle: MuscleGroup.biceps, equipment: Equipment.barbell),
      const Exercise(id: 'ex_cable_curl', name: 'Cable Curl', primaryMuscle: MuscleGroup.biceps, equipment: Equipment.cable),
      // Triceps
      const Exercise(id: 'ex_tricep_pushdown', name: 'Tricep Pushdown', primaryMuscle: MuscleGroup.triceps, equipment: Equipment.cable),
      const Exercise(id: 'ex_skull_crusher', name: 'Skull Crusher', primaryMuscle: MuscleGroup.triceps, equipment: Equipment.barbell),
      const Exercise(id: 'ex_overhead_extension', name: 'Overhead Tricep Extension', primaryMuscle: MuscleGroup.triceps, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_close_grip_bench', name: 'Close Grip Bench Press', primaryMuscle: MuscleGroup.triceps, secondaryMuscle: MuscleGroup.chest, equipment: Equipment.barbell),
      // Legs
      const Exercise(id: 'ex_squat', name: 'Squat', primaryMuscle: MuscleGroup.legs, secondaryMuscle: MuscleGroup.glutes, equipment: Equipment.barbell),
      const Exercise(id: 'ex_front_squat', name: 'Front Squat', primaryMuscle: MuscleGroup.legs, equipment: Equipment.barbell),
      const Exercise(id: 'ex_leg_press', name: 'Leg Press', primaryMuscle: MuscleGroup.legs, secondaryMuscle: MuscleGroup.glutes, equipment: Equipment.machine),
      const Exercise(id: 'ex_romanian_dl', name: 'Romanian Deadlift', primaryMuscle: MuscleGroup.legs, secondaryMuscle: MuscleGroup.glutes, equipment: Equipment.barbell),
      const Exercise(id: 'ex_leg_curl', name: 'Leg Curl', primaryMuscle: MuscleGroup.legs, equipment: Equipment.machine),
      const Exercise(id: 'ex_leg_extension', name: 'Leg Extension', primaryMuscle: MuscleGroup.legs, equipment: Equipment.machine),
      const Exercise(id: 'ex_calf_raise', name: 'Calf Raise', primaryMuscle: MuscleGroup.legs, equipment: Equipment.machine),
      const Exercise(id: 'ex_lunge', name: 'Lunge', primaryMuscle: MuscleGroup.legs, secondaryMuscle: MuscleGroup.glutes, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_bulgarian_split', name: 'Bulgarian Split Squat', primaryMuscle: MuscleGroup.legs, secondaryMuscle: MuscleGroup.glutes, equipment: Equipment.dumbbell),
      const Exercise(id: 'ex_hack_squat', name: 'Hack Squat', primaryMuscle: MuscleGroup.legs, equipment: Equipment.machine),
      // Glutes
      const Exercise(id: 'ex_hip_thrust', name: 'Hip Thrust', primaryMuscle: MuscleGroup.glutes, secondaryMuscle: MuscleGroup.legs, equipment: Equipment.barbell),
      const Exercise(id: 'ex_cable_kickback', name: 'Cable Kickback', primaryMuscle: MuscleGroup.glutes, equipment: Equipment.cable),
      // Core
      const Exercise(id: 'ex_plank', name: 'Plank', primaryMuscle: MuscleGroup.core, equipment: Equipment.bodyweight),
      const Exercise(id: 'ex_cable_crunch', name: 'Cable Crunch', primaryMuscle: MuscleGroup.core, equipment: Equipment.cable),
      const Exercise(id: 'ex_hanging_leg_raise', name: 'Hanging Leg Raise', primaryMuscle: MuscleGroup.core, equipment: Equipment.bodyweight),
      const Exercise(id: 'ex_ab_wheel', name: 'Ab Wheel Rollout', primaryMuscle: MuscleGroup.core, equipment: Equipment.other),
    ];

    for (final exercise in exercises) {
      await _exercisesBox.put(exercise.id, jsonEncode(exercise.toMap()));
    }
  }
}
