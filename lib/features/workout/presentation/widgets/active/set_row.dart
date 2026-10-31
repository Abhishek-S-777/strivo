import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/domain/entities/exercise_set.dart';
import 'package:strivo/features/workout/presentation/widgets/active/inline_number_input.dart';

/// One logged set: its number/PR badge, the previous session's figures, fast
/// weight/reps inputs, and a complete toggle. Swipe left to delete.
class SetRow extends StatelessWidget {
  const SetRow({
    required this.set,
    required this.onToggleComplete,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRemove,
    this.previousSet,
    super.key,
  });
  final ExerciseSet set;
  final ExerciseSet? previousSet;
  final VoidCallback onToggleComplete;
  final void Function(double) onWeightChanged;
  final void Function(int) onRepsChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${set.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withAlpha(30),
        child: const Icon(LucideIcons.trash2, color: AppColors.error, size: 18),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: set.isCompleted
            ? AppColors.success.withAlpha(8)
            : Colors.transparent,
        child: Row(
          children: [
            // Set number
            SizedBox(
              width: 36,
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: set.isPR
                        ? AppColors.pr.withAlpha(30)
                        : set.isWarmup
                        ? AppColors.warning.withAlpha(20)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: set.isPR
                        ? const Icon(
                            LucideIcons.trophy,
                            size: 12,
                            color: AppColors.pr,
                          )
                        : Text(
                            '${set.setNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: set.isWarmup
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Previous set data
            Expanded(
              child: Center(
                child: Text(
                  previousSet != null
                      ? '${Units.weight(previousSet!.weight)} × ${previousSet!.reps}'
                      : '—',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Weight input (shown/edited in the user's unit; stored in kg)
            InlineNumberInput(
              value: Units.fromKg(set.weight),
              width: 72,
              onIncrement: () => onWeightChanged(set.weight + Units.stepKg),
              onDecrement: () => onWeightChanged(
                (set.weight - Units.stepKg).clamp(0, double.infinity),
              ),
              onDirectInput: (v) => onWeightChanged(Units.toKg(v)),
              isDecimal: true,
              unitLabel: Units.label,
              comparison: previousSet != null
                  ? Units.fromKg(set.weight) - Units.fromKg(previousSet!.weight)
                  : null,
            ),
            const SizedBox(width: 8),

            // Reps input
            InlineNumberInput(
              value: set.reps.toDouble(),
              width: 56,
              onIncrement: () => onRepsChanged(set.reps + 1),
              onDecrement: () => onRepsChanged((set.reps - 1).clamp(0, 999)),
              onDirectInput: (v) => onRepsChanged(v.toInt()),
            ),
            const SizedBox(width: 8),

            // Complete button
            GestureDetector(
              onTap: onToggleComplete,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: set.isCompleted
                      ? AppColors.success
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: set.isCompleted
                        ? AppColors.success
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  LucideIcons.check,
                  size: 18,
                  color: set.isCompleted
                      ? AppColors.onAccent
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
