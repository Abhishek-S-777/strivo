import 'package:flutter/foundation.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';

/// A routine exercise template (what exercises are in a routine)
@immutable
class RoutineExercise {
  const RoutineExercise({
    required this.id,
    required this.exercise,
    required this.targetSets,
    required this.targetReps,
    required this.order,
    this.restSeconds,
    this.notes,
  });

  factory RoutineExercise.fromMap(Map<String, dynamic> map) {
    return RoutineExercise(
      id: map['id'] as String,
      exercise: Exercise.fromMap(map['exercise'] as Map<String, dynamic>),
      targetSets: (map['targetSets'] as num).toInt(),
      targetReps: (map['targetReps'] as num).toInt(),
      order: (map['order'] as num).toInt(),
      restSeconds: (map['restSeconds'] as num?)?.toInt(),
      notes: map['notes'] as String?,
    );
  }
  final String id;
  final Exercise exercise;
  final int targetSets;
  final int targetReps;
  final int order;
  final int? restSeconds;
  final String? notes;

  RoutineExercise copyWith({
    String? id,
    Exercise? exercise,
    int? targetSets,
    int? targetReps,
    int? order,
    int? restSeconds,
    String? notes,
  }) {
    return RoutineExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      order: order ?? this.order,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise': exercise.toMap(),
      'targetSets': targetSets,
      'targetReps': targetReps,
      'order': order,
      'restSeconds': restSeconds,
      'notes': notes,
    };
  }
}

/// A workout routine / template
@immutable
class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.color,
    this.timesUsed = 0,
  });

  factory Routine.create({
    required String name,
    String? description,
    String? color,
  }) {
    final now = DateTime.now();
    return Routine(
      id: IdGenerator.generate(),
      name: name,
      description: description,
      exercises: const [],
      color: color,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      exercises:
          (map['exercises'] as List?)
              ?.map((e) => RoutineExercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      timesUsed: map['timesUsed'] as int? ?? 0,
    );
  }
  final String id;
  final String name;
  final String? description;
  final List<RoutineExercise> exercises;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int timesUsed;

  int get exerciseCount => exercises.length;

  int get totalTargetSets => exercises.fold(0, (sum, e) => sum + e.targetSets);

  Routine copyWith({
    String? id,
    String? name,
    String? description,
    List<RoutineExercise>? exercises,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? timesUsed,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timesUsed: timesUsed ?? this.timesUsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'timesUsed': timesUsed,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Routine && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
