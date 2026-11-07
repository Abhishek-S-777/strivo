import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';

/// Bottom sheet listing an exercise's alternatives — shown when the primary
/// machine/setup isn't available. Selecting one pops with that [Exercise].
class AlternativesSheet extends StatelessWidget {
  const AlternativesSheet({
    required this.base,
    required this.alternatives,
    super.key,
  });
  final Exercise base;
  final List<Exercise> alternatives;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alternatives', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 2),
            Text(
              "Swap in for ${base.name} if it isn't available.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            ...alternatives.map(
              (alt) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
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
                title: Text(alt.name, style: theme.textTheme.titleSmall),
                subtitle: Text(
                  '${alt.primaryMuscle.displayName} • ${alt.equipment.displayName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                trailing: const Icon(
                  LucideIcons.plus,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                onTap: () => Navigator.pop(context, alt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
