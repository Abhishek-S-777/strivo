import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';

/// The fixed bottom bar during an active workout: running set/volume totals and
/// an add-exercise action.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    required this.onAddExercise,
    required this.completedSets,
    required this.totalVolume,
    super.key,
  });
  final VoidCallback onAddExercise;
  final int completedSets;
  final double totalVolume;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
