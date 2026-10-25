import 'package:strivo/features/analytics/domain/analytics_models.dart';
import 'package:strivo/features/analytics/domain/weight_formatter.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';

/// Inputs available to every [InsightRule].
class InsightContext {
  const InsightContext({
    required this.completed,
    required this.trends,
    required this.streak,
    required this.muscleVolume,
    required this.now,
    required this.formatter,
  });

  /// Completed sessions, most recent first.
  final List<WorkoutSession> completed;

  /// Precomputed per-exercise trends.
  final List<ExerciseTrend> trends;

  /// Current training-consistency streak.
  final TrainingStreak streak;

  /// This week's volume per muscle group.
  final Map<MuscleGroup, double> muscleVolume;

  /// The reference "now" (injected so rules are deterministic in tests).
  final DateTime now;

  /// Formats weights for the user's unit when building copy.
  final WeightFormatter formatter;
}

/// A single coaching heuristic. Each rule inspects the [InsightContext] and
/// returns zero or more [Insight]s. Rules are pure and independently testable.
///
/// This is deliberately a named interface with many implementations wired into
/// a registry, not a function typedef.
// ignore: one_member_abstracts
abstract interface class InsightRule {
  List<Insight> evaluate(InsightContext context);
}
