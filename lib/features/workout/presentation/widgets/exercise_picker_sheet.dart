import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/features/workout/presentation/widgets/alternatives_sheet.dart';
import 'package:strivo/features/workout/presentation/widgets/create_exercise_dialog.dart';
import 'package:strivo/features/workout/presentation/widgets/exercise_list_item.dart';

class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({
    required this.onExerciseSelected,
    super.key,
  });
  final void Function(Exercise) onExerciseSelected;

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
                  onPressed: () => showCreateExerciseDialog(
                    context,
                    ref,
                    widget.onExerciseSelected,
                  ),
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
              decoration: const InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(LucideIcons.search, size: 18),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                ...MuscleGroup.values.map(
                  (mg) => _FilterChip(
                    label: mg.displayName,
                    isSelected: _selectedMuscle == mg,
                    onTap: () => setState(() => _selectedMuscle = mg),
                  ),
                ),
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
                        const Icon(
                          LucideIcons.search,
                          size: 40,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises found',
                          style: Theme.of(context).textTheme.bodyMedium
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
                      return ExerciseListItem(
                        exercise: exercise,
                        onTap: () => widget.onExerciseSelected(exercise),
                        onShowAlternatives: exercise.hasAlternatives
                            ? () => _showAlternatives(exercise, allExercises)
                            : null,
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
      result = result.where((e) => e.primaryMuscle == _selectedMuscle).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where(
            (e) =>
                e.name.toLowerCase().contains(query) ||
                e.primaryMuscle.displayName.toLowerCase().contains(query) ||
                e.equipment.displayName.toLowerCase().contains(query),
          )
          .toList();
    }

    return result;
  }

  /// Show this exercise's alternatives (e.g. when the required machine isn't
  /// available). Picking one selects it in place of the original.
  Future<void> _showAlternatives(Exercise base, List<Exercise> all) async {
    final byId = {for (final e in all) e.id: e};
    final alts = [
      for (final id in base.alternativeIds)
        if (byId[id] != null) byId[id]!,
    ];
    if (alts.isEmpty) return;
    final chosen = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AlternativesSheet(base: base, alternatives: alts),
    );
    if (chosen != null) widget.onExerciseSelected(chosen);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

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
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
