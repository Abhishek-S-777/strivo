import 'package:flutter/foundation.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';

/// Prescribed target for one exercise on one week: sets × reps (range) @ RPE.
/// Weight is intentionally NOT prescribed — the lifter works to the target and
/// the app pre-fills load from their history so they progress week to week.
@immutable
class SetTarget {
  const SetTarget({
    required this.sets,
    required this.repsMin,
    this.repsMax,
    this.rpe,
  });

  factory SetTarget.fromMap(Map<String, dynamic> map) => SetTarget(
    sets: map['sets'] as int? ?? 3,
    repsMin: map['repsMin'] as int? ?? 8,
    repsMax: map['repsMax'] as int?,
    rpe: (map['rpe'] as num?)?.toDouble(),
  );
  final int sets;
  final int repsMin;
  final int? repsMax; // null or == repsMin → single number
  final double? rpe;

  /// "3 × 8" or "3 × 8-10"
  String get display {
    final reps = (repsMax == null || repsMax == repsMin)
        ? '$repsMin'
        : '$repsMin-$repsMax';
    return '$sets × $reps';
  }

  /// "3 × 8-10 @8" (RPE appended when present)
  String get displayFull => rpe == null
      ? display
      : '$display @${rpe! % 1 == 0 ? rpe!.toStringAsFixed(0) : rpe}';

  SetTarget copyWith({int? sets, int? repsMin, int? repsMax, double? rpe}) =>
      SetTarget(
        sets: sets ?? this.sets,
        repsMin: repsMin ?? this.repsMin,
        repsMax: repsMax ?? this.repsMax,
        rpe: rpe ?? this.rpe,
      );

  Map<String, dynamic> toMap() => {
    'sets': sets,
    'repsMin': repsMin,
    'repsMax': repsMax,
    'rpe': rpe,
  };
}

/// An exercise inside a program day, with one [SetTarget] per program week.
@immutable
class ProgramExercise {
  const ProgramExercise({
    required this.id,
    required this.exercise,
    required this.weeklyTargets,
  });

  factory ProgramExercise.fromMap(Map<String, dynamic> map) => ProgramExercise(
    id: map['id'] as String,
    exercise: Exercise.fromMap(map['exercise'] as Map<String, dynamic>),
    weeklyTargets:
        (map['weeklyTargets'] as List?)
            ?.map((t) => SetTarget.fromMap(t as Map<String, dynamic>))
            .toList() ??
        const [],
  );
  final String id;
  final Exercise exercise;

  /// One target per week; index 0 = week 1. Length tracks the program duration.
  final List<SetTarget> weeklyTargets;

  /// Target for a 1-based [week], clamped to the available range.
  SetTarget targetForWeek(int week) {
    if (weeklyTargets.isEmpty) {
      return const SetTarget(sets: 3, repsMin: 8);
    }
    final i = (week - 1).clamp(0, weeklyTargets.length - 1);
    return weeklyTargets[i];
  }

  ProgramExercise copyWith({
    String? id,
    Exercise? exercise,
    List<SetTarget>? weeklyTargets,
  }) => ProgramExercise(
    id: id ?? this.id,
    exercise: exercise ?? this.exercise,
    weeklyTargets: weeklyTargets ?? this.weeklyTargets,
  );

  /// Resize the weekly targets to [weeks], repeating the last target when
  /// growing and truncating when shrinking.
  ProgramExercise resizedTo(int weeks) {
    if (weeklyTargets.length == weeks) return this;
    final base = weeklyTargets.isNotEmpty
        ? weeklyTargets.last
        : const SetTarget(sets: 3, repsMin: 8);
    final next = List<SetTarget>.generate(
      weeks,
      (i) => i < weeklyTargets.length ? weeklyTargets[i] : base,
    );
    return copyWith(weeklyTargets: next);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'exercise': exercise.toMap(),
    'weeklyTargets': weeklyTargets.map((t) => t.toMap()).toList(),
  };
}

/// One training day in a program's weekly cycle (e.g. "Upper A", "Push").
@immutable
class ProgramDay {
  const ProgramDay({
    required this.id,
    required this.name,
    required this.exercises,
  });

