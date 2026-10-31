import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/utils/video_launcher.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/features/workout/presentation/widgets/active/empty_exercise_state.dart';
import 'package:strivo/features/workout/presentation/widgets/active/exercise_card.dart';
import 'package:strivo/features/workout/presentation/widgets/exercise_picker_sheet.dart';

/// The reorderable list of exercise cards in an active workout. Wires each
/// card's set/notes/remove/swap/video actions to the workout notifier, and
/// shows the empty state when no exercises have been added.
class ActiveExerciseList extends ConsumerWidget {
  const ActiveExerciseList({
    required this.workout,
    required this.onAddExercise,
    super.key,
  });

  final WorkoutSession workout;
  final VoidCallback onAddExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (workout.exercises.isEmpty) {
      return EmptyExerciseState(onAdd: onAddExercise);
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: workout.exercises.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        ref
            .read(activeWorkoutProvider.notifier)
            .reorderExercises(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return Material(color: Colors.transparent, child: child);
      },
      itemBuilder: (context, index) {
        final exercise = workout.exercises[index];
        return ExerciseCard(
          key: ValueKey(exercise.id),
          workoutExercise: exercise,
          previousExercise: _getPreviousExercise(ref, workout, exercise),
          onSetCompleted: (setId) {
            ref
                .read(activeWorkoutProvider.notifier)
                .toggleSetCompletion(exercise.id, setId);
            unawaited(HapticFeedback.lightImpact());
            // Start rest timer on set completion
            final set = exercise.sets.firstWhere((s) => s.id == setId);
            if (!set.isCompleted) {
              ref
                  .read(restTimerProvider.notifier)
                  .startTimer(
                    exercise.restSeconds ??
                        ref.read(defaultRestSecondsProvider),
                  );
            }
          },
          onSetUpdated: (setId, newSet) {
            ref
                .read(activeWorkoutProvider.notifier)
                .updateSet(exercise.id, setId, newSet);
          },
          onAddSet: () {
            ref.read(activeWorkoutProvider.notifier).addSet(exercise.id);
          },
          onRemoveSet: (setId) {
            ref
                .read(activeWorkoutProvider.notifier)
                .removeSet(exercise.id, setId);
          },
          onRemoveExercise: () {
            ref
                .read(activeWorkoutProvider.notifier)
                .removeExercise(exercise.id);
          },
          onNotesChanged: (notes) {
            ref
                .read(activeWorkoutProvider.notifier)
                .updateExerciseNotes(exercise.id, notes);
          },
          onWatchVideo: () => _watchVideo(context, exercise.exercise),
          onSwap: () => _showAlternatives(context, ref, exercise),
        );
      },
    );
  }

  WorkoutExercise? _getPreviousExercise(
    WidgetRef ref,
    WorkoutSession workout,
    WorkoutExercise current,
  ) {
    final notifier = ref.read(workoutSessionsProvider.notifier);
    WorkoutSession? lastSession;
    if (workout.programId != null && workout.programDayName != null) {
      lastSession = notifier.getLastSessionForProgramDay(
        workout.programId!,
        workout.programDayName!,
      );
    } else if (workout.routineId != null) {
      lastSession = notifier.getLastSessionForRoutine(workout.routineId!);
    }
    if (lastSession == null) return null;
    return lastSession.exercises
        .where((e) => e.exercise.id == current.exercise.id)
        .firstOrNull;
  }

  /// Open a form/technique video for the exercise (pinned link or YouTube
  /// search fallback), so the user can check technique without leaving flow.
  Future<void> _watchVideo(BuildContext context, Exercise exercise) async {
    final ok = await ExerciseVideo.open(exercise);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open a video for this exercise'),
        ),
      );
    }
  }

  /// Show this exercise's alternatives and swap the chosen one in, in place —
  /// the user-friendly "machine is taken" flow, right from the logging screen.
  Future<void> _showAlternatives(
    BuildContext context,
    WidgetRef ref,
    WorkoutExercise we,
  ) async {
    final alts = ref
        .read(exerciseLibraryProvider.notifier)
        .resolveByIds(we.exercise.alternativeIds);
    if (alts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No alternatives listed for this exercise'),
        ),
      );
      return;
    }
    final chosen = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AlternativesSheet(base: we.exercise, alternatives: alts),
    );
    if (chosen != null && context.mounted) {
      ref.read(activeWorkoutProvider.notifier).replaceExercise(we.id, chosen);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Swapped to ${chosen.name}')),
      );
    }
  }
}
