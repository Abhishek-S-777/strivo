import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';

class ExercisePickerSheet extends ConsumerStatefulWidget {
  final Function(Exercise) onExerciseSelected;

  const ExercisePickerSheet({
    super.key,
    required this.onExerciseSelected,
  });

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  String _searchQuery = '';
  MuscleGroup? _selectedMuscle;

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exerciseLibraryProvider);
    final filtered = _getFilteredExercises(allExercises);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Exercise',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton.icon(
                  onPressed: () => _showCreateExerciseDialog(context),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Custom'),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Muscle group filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedMuscle == null,
                  onTap: () => setState(() => _selectedMuscle = null),
                ),
                ...MuscleGroup.values.map((mg) => _FilterChip(
                      label: mg.displayName,
                      isSelected: _selectedMuscle == mg,
                      onTap: () => setState(() => _selectedMuscle = mg),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.search,
                            size: 40, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises found',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return _ExerciseListItem(
                        exercise: exercise,
                        onTap: () =>
                            widget.onExerciseSelected(exercise),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Exercise> _getFilteredExercises(List<Exercise> all) {
    var result = all;

    if (_selectedMuscle != null) {
      result =
          result.where((e) => e.primaryMuscle == _selectedMuscle).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((e) =>
              e.name.toLowerCase().contains(query) ||
              e.primaryMuscle.displayName.toLowerCase().contains(query) ||
              e.equipment.displayName.toLowerCase().contains(query))
          .toList();
    }

    return result;
  }

  void _showCreateExerciseDialog(BuildContext context) {
    final nameController = TextEditingController();
    MuscleGroup selectedMuscle = MuscleGroup.chest;
    Equipment selectedEquipment = Equipment.barbell;

    showDialog(
      context: context,
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
                    .map((m) => DropdownMenuItem(
                        value: m, child: Text(m.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => selectedMuscle = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Equipment>(
                initialValue: selectedEquipment,
                decoration: const InputDecoration(labelText: 'Equipment'),
                items: Equipment.values
                    .map((e) => DropdownMenuItem(
                        value: e, child: Text(e.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => selectedEquipment = v!),
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
                final exercise = Exercise(
                  id: IdGenerator.generate(),
                  name: nameController.text.trim(),
                  primaryMuscle: selectedMuscle,
                  equipment: selectedEquipment,
                  isCustom: true,
                );
                ref
                    .read(exerciseLibraryProvider.notifier)
                    .addExercise(exercise);
                Navigator.pop(ctx);
                widget.onExerciseSelected(exercise);
                Navigator.pop(context);
              },
              child: const Text('Create & Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: isSelected
            ? AppDecorations.activeChip
            : AppDecorations.chip,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseListItem({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getEquipmentIcon(exercise.equipment),
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exercise.primaryMuscle.displayName} • ${exercise.equipment.displayName}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (exercise.isCustom)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Custom',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 9,
                      ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(LucideIcons.plus,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  IconData _getEquipmentIcon(Equipment equipment) {
    switch (equipment) {
      case Equipment.barbell:
        return LucideIcons.zap;
      case Equipment.dumbbell:
        return LucideIcons.dumbbell;
      case Equipment.machine:
        return LucideIcons.settings;
      case Equipment.cable:
        return LucideIcons.link2;
      case Equipment.bodyweight:
        return LucideIcons.user;
      case Equipment.kettlebell:
        return LucideIcons.diamond;
      case Equipment.band:
        return LucideIcons.activity;
      case Equipment.other:
        return LucideIcons.circle;
    }
  }
}
