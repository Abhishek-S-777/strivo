import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/routines/presentation/screens/routines_screen.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/features/workout/presentation/widgets/exercise_picker_sheet.dart';

class RoutineBuilderScreen extends ConsumerStatefulWidget {
  const RoutineBuilderScreen({super.key, this.routineId});
  final String? routineId;

  @override
  ConsumerState<RoutineBuilderScreen> createState() =>
      _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  List<RoutineExercise> _exercises = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.routineId != null) {
      _isEditing = true;
      final routine = HiveService.getRoutine(widget.routineId!);
      if (routine != null) {
        _nameController.text = routine.name;
        _descriptionController.text = routine.description ?? '';
        _exercises = List.from(routine.exercises);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Routine' : 'New Routine'),
        actions: [
          TextButton(
            onPressed: _saveRoutine,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Routine Name',
                      hintText: 'e.g., Push Day, Upper Body',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Notes about this routine...',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),

                  // Exercises header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exercises',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${_exercises.length} exercises',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Exercise list
                  if (_exercises.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: AppColors.border,
                        ),
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _exercises.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _exercises.removeAt(oldIndex);
                          _exercises.insert(newIndex, item);
                          _exercises = _exercises
                              .asMap()
                              .entries
                              .map((e) => e.value.copyWith(order: e.key))
                              .toList();
                        });
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final re = _exercises[index];
                        return _RoutineExerciseItem(
                          key: ValueKey(re.id),
                          routineExercise: re,
                          onSetsChanged: (sets) {
                            setState(() {
                              _exercises[index] = re.copyWith(targetSets: sets);
                            });
                          },
                          onRepsChanged: (reps) {
                            setState(() {
                              _exercises[index] = re.copyWith(targetReps: reps);
                            });
                          },
                          onEditVideo: () => _editVideo(index),
                          onRemove: () {
                            setState(() {
                              _exercises.removeAt(index);
                            });
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // Add exercise button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Add Exercise'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addExercise() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExercisePickerSheet(
          onExerciseSelected: (exercise) {
            setState(() {
              _exercises.add(
                RoutineExercise(
                  id: IdGenerator.generate(),
                  exercise: exercise,
                  targetSets: 3,
                  targetReps: 10,
                  order: _exercises.length,
                ),
              );
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  /// Rebuild an exercise with a new (nullable) video URL. Uses the constructor
  /// rather than copyWith so a null actually *clears* the link.
  Exercise _withVideo(Exercise e, String? url) => Exercise(
    id: e.id,
    name: e.name,
    primaryMuscle: e.primaryMuscle,
    secondaryMuscle: e.secondaryMuscle,
    equipment: e.equipment,
    notes: e.notes,
    isCustom: e.isCustom,
    alternativeIds: e.alternativeIds,
    videoUrl: url,
  );

  /// Attach / edit / clear a tutorial video link for a routine exercise. The
  /// link is saved both on the routine and back to the exercise library so it
  /// shows up everywhere the exercise appears.
  Future<void> _editVideo(int index) async {
    final re = _exercises[index];
    final controller = TextEditingController(text: re.exercise.videoUrl ?? '');
    final hadVideo = re.exercise.hasVideo;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Video · ${re.exercise.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'YouTube / video link',
                hintText: 'https://youtu.be/…',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to use an automatic YouTube search when you tap "watch" during a workout.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (hadVideo)
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Clear'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return; // cancelled
    final updated = _withVideo(re.exercise, result.isEmpty ? null : result);
    setState(() => _exercises[index] = re.copyWith(exercise: updated));
    // Persist to the library too (and cloud-sync custom exercises).
    unawaited(ref.read(exerciseLibraryProvider.notifier).addExercise(updated));
  }

  void _saveRoutine() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a routine name')),
      );
      return;
    }

    final now = DateTime.now();
    Routine routine;

    if (_isEditing) {
      final existing = HiveService.getRoutine(widget.routineId!);
      routine = existing!.copyWith(
        name: name,
        description: _descriptionController.text.trim(),
        exercises: _exercises,
        updatedAt: now,
      );
    } else {
      routine = Routine(
        id: IdGenerator.generate(),
        name: name,
        description: _descriptionController.text.trim(),
        exercises: _exercises,
        createdAt: now,
        updatedAt: now,
      );
    }

    unawaited(ref.read(routinesProvider.notifier).saveRoutine(routine));
    context.pop();
  }
}

class _RoutineExerciseItem extends StatelessWidget {
  const _RoutineExerciseItem({
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
