import 'package:flutter/material.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// Per-exercise breakdown on the workout summary screen: the name, an optional
/// volume delta versus last time, and each completed set with PR and RPE tags.
class ExerciseBreakdownCard extends StatelessWidget {
  const ExerciseBreakdownCard({
    required this.exercise,
    this.previousExercise,
    super.key,
  });
  final WorkoutExercise exercise;
  final WorkoutExercise? previousExercise;

  /// RPE reads cleaner as a whole number when it is one ("RPE 8", not "8.0").
  String _rpeLabel(double rpe) =>
      rpe % 1 == 0 ? rpe.toStringAsFixed(0) : rpe.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final prev = previousExercise;
    final volumeDiff = prev != null
        ? exercise.totalVolume - prev.totalVolume
        : null;
    final completedSets = exercise.sets.where((s) => s.isCompleted).toList();

    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exercise.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (volumeDiff != null && volumeDiff != 0)
                  Text(
                    '${volumeDiff > 0 ? '+' : ''}${Units.fromKg(volumeDiff).toStringAsFixed(0)} ${Units.label} vol',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: volumeDiff > 0
                          ? AppColors.increase
                          : AppColors.decrease,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...completedSets.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${s.setNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${Units.weightLabel(s.weight)} × ${s.reps} reps',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.isPR) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pr.withAlpha(20),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'PR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pr,
                          ),
                        ),
                      ),
                    ],
                    if (s.rpe != null) ...[
                      const Spacer(),
                      Text(
                        'RPE ${_rpeLabel(s.rpe!)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
