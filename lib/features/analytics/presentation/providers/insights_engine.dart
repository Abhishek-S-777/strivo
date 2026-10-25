import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/domain/analytics_calculations.dart';
import 'package:strivo/features/analytics/domain/analytics_models.dart';
import 'package:strivo/features/analytics/domain/insights/insight_generator.dart';
import 'package:strivo/features/analytics/domain/insights/insight_rule.dart';
import 'package:strivo/features/analytics/domain/weight_formatter.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';

// Re-export the domain models so existing imports of this file keep resolving
// ExerciseTrend / TrendStatus / WeeklyLoadSummary / TrainingStreak / InsightType.
export 'package:strivo/features/analytics/domain/analytics_models.dart';

/// Presentation view of an [Insight] with the icon and colour used to render it.
@immutable
class TrainingInsight {
  const TrainingInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.exerciseId,
  });
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final int priority;
  final IconData icon;
  final Color color;
  final String? exerciseId;
  final DateTime timestamp;
}

/// [WeightFormatter] over the app's [Units] mirror, injected into insight rules.
class _UnitsWeightFormatter implements WeightFormatter {
  const _UnitsWeightFormatter();

  @override
  String get unitLabel => Units.label;

  @override
  double fromKg(double kg) => Units.fromKg(kg);

  @override
  String weight(double kg) => Units.weight(kg);

  @override
  String weightLabel(double kg) => Units.weightLabel(kg);
}

// ── Analytics providers (thin wrappers over the domain calculations) ──

final trainingStreakProvider = Provider<TrainingStreak>((ref) {
  return calculateStreak(ref.watch(workoutSessionsProvider), DateTime.now());
});

final muscleGroupVolumeProvider = Provider<Map<MuscleGroup, double>>((ref) {
  return calculateMuscleGroupVolume(
    ref.watch(workoutSessionsProvider),
    DateTime.now(),
  );
});

final weeklyLoadHistoryProvider = Provider<List<WeeklyLoadSummary>>((ref) {
  return calculateWeeklyLoadHistory(
    ref.watch(workoutSessionsProvider),
    DateTime.now(),
  );
});

final exerciseTrendsProvider = Provider<List<ExerciseTrend>>((ref) {
  return calculateExerciseTrends(
    ref.watch(workoutSessionsProvider),
    DateTime.now(),
  );
});

/// Smart Insights: runs the domain rule engine and maps each result to a
/// [TrainingInsight] for rendering.
final insightsProvider = Provider<List<TrainingInsight>>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  final trends = ref.watch(exerciseTrendsProvider);
  final streak = ref.watch(trainingStreakProvider);
  final muscleVolume = ref.watch(muscleGroupVolumeProvider);
  ref.watch(weightUnitProvider); // regenerate copy on kg/lbs change

  final completed = sessions.where((s) => s.isCompleted).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  final insights = generateInsights(
    InsightContext(
      completed: completed,
      trends: trends,
      streak: streak,
      muscleVolume: muscleVolume,
      now: DateTime.now(),
      formatter: const _UnitsWeightFormatter(),
    ),
  );

  return insights.map(_toTrainingInsight).toList();
});

TrainingInsight _toTrainingInsight(Insight insight) {
  return TrainingInsight(
    id: insight.id,
    type: insight.type,
    title: insight.title,
    description: insight.description,
    priority: insight.priority,
    icon: _iconFor(insight.type),
    color: _colorFor(insight.type),
    exerciseId: insight.exerciseId,
    timestamp: insight.timestamp,
  );
}

IconData _iconFor(InsightType type) {
  switch (type) {
    case InsightType.prAchieved:
      return LucideIcons.trophy;
    case InsightType.strengthIncreasing:
      return LucideIcons.trendingUp;
    case InsightType.strengthStagnant:
      return LucideIcons.minus;
    case InsightType.strengthDecreasing:
      return LucideIcons.trendingDown;
    case InsightType.volumeMilestone:
    case InsightType.newMilestone:
      return LucideIcons.award;
    case InsightType.consistencyStreak:
      return LucideIcons.flame;
    case InsightType.muscleImbalance:
      return LucideIcons.scale;
    case InsightType.overtrainingRisk:
      return LucideIcons.alertTriangle;
    case InsightType.recoverySuggestion:
      return LucideIcons.heartPulse;
  }
}

Color _colorFor(InsightType type) {
  switch (type) {
    case InsightType.prAchieved:
      return AppColors.pr;
    case InsightType.strengthIncreasing:
      return AppColors.success;
    case InsightType.strengthStagnant:
      return AppColors.stagnant;
    case InsightType.strengthDecreasing:
    case InsightType.overtrainingRisk:
      return AppColors.error;
    case InsightType.volumeMilestone:
    case InsightType.newMilestone:
      return AppColors.primary;
    case InsightType.consistencyStreak:
    case InsightType.muscleImbalance:
      return AppColors.warning;
    case InsightType.recoverySuggestion:
      return AppColors.info;
  }
}
