import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/routines/data/routine_repository_impl.dart';
import 'package:strivo/features/routines/presentation/providers/routine_providers.dart';
import 'package:strivo/features/routines/presentation/widgets/edit_video_dialog.dart';
import 'package:strivo/features/routines/presentation/widgets/routine_exercise_list.dart';
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
      final routine = ref
          .read(routineRepositoryProvider)
          .getById(widget.routineId!);
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
                  RoutineExerciseList(
                    exercises: _exercises,
                    onReorder: _reorderExercises,
                    onSetsChanged: (index, sets) => setState(() {
                      _exercises[index] = _exercises[index].copyWith(
                        targetSets: sets,
                      );
                    }),
                    onRepsChanged: (index, reps) => setState(() {
                      _exercises[index] = _exercises[index].copyWith(
                        targetReps: reps,
                      );
                    }),
                    onEditVideo: _editVideo,
                    onRemove: (index) =>
                        setState(() => _exercises.removeAt(index)),
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

  void _reorderExercises(int oldIndex, int newIndex) {
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    setState(() {
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(target, item);
      _exercises = _exercises
          .asMap()
          .entries
          .map((e) => e.value.copyWith(order: e.key))
          .toList();
    });
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
    final result = await showEditVideoDialog(
      context,
      exerciseName: re.exercise.name,
      currentUrl: re.exercise.videoUrl,
      hasVideo: re.exercise.hasVideo,
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
      final existing = ref
          .read(routineRepositoryProvider)
          .getById(widget.routineId!);
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
