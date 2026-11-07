import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';

/// Dialog for creating a custom exercise. On save it persists the exercise to
/// the library, reports it via [onExerciseSelected], and closes the picker
/// ([sheetContext]).
void showCreateExerciseDialog(
  BuildContext sheetContext,
  WidgetRef ref,
  void Function(Exercise) onExerciseSelected,
) {
  final nameController = TextEditingController();
  final videoController = TextEditingController();
  var selectedMuscle = MuscleGroup.chest;
  var selectedEquipment = Equipment.barbell;

  unawaited(
    showDialog<void>(
      context: sheetContext,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Close Grip Lat Pulldown',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MuscleGroup>(
                initialValue: selectedMuscle,
                decoration: const InputDecoration(labelText: 'Muscle Group'),
                items: MuscleGroup.values
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedMuscle = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Equipment>(
                initialValue: selectedEquipment,
                decoration: const InputDecoration(labelText: 'Equipment'),
                items: Equipment.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedEquipment = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: videoController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Video link (optional)',
                  hintText: 'https://youtu.be/…',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                final video = videoController.text.trim();
                final exercise = Exercise(
                  id: IdGenerator.generate(),
                  name: nameController.text.trim(),
                  primaryMuscle: selectedMuscle,
                  equipment: selectedEquipment,
                  isCustom: true,
                  videoUrl: video.isEmpty ? null : video,
                );
                unawaited(
                  ref
                      .read(exerciseLibraryProvider.notifier)
                      .addExercise(exercise),
                );
                Navigator.pop(ctx);
                onExerciseSelected(exercise);
                Navigator.pop(sheetContext);
              },
              child: const Text('Create & Add'),
            ),
          ],
        ),
      ),
    ),
  );
}
