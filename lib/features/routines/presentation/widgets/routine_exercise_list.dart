import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/routines/presentation/widgets/routine_exercise_item.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';

/// The reorderable list of exercises in the routine builder, or a prompt to add
/// the first one when empty. All mutations are reported back via callbacks.
class RoutineExerciseList extends StatelessWidget {
  const RoutineExerciseList({
    required this.exercises,
    required this.onReorder,
    required this.onSetsChanged,
    required this.onRepsChanged,
    required this.onEditVideo,
    required this.onRemove,
    super.key,
  });

  final List<RoutineExercise> exercises;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index, int sets) onSetsChanged;
  final void Function(int index, int reps) onRepsChanged;
  final void Function(int index) onEditVideo;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              LucideIcons.listPlus,
              size: 32,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Add exercises to your routine',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      onReorder: onReorder,
      proxyDecorator: (child, index, animation) {
        return Material(color: Colors.transparent, child: child);
      },
      itemBuilder: (context, index) {
        final re = exercises[index];
        return RoutineExerciseItem(
          key: ValueKey(re.id),
          routineExercise: re,
          onSetsChanged: (sets) => onSetsChanged(index, sets),
          onRepsChanged: (reps) => onRepsChanged(index, reps),
          onEditVideo: () => onEditVideo(index),
          onRemove: () => onRemove(index),
        );
      },
    );
  }
}