  factory ProgramDay.fromMap(Map<String, dynamic> map) => ProgramDay(
    id: map['id'] as String,
    name: map['name'] as String,
    exercises:
        (map['exercises'] as List?)
            ?.map((e) => ProgramExercise.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
  final String id;
  final String name;
  final List<ProgramExercise> exercises;

  ProgramDay copyWith({
    String? id,
    String? name,
    List<ProgramExercise>? exercises,
  }) => ProgramDay(
    id: id ?? this.id,
    name: name ?? this.name,
    exercises: exercises ?? this.exercises,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'exercises': exercises.map((e) => e.toMap()).toList(),
  };
}

/// A structured training plan: a repeating weekly cycle of [days] run for
/// [durationWeeks] weeks (or `0` = ongoing rotation like PPL). A position
/// pointer ([currentWeek], [currentDayIndex]) tracks the next workout and
/// advances when a session is completed.
@immutable
class Program {
  const Program({
    required this.id,
    required this.name,
    required this.durationWeeks,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.currentWeek = 1,
    this.currentDayIndex = 0,
    this.isComplete = false,
    this.timesCompleted = 0,
  });

  factory Program.create({
    required String name,
    String? description,
    int durationWeeks = 12,
  }) {
    final now = DateTime.now();
    return Program(
      id: IdGenerator.generate(),
      name: name,
      description: description,
      durationWeeks: durationWeeks,
      days: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Program.fromMap(Map<String, dynamic> map) => Program(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    durationWeeks: map['durationWeeks'] as int? ?? 12,
    days:
        (map['days'] as List?)
            ?.map((d) => ProgramDay.fromMap(d as Map<String, dynamic>))
            .toList() ??
        const [],
    currentWeek: map['currentWeek'] as int? ?? 1,
    currentDayIndex: map['currentDayIndex'] as int? ?? 0,
    isComplete: map['isComplete'] as bool? ?? false,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    timesCompleted: map['timesCompleted'] as int? ?? 0,
  );
  final String id;
  final String name;
  final String? description;
  final int durationWeeks; // 0 = ongoing/cyclic
  final List<ProgramDay> days;
  final int currentWeek; // 1-based
  final int currentDayIndex; // 0-based into days
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int timesCompleted;

  bool get isOngoing => durationWeeks <= 0;
  int get dayCount => days.length;

  /// The day the pointer is currently on (the "next" workout), or null.
  ProgramDay? get currentDay {
    if (days.isEmpty) return null;
    final i = currentDayIndex.clamp(0, days.length - 1);
    return days[i];
  }

  /// A short label for the current position, e.g. "Week 3 · Day 1".
  String get positionLabel {
    if (isOngoing) return 'Up next';
    return 'Week $currentWeek of $durationWeeks';
  }

  /// Total sessions across the whole plan (finite programs only).
  int get totalSessions => isOngoing ? 0 : durationWeeks * days.length;

  /// 0..1 progress through a finite program.
  double get progress {
    if (isOngoing || totalSessions == 0) return 0;
    final done = (currentWeek - 1) * days.length + currentDayIndex;
    return (done / totalSessions).clamp(0.0, 1.0);
  }

  /// Advance the pointer after completing the current day. Wraps to the next
  /// week; finite programs flip [isComplete] once past the final week.
  Program advanced() {
    if (days.isEmpty) return this;
    var week = currentWeek;
    var day = currentDayIndex + 1;
    var complete = isComplete;
    var completedCount = timesCompleted;

    if (day >= days.length) {
      day = 0;
      week += 1;
      if (!isOngoing && week > durationWeeks) {
        // Finished the plan.
        complete = true;
        completedCount += 1;
        week = 1; // ready to run again if restarted
      }
    }
    return copyWith(
      currentWeek: week,
      currentDayIndex: day,
      isComplete: complete,
      timesCompleted: completedCount,
      updatedAt: DateTime.now(),
    );
  }

  /// Reset the pointer to the very start.
  Program restarted() => copyWith(
    currentWeek: 1,
    currentDayIndex: 0,
    isComplete: false,
    updatedAt: DateTime.now(),
  );

  Program copyWith({
    String? id,
    String? name,
    String? description,
    int? durationWeeks,
    List<ProgramDay>? days,
    int? currentWeek,
    int? currentDayIndex,
    bool? isComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? timesCompleted,
  }) => Program(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    durationWeeks: durationWeeks ?? this.durationWeeks,
    days: days ?? this.days,
    currentWeek: currentWeek ?? this.currentWeek,
    currentDayIndex: currentDayIndex ?? this.currentDayIndex,
    isComplete: isComplete ?? this.isComplete,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    timesCompleted: timesCompleted ?? this.timesCompleted,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'durationWeeks': durationWeeks,
    'days': days.map((d) => d.toMap()).toList(),
    'currentWeek': currentWeek,
    'currentDayIndex': currentDayIndex,
    'isComplete': isComplete,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'timesCompleted': timesCompleted,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Program && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
