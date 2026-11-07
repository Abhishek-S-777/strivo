import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';

/// A draggable row in the routine builder: the exercise name/equipment, a video
/// affordance, compact sets/reps steppers, and a remove action.
class RoutineExerciseItem extends StatelessWidget {
  const RoutineExerciseItem({
    required this.routineExercise,
    required this.onSetsChanged,
    required this.onRepsChanged,
    required this.onEditVideo,
    required this.onRemove,
    super.key,
  });
  final RoutineExercise routineExercise;
  final void Function(int) onSetsChanged;
  final void Function(int) onRepsChanged;
  final VoidCallback onEditVideo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Drag handle
          const Icon(
            LucideIcons.gripVertical,
            size: 18,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 12),

          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routineExercise.exercise.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        routineExercise.exercise.equipment.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _VideoChip(
                      hasVideo: routineExercise.exercise.hasVideo,
                      onTap: onEditVideo,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sets input
          _CompactInput(
            label: 'Sets',
            value: routineExercise.targetSets,
            onIncrement: () => onSetsChanged(routineExercise.targetSets + 1),
            onDecrement: () =>
                onSetsChanged((routineExercise.targetSets - 1).clamp(1, 20)),
          ),
          const SizedBox(width: 8),

          // Reps input
          _CompactInput(
            label: 'Reps',
            value: routineExercise.targetReps,
            onIncrement: () => onRepsChanged(routineExercise.targetReps + 1),
            onDecrement: () =>
                onRepsChanged((routineExercise.targetReps - 1).clamp(1, 100)),
          ),
          const SizedBox(width: 8),

          // Remove
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              LucideIcons.x,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable "video" affordance on a routine exercise row — the column where a
/// tutorial link is attached. Highlights when a link is set.
class _VideoChip extends StatelessWidget {
  const _VideoChip({required this.hasVideo, required this.onTap});
  final bool hasVideo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = hasVideo ? AppColors.primary : AppColors.textTertiary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.youtube, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            hasVideo ? 'Video' : 'Add video',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  const _CompactInput({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });
  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    LucideIcons.minus,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onIncrement,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    LucideIcons.plus,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
