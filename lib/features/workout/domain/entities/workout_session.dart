import 'package:flutter/foundation.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';

/// A completed or in-progress workout session
@immutable
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.name,
    required this.exercises,
    required this.startTime,
    this.routineId,
    this.routineName,
    this.endTime,
    this.notes,
    this.isCompleted = false,
    this.programId,
    this.programWeek,
    this.programDayName,
  });

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as String,
      routineId: map['routineId'] as String?,
      routineName: map['routineName'] as String?,
      name: map['name'] as String,
      exercises: (map['exercises'] as List)
          .map((e) => WorkoutExercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      notes: map['notes'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      programId: map['programId'] as String?,
      programWeek: (map['programWeek'] as num?)?.toInt(),
      programDayName: map['programDayName'] as String?,
    );
  }
  final String id;
  final String? routineId;
  final String? routineName;
  final String name;
  final List<WorkoutExercise> exercises;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final bool isCompleted;
  // Program linkage (set when the session was started from a program day).
  final String? programId;
  final int? programWeek;
  final String? programDayName;

  /// Duration of the workout
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Formatted duration string
  String get durationFormatted {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Total volume across all exercises
  double get totalVolume {
    return exercises.fold(0, (sum, e) => sum + e.totalVolume);
  }

  /// Total completed sets
  int get totalCompletedSets {
    return exercises.fold(0, (sum, e) => sum + e.completedSets);
  }

  /// Total exercises performed
  int get totalExercises => exercises.length;

  /// Check if workout has any data
  bool get hasData {
    return exercises.any((e) => e.sets.any((s) => s.isCompleted));
  }

  /// Number of PRs in this session
  int get prCount {
    return exercises.fold(
      0,
      (sum, e) => sum + e.sets.where((s) => s.isPR).length,
    );
  }

  WorkoutSession copyWith({
    String? id,
    String? routineId,
    String? routineName,
    String? name,
    List<WorkoutExercise>? exercises,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    bool? isCompleted,
    String? programId,
    int? programWeek,
    String? programDayName,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      routineName: routineName ?? this.routineName,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      programId: programId ?? this.programId,
      programWeek: programWeek ?? this.programWeek,
      programDayName: programDayName ?? this.programDayName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'routineName': routineName,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notes': notes,
      'isCompleted': isCompleted,
      'programId': programId,
      'programWeek': programWeek,
      'programDayName': programDayName,
      'totalVolume': totalVolume,
      'totalSets': totalCompletedSets,
      'totalExercises': totalExercises,
      'duration': duration.inSeconds,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
