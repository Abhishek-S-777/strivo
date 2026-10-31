import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/domain/entities/exercise_set.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/features/workout/presentation/widgets/active/exercise_card_header.dart';
import 'package:strivo/features/workout/presentation/widgets/active/set_row.dart';

/// The core logging card for one exercise in an active workout: header with
/// video/swap/overflow actions, optional notes, last-session comparison, and
/// the set rows with an add-set control.
class ExerciseCard extends StatefulWidget {
  const ExerciseCard({
    required this.workoutExercise,
    required this.onSetCompleted,
    required this.onSetUpdated,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
    required this.onNotesChanged,
    required this.onWatchVideo,
    required this.onSwap,
    super.key,
    this.previousExercise,
  });
  final WorkoutExercise workoutExercise;
  final WorkoutExercise? previousExercise;
  final void Function(String setId) onSetCompleted;
  final void Function(String setId, ExerciseSet newSet) onSetUpdated;
  final VoidCallback onAddSet;
  final void Function(String setId) onRemoveSet;
  final VoidCallback onRemoveExercise;
  final void Function(String notes) onNotesChanged;
  final VoidCallback onWatchVideo;
  final VoidCallback onSwap;

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _showNotes = false;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.workoutExercise.notes ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.workoutExercise;
    final prev = widget.previousExercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExerciseCardHeader(
            exercise: exercise.exercise,
            onWatchVideo: widget.onWatchVideo,
            onSwap: widget.onSwap,
            onToggleNotes: () => setState(() => _showNotes = !_showNotes),
            onRemove: widget.onRemoveExercise,
          ),

          // ── Notes field ──
          if (_showNotes || (exercise.notes?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Add notes...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                controller: _notesController,
                onChanged: widget.onNotesChanged,
              ),
            ),

          // ── Previous session comparison ──
          if (prev != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.history,
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last: ${prev.sets.length} sets × ${Units.weightLabel(prev.maxWeight)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ── Set Header Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 36,
                  child: Text(
                    'SET',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'PREVIOUS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    Units.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 56,
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 36),
              ],
            ),
          ),

          // ── Set Rows ──
          ...exercise.sets.asMap().entries.map((entry) {
            final set = entry.value;
            final prevSet = prev != null && entry.key < prev.sets.length
                ? prev.sets[entry.key]
                : null;

            return SetRow(
              set: set,
              previousSet: prevSet,
              onToggleComplete: () => widget.onSetCompleted(set.id),
              onWeightChanged: (w) =>
                  widget.onSetUpdated(set.id, set.copyWith(weight: w)),
              onRepsChanged: (r) =>
                  widget.onSetUpdated(set.id, set.copyWith(reps: r)),
              onRemove: () => widget.onRemoveSet(set.id),
            );
          }),

          // ── Add Set Button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: GestureDetector(
              onTap: widget.onAddSet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.plus,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add Set',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
