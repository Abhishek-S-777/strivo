import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/features/workout/presentation/widgets/active/active_exercise_list.dart';
import 'package:strivo/features/workout/presentation/widgets/active/bottom_action_bar.dart';
import 'package:strivo/features/workout/presentation/widgets/active/workout_top_bar.dart';
import 'package:strivo/features/workout/presentation/widgets/exercise_picker_sheet.dart';
import 'package:strivo/features/workout/presentation/widgets/rest_timer_widget.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, this.routineId});
  final String? routineId;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);
    final duration = ref.watch(workoutDurationProvider);
    final restTimer = ref.watch(restTimerProvider);
    ref.watch(weightUnitProvider); // rebuild on kg/lbs change

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('No active workout'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              WorkoutTopBar(
                workoutName: workout.name,
                duration: duration.when(
                  data: _formatDuration,
                  loading: () => '00:00',
                  error: (e, st) => '00:00',
                ),
                onClose: () => _showExitDialog(context),
                onFinish: () => _finishWorkout(context),
              ),

              // Rest timer (shows when active)
              if (restTimer.isRunning)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: RestTimerWidget(),
                ),

              Expanded(
                child: ActiveExerciseList(
                  workout: workout,
                  onAddExercise: _showExercisePicker,
                ),
              ),

              BottomActionBar(
                onAddExercise: _showExercisePicker,
                completedSets: workout.totalCompletedSets,
                totalVolume: workout.totalVolume,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExercisePicker() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExercisePickerSheet(
          onExerciseSelected: (exercise) {
            ref.read(activeWorkoutProvider.notifier).addExercise(exercise);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _finishWorkout(BuildContext context) async {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;

    if (!workout.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete at least one set first')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: Text(
          'You completed ${workout.totalCompletedSets} sets across ${workout.totalExercises} exercises.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final session = await ref
        .read(activeWorkoutProvider.notifier)
        .finishWorkout();
    if (session != null && context.mounted) {
      ref.read(workoutSessionsProvider.notifier).refresh();
      context.go('/workout/summary/${session.id}');
    }
  }

  void _showExitDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave Workout?'),
          content: const Text(
            'Your workout will be saved and you can continue later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('Leave (Auto-saved)'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(activeWorkoutProvider.notifier).discardWorkout();
                if (context.mounted) context.pop();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Discard'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
