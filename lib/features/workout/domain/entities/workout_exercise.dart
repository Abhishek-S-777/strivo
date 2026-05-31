import 'package:flutter/foundation.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/exercise_set.dart';

/// An exercise instance within a workout session
@immutable
class WorkoutExercise {
  final String id;
  final Exercise exercise;
  final List<ExerciseSet> sets;
  final String? notes;
  final int order;
  final int? restSeconds;

  const WorkoutExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    this.notes,
    required this.order,
    this.restSeconds,
  });

  /// Total volume for this exercise (weight × reps for all completed sets)
  double get totalVolume {
    return sets
        .where((s) => s.isCompleted && !s.isWarmup)
        .fold(0.0, (sum, s) => sum + s.volume);
  }

  /// Number of completed working sets
  int get completedSets {
    return sets.where((s) => s.isCompleted && !s.isWarmup).length;
  }

  /// Max weight lifted in this exercise
  double get maxWeight {
    if (sets.isEmpty) return 0;
    return sets
        .where((s) => s.isCompleted)
        .fold(0.0, (max, s) => s.weight > max ? s.weight : max);
  }

  /// Best set (highest volume single set)
  ExerciseSet? get bestSet {
    final completed = sets.where((s) => s.isCompleted && !s.isWarmup).toList();
    if (completed.isEmpty) return null;
    completed.sort((a, b) => b.volume.compareTo(a.volume));
    return completed.first;
  }

  WorkoutExercise copyWith({
    String? id,
    Exercise? exercise,
    List<ExerciseSet>? sets,
    String? notes,
    int? order,
    int? restSeconds,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      order: order ?? this.order,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise': exercise.toMap(),
      'sets': sets.map((s) => s.toMap()).toList(),
      'notes': notes,
      'order': order,
      'restSeconds': restSeconds,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] as String,
      exercise: Exercise.fromMap(map['exercise'] as Map<String, dynamic>),
      sets: (map['sets'] as List)
          .map((s) => ExerciseSet.fromMap(s as Map<String, dynamic>))
          .toList(),
      notes: map['notes'] as String?,
      order: map['order'] as int,
      restSeconds: map['restSeconds'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExercise &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
