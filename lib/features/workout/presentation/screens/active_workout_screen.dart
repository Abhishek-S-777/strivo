import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/domain/entities/exercise_set.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/features/workout/presentation/widgets/exercise_picker_sheet.dart';
import 'package:strivo/features/workout/presentation/widgets/rest_timer_widget.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String? routineId;

  const ActiveWorkoutScreen({super.key, this.routineId});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // If coming from routine and no active workout, start one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeWorkout = ref.read(activeWorkoutProvider);
      if (activeWorkout == null && widget.routineId != null) {
        // Workout was already started from home screen
      }
    });
  }

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
              // ── Top Bar ──
              _WorkoutTopBar(
                workoutName: workout.name,
                duration: duration.when(
                  data: (d) => _formatDuration(d),
                  loading: () => '00:00',
                  error: (e, st) => '00:00',
                ),
                onClose: () => _showExitDialog(context),
                onFinish: () => _finishWorkout(context),
              ),

              // ── Rest Timer (shows when active) ──
              if (restTimer.isRunning)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: RestTimerWidget(),
                ),

              // ── Exercise List ──
              Expanded(
                child: workout.exercises.isEmpty
                    ? _EmptyExerciseState(onAdd: () => _showExercisePicker())
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: workout.exercises.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          ref
                              .read(activeWorkoutProvider.notifier)
                              .reorderExercises(oldIndex, newIndex);
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: Colors.transparent,
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final exercise = workout.exercises[index];
                          return _ExerciseCard(
                            key: ValueKey(exercise.id),
                            workoutExercise: exercise,
                            previousExercise: _getPreviousExercise(
                                workout.routineId, exercise),
                            onSetCompleted: (setId) {
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .toggleSetCompletion(exercise.id, setId);
                              HapticFeedback.lightImpact();
                              // Start rest timer on set completion
                              final set = exercise.sets
                                  .firstWhere((s) => s.id == setId);
                              if (!set.isCompleted) {
                                ref
                                    .read(restTimerProvider.notifier)
                                    .startTimer(
                                        exercise.restSeconds ?? 90);
                              }
                            },
                            onSetUpdated: (setId, newSet) {
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .updateSet(exercise.id, setId, newSet);
                            },
                            onAddSet: () {
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .addSet(exercise.id);
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
                          );
                        },
                      ),
              ),

              // ── Bottom Action Bar ──
              _BottomActionBar(
                onAddExercise: () => _showExercisePicker(),
                completedSets: workout.totalCompletedSets,
                totalVolume: workout.totalVolume,
              ),
            ],
          ),
        ),
      ),
    );
  }

  WorkoutExercise? _getPreviousExercise(
      String? routineId, WorkoutExercise current) {
    if (routineId == null) return null;
    final lastSession =
        ref.read(workoutSessionsProvider.notifier).getLastSessionForRoutine(routineId);
    if (lastSession == null) return null;
    return lastSession.exercises
        .where((e) => e.exercise.id == current.exercise.id)
        .firstOrNull;
  }

  void _showExercisePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExercisePickerSheet(
        onExerciseSelected: (exercise) {
          ref.read(activeWorkoutProvider.notifier).addExercise(exercise);
          Navigator.pop(context);
        },
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

    final session =
        await ref.read(activeWorkoutProvider.notifier).finishWorkout();
    if (session != null && context.mounted) {
      ref.read(workoutSessionsProvider.notifier).refresh();
      context.go('/workout/summary/${session.id}');
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
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

// ── Top Bar ──
class _WorkoutTopBar extends StatelessWidget {
  final String workoutName;
  final String duration;
  final VoidCallback onClose;
  final VoidCallback onFinish;

  const _WorkoutTopBar({
    required this.workoutName,
    required this.duration,
    required this.onClose,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  duration,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onFinish,
            icon: const Icon(LucideIcons.check, size: 18),
            label: const Text('Finish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Card (The Core Logging UI) ──
class _ExerciseCard extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final WorkoutExercise? previousExercise;
  final Function(String setId) onSetCompleted;
  final Function(String setId, ExerciseSet newSet) onSetUpdated;
  final VoidCallback onAddSet;
  final Function(String setId) onRemoveSet;
  final VoidCallback onRemoveExercise;
  final Function(String notes) onNotesChanged;

  const _ExerciseCard({
    super.key,
    required this.workoutExercise,
    this.previousExercise,
    required this.onSetCompleted,
    required this.onSetUpdated,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
    required this.onNotesChanged,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _showNotes = false;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.workoutExercise.notes ?? '');
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
          // ── Exercise Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exercise.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exercise.exercise.equipment.displayName} • ${exercise.exercise.primaryMuscle.displayName}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.moreVertical,
                      size: 18, color: AppColors.textTertiary),
                  onSelected: (value) {
                    if (value == 'notes') {
                      setState(() => _showNotes = !_showNotes);
                    } else if (value == 'remove') {
                      widget.onRemoveExercise();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'notes',
                      child: Text('Add Notes'),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove Exercise',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Notes field ──
          if (_showNotes || (exercise.notes?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Add notes...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.history,
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Last: ${prev.sets.length} sets × ${Units.weightLabel(prev.maxWeight)}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textTertiary),
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
                const SizedBox(width: 36, child: Text('SET', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                const SizedBox(width: 8),
                const Expanded(child: Text('PREVIOUS', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                const SizedBox(width: 8),
                SizedBox(width: 72, child: Text(Units.label.toUpperCase(), textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                const SizedBox(width: 8),
                const SizedBox(width: 56, child: Text('REPS', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
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

            return _SetRow(
              set: set,
              previousSet: prevSet,
              onToggleComplete: () => widget.onSetCompleted(set.id),
              onWeightChanged: (w) => widget.onSetUpdated(
                  set.id, set.copyWith(weight: w)),
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
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.plus,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Add Set',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.textSecondary),
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

// ── Individual Set Row (Speed-optimized input) ──
class _SetRow extends StatelessWidget {
  final ExerciseSet set;
  final ExerciseSet? previousSet;
  final VoidCallback onToggleComplete;
  final Function(double) onWeightChanged;
  final Function(int) onRepsChanged;
  final VoidCallback onRemove;

  const _SetRow({
    required this.set,
    this.previousSet,
    required this.onToggleComplete,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRemove,
  });

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
        child: const Icon(LucideIcons.trash2,
            color: AppColors.error, size: 18),
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
                        ? const Icon(LucideIcons.trophy,
                            size: 12, color: AppColors.pr)
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
            _InlineNumberInput(
              value: Units.fromKg(set.weight),
              width: 72,
              onIncrement: () => onWeightChanged(set.weight + Units.stepKg),
              onDecrement: () => onWeightChanged(
                  (set.weight - Units.stepKg).clamp(0, double.infinity)),
              onDirectInput: (v) => onWeightChanged(Units.toKg(v)),
              isDecimal: true,
              unitLabel: Units.label,
              comparison: previousSet != null
                  ? Units.fromKg(set.weight) - Units.fromKg(previousSet!.weight)
                  : null,
            ),
            const SizedBox(width: 8),

            // Reps input
            _InlineNumberInput(
              value: set.reps.toDouble(),
              width: 56,
              onIncrement: () => onRepsChanged(set.reps + 1),
              onDecrement: () =>
                  onRepsChanged((set.reps - 1).clamp(0, 999)),
              onDirectInput: (v) => onRepsChanged(v.toInt()),
              isDecimal: false,
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

// ── Inline Number Input (weight/reps - fast tap input) ──
class _InlineNumberInput extends StatelessWidget {
  final double value;
  final double width;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Function(double) onDirectInput;
  final bool isDecimal;
  final double? comparison;
  final String? unitLabel;

  const _InlineNumberInput({
    required this.value,
    required this.width,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDirectInput,
    this.isDecimal = false,
    this.comparison,
    this.unitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showInputDialog(context),
      onLongPress: onDecrement,
      child: Container(
        width: width,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Decrement tap zone
            GestureDetector(
              onTap: onDecrement,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 14,
                height: 36,
                child: Center(
                  child: Icon(LucideIcons.minus,
                      size: 10, color: AppColors.textTertiary),
                ),
              ),
            ),
            // Value display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isDecimal
                          ? (value % 1 == 0
                              ? value.toInt().toString()
                              : value.toStringAsFixed(1))
                          : value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (comparison != null && comparison != 0)
                      Text(
                        '${comparison! > 0 ? '+' : ''}${comparison!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: comparison! > 0
                              ? AppColors.increase
                              : AppColors.decrease,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Increment tap zone
            GestureDetector(
              onTap: onIncrement,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 14,
                height: 36,
                child: Center(
                  child: Icon(LucideIcons.plus,
                      size: 10, color: AppColors.textTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    final controller = TextEditingController(
      text: isDecimal
          ? (value % 1 == 0 ? value.toInt().toString() : value.toString())
          : value.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDecimal
            ? 'Enter Weight (${unitLabel ?? 'kg'})'
            : 'Enter Reps'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null) {
              onDirectInput(parsed);
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed != null) {
                onDirectInput(parsed);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ──
class _EmptyExerciseState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyExerciseState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.dumbbell,
              size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No exercises added',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an exercise to start logging',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Action Bar ──
class _BottomActionBar extends StatelessWidget {
  final VoidCallback onAddExercise;
  final int completedSets;
  final double totalVolume;

  const _BottomActionBar({
    required this.onAddExercise,
    required this.completedSets,
    required this.totalVolume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Stats
            Expanded(
              child: Row(
                children: [
                  _MiniStat(
                    label: 'Sets',
                    value: '$completedSets',
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    label: 'Volume',
                    value: Units.volumeLabel(totalVolume),
                  ),
                ],
              ),
            ),
            // Add Exercise Button
            ElevatedButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Exercise'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }
}
