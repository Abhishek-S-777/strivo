import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';

/// Featured card on Home that suggests the next routine to run when there is no
/// active program.
class NextRoutineCard extends StatelessWidget {
  const NextRoutineCard({
    required this.routine,
    required this.hasActiveWorkout,
    required this.onStart,
    super.key,
  });
  final Routine routine;
  final bool hasActiveWorkout;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscles = routine.exercises
        .map((e) => e.exercise.primaryMuscle.displayName)
        .toSet()
        .take(3)
        .join(', ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 0.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2336), AppColors.surface],
          ),
        ),
        child: Stack(
          children: [
            // Watermark
            Positioned(
              right: -18,
              top: -18,
              child: Icon(
                LucideIcons.dumbbell,
                size: 130,
                color: AppColors.primary.withAlpha(15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    muscles.isEmpty
                        ? '${routine.exerciseCount} exercises • ${routine.totalTargetSets} sets'
                        : '$muscles • ${routine.totalTargetSets} sets',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onStart,
                      icon: Icon(
                        hasActiveWorkout
                            ? LucideIcons.arrowRight
                            : LucideIcons.play,
                        size: 18,
                      ),
                      label: Text(
                        hasActiveWorkout ? 'Resume Workout' : 'Start Workout',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
