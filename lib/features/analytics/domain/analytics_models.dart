import 'package:strivo/features/workout/domain/entities/exercise.dart';

/// The kinds of insight the engine can surface.
enum InsightType {
  prAchieved,
  strengthIncreasing,
  strengthStagnant,
  strengthDecreasing,
  volumeMilestone,
  consistencyStreak,
  muscleImbalance,
  overtrainingRisk,
  recoverySuggestion,
  newMilestone,
}

/// Direction of a strength or volume trend.
enum TrendStatus { progressing, stagnant, regressing }

/// A single, presentation-agnostic coaching insight. Icon, colour and any
/// emoji are applied in the presentation layer; the copy here is plain text.
class Insight {
  const Insight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.timestamp,
    this.exerciseId,
  });

  final String id;
  final InsightType type;
  final String title;
  final String description;
  final int priority;
  final DateTime timestamp;
  final String? exerciseId;
}

/// Per-exercise strength/volume trend over the recent training window.
class ExerciseTrend {
  const ExerciseTrend({
    required this.exerciseId,
    required this.exerciseName,
    required this.status,
    required this.currentWeight,
    required this.weightChange,
    required this.weightChangePercent,
    required this.estimated1RM,
    required this.volumeTrend,
    required this.lastPerformed,
    required this.sessionCount,
  });

  final String exerciseId;
  final String exerciseName;
  final TrendStatus status;
  final double currentWeight;
  final double weightChange;
  final double weightChangePercent;
  final double estimated1RM;
  final TrendStatus volumeTrend;
  final DateTime lastPerformed;
  final int sessionCount;
}

/// Aggregated training load for one ISO week.
class WeeklyLoadSummary {
  const WeeklyLoadSummary({
    required this.weekStart,
    required this.totalVolume,
    required this.totalSets,
    required this.totalReps,
    required this.workoutCount,
    required this.avgSessionDuration,
    required this.muscleGroupDistribution,
    required this.topExerciseByVolume,
  });

  final DateTime weekStart;
  final double totalVolume;
  final int totalSets;
  final int totalReps;
  final int workoutCount;
  final Duration avgSessionDuration;
  final Map<MuscleGroup, double> muscleGroupDistribution;
  final String topExerciseByVolume;
}

/// Weekly training-consistency streak.
class TrainingStreak {
  const TrainingStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.isActive,
  });

  final int currentStreak;
  final int longestStreak;
  final bool isActive;
}
