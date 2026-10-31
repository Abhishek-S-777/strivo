import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';

/// Shown in an active workout that has no exercises yet, prompting the user to
/// add their first one.
class EmptyExerciseState extends StatelessWidget {
  const EmptyExerciseState({required this.onAdd, super.key});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.dumbbell,
            size: 56,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises added',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an exercise to start logging',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
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
