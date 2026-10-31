import 'package:flutter/material.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/analytics/presentation/providers/insights_engine.dart';

/// A single smart-insight tile in the horizontal insights strip.
class InsightCard extends StatelessWidget {
  const InsightCard({required this.insight, super.key});
  final TrainingInsight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: insight.color.withAlpha(30)),
        gradient: LinearGradient(
          colors: [insight.color.withAlpha(8), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: insight.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(insight.icon, size: 16, color: insight.color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: insight.color.withAlpha(15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _insightTypeLabel(insight.type),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: insight.color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontSize: 13, height: 1.3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              insight.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _insightTypeLabel(InsightType type) {
    switch (type) {
      case InsightType.prAchieved:
        return 'PR';
      case InsightType.strengthIncreasing:
        return 'GAINS';
      case InsightType.strengthStagnant:
        return 'PLATEAU';
      case InsightType.strengthDecreasing:
        return 'DECLINE';
      case InsightType.volumeMilestone:
        return 'MILESTONE';
      case InsightType.consistencyStreak:
        return 'STREAK';
      case InsightType.muscleImbalance:
        return 'BALANCE';
      case InsightType.overtrainingRisk:
        return 'CAUTION';
      case InsightType.recoverySuggestion:
        return 'RECOVERY';
      case InsightType.newMilestone:
        return 'MILESTONE';
    }
  }
}
