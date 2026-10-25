import 'package:strivo/features/analytics/domain/analytics_models.dart';
import 'package:strivo/features/analytics/domain/insights/insight_rule.dart';
import 'package:strivo/features/analytics/domain/insights/insight_rules.dart';

/// The rule set evaluated for every lifter, in no particular order (results are
/// sorted by priority afterwards).
const List<InsightRule> defaultInsightRules = [
  PersonalRecordRule(),
  StrengthTrendRule(),
  VolumeMilestoneRule(),
  ConsistencyStreakRule(),
  MuscleImbalanceRule(),
  OvertrainingRule(),
  RecoveryRule(),
];

/// Runs every rule over [context], then sorts by priority (then recency) and
/// caps the result at the ten most important insights.
List<Insight> generateInsights(
  InsightContext context, {
  List<InsightRule> rules = defaultInsightRules,
}) {
  if (context.completed.isEmpty) return const [];

  final insights =
      <Insight>[
        for (final rule in rules) ...rule.evaluate(context),
      ]..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        return byPriority != 0
            ? byPriority
            : b.timestamp.compareTo(a.timestamp);
      });

  return insights.take(10).toList();
}
