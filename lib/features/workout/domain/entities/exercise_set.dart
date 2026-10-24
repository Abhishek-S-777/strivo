import 'package:flutter/foundation.dart';
import 'package:strivo/core/utils/id_generator.dart';

/// Represents a single set within an exercise
@immutable
class ExerciseSet {
  const ExerciseSet({
    required this.id,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.rpe,
    this.isCompleted = false,
    this.isWarmup = false,
    this.isPR = false,
  });

  factory ExerciseSet.empty(int setNumber) {
    return ExerciseSet(
      id: IdGenerator.generate(),
      setNumber: setNumber,
      weight: 0,
      reps: 0,
    );
  }

  factory ExerciseSet.fromPrevious(ExerciseSet previous, int setNumber) {
    return ExerciseSet(
      id: IdGenerator.generate(),
      setNumber: setNumber,
      weight: previous.weight,
      reps: previous.reps,
      rpe: previous.rpe,
    );
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      id: map['id'] as String,
      setNumber: (map['setNumber'] as num).toInt(),
      weight: (map['weight'] as num).toDouble(),
      reps: (map['reps'] as num).toInt(),
      rpe: (map['rpe'] as num?)?.toDouble(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      isWarmup: map['isWarmup'] as bool? ?? false,
      isPR: map['isPR'] as bool? ?? false,
    );
  }
  final String id;
  final int setNumber;
  final double weight;
  final int reps;
  final double? rpe;
  final bool isCompleted;
  final bool isWarmup;
  final bool isPR;

  double get volume => weight * reps;

  ExerciseSet copyWith({
    String? id,
    int? setNumber,
    double? weight,
    int? reps,
    double? rpe,
    bool? isCompleted,
    bool? isWarmup,
    bool? isPR,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      isCompleted: isCompleted ?? this.isCompleted,
      isWarmup: isWarmup ?? this.isWarmup,
      isPR: isPR ?? this.isPR,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'isCompleted': isCompleted,
      'isWarmup': isWarmup,
      'isPR': isPR,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
