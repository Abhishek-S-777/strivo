import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/domain/analytics_models.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// A row in the "Exercise Progress" list showing a lift's current working
/// weight, estimated 1RM, recent change, and a progressing/stagnant/regressing
/// status badge.
class ExerciseTrendCard extends StatelessWidget {
  const ExerciseTrendCard({
    required this.trend,
    required this.onTap,
    super.key,
  });
  final ExerciseTrend trend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StrivoCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Trend indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_statusIcon, size: 16, color: _statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trend.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        Units.weightLabel(trend.currentWeight),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (trend.weightChange.abs() > 0 &&
                          trend.sessionCount > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: trend.weightChange > 0
                                ? AppColors.successMuted
                                : trend.weightChange < 0
                                ? AppColors.errorMuted
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${trend.weightChange > 0 ? '+' : ''}${Units.fromKg(trend.weightChange).toStringAsFixed(1)} ${Units.label}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: trend.weightChange > 0
                                  ? AppColors.increase
                                  : trend.weightChange < 0
                                  ? AppColors.decrease
                                  : AppColors.stagnant,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        'Est. 1RM: ${Units.weightLabel(trend.estimated1RM)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trend.sessionCount} sessions',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (trend.status) {
      case TrendStatus.progressing:
        return AppColors.success;
      case TrendStatus.stagnant:
        return AppColors.stagnant;
      case TrendStatus.regressing:
        return AppColors.error;
    }
  }

  IconData get _statusIcon {
    switch (trend.status) {
      case TrendStatus.progressing:
        return LucideIcons.trendingUp;
      case TrendStatus.stagnant:
        return LucideIcons.minus;
      case TrendStatus.regressing:
        return LucideIcons.trendingDown;
    }
  }

  String get _statusLabel {
    switch (trend.status) {
      case TrendStatus.progressing:
        return '↑ GAINS';
      case TrendStatus.stagnant:
        return '— PLATEAU';
      case TrendStatus.regressing:
        return '↓ DECLINE';
    }
  }
}
