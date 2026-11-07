import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';

/// A row in the exercise picker: the exercise name, its muscle/equipment, a
/// custom badge, an optional alternatives action, and an add affordance.
class ExerciseListItem extends StatelessWidget {
  const ExerciseListItem({
    required this.exercise,
    required this.onTap,
    this.onShowAlternatives,
    super.key,
  });
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback? onShowAlternatives;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.dumbbell,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exercise.primaryMuscle.displayName} • ${exercise.equipment.displayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (exercise.isCustom)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Custom',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                  ),
                ),
              ),
            if (onShowAlternatives != null)
              IconButton(
                tooltip: 'Alternatives',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  LucideIcons.repeat,
                  size: 16,
                  color: AppColors.primary,
                ),
                onPressed: onShowAlternatives,
              ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.plus,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
