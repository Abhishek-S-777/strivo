import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';

/// A single training day in the program builder: its name, its exercises with
/// their week-1 targets, and controls to rename, delete, and add exercises.
class ProgramDayCard extends StatelessWidget {
  const ProgramDayCard({
    required this.day,
    required this.ongoing,
    required this.onRename,
    required this.onDelete,
    required this.onAddExercise,
    required this.onEditTargets,
    required this.onRemoveExercise,
    super.key,
  });

  final ProgramDay day;
  final bool ongoing;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onAddExercise;
  final ValueChanged<int> onEditTargets;
  final ValueChanged<int> onRemoveExercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onRename,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            day.name,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.pencil,
                          size: 13,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'No exercises yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else
            ...day.exercises.asMap().entries.map((entry) {
              final pe = entry.value;
              final w1 = pe.weeklyTargets.isNotEmpty
                  ? pe.weeklyTargets.first.displayFull
                  : '—';
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  pe.exercise.name,
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  ongoing ? w1 : 'Wk1: $w1 · tap to set all weeks',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  color: AppColors.textTertiary,
                  onPressed: () => onRemoveExercise(entry.key),
                ),
                onTap: () => onEditTargets(entry.key),
              );
            }),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Exercise'),
            ),
          ),
        ],
      ),
    );
  }
}
