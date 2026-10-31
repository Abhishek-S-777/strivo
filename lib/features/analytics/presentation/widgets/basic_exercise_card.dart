import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// Fallback row in the "Exercise Progress" list for lifts without enough data
/// for a trend: current max, change vs. previous, session count, and best ever.
class BasicExerciseCard extends StatelessWidget {
  const BasicExerciseCard({
    required this.progress,
    required this.onTap,
    super.key,
  });
  final ExerciseProgressData progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weightDiff = progress.currentMax - progress.previousMax;

    return StrivoCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        Units.weightLabel(progress.currentMax),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (weightDiff != 0 && progress.previousMax > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: weightDiff > 0
                                ? AppColors.successMuted
                                : AppColors.errorMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${weightDiff > 0 ? '+' : ''}${Units.fromKg(weightDiff).toStringAsFixed(1)} ${Units.label}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: weightDiff > 0
                                  ? AppColors.increase
                                  : AppColors.decrease,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${progress.dataPoints.length} sessions • Best: ${Units.weightLabel(progress.allTimeMax)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
