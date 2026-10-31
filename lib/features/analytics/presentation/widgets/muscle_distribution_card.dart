import 'package:flutter/material.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// This week's training volume broken down by muscle group, as ranked bars.
class MuscleDistributionCard extends StatelessWidget {
  const MuscleDistributionCard({required this.muscleVolume, super.key});
  final Map<MuscleGroup, double> muscleVolume;

  @override
  Widget build(BuildContext context) {
    final totalVolume = muscleVolume.values.fold<double>(
      0,
      (sum, v) => sum + v,
    );
    if (totalVolume == 0) return const SizedBox.shrink();

    final sorted = muscleVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Muscle Distribution',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "This week's volume by muscle group",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            ...sorted.map((entry) {
              final percent = entry.value / totalVolume * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.displayName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${percent.toStringAsFixed(0)}% · ${Units.volumeLabel(entry.value)}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceLight,
                        color: _getMuscleColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getMuscleColor(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.chest:
        return AppColors.primary;
      case MuscleGroup.back:
        return AppColors.success;
      case MuscleGroup.shoulders:
        return const Color(0xFFFF9F0A);
      case MuscleGroup.biceps:
        return const Color(0xFFBF5AF2);
      case MuscleGroup.triceps:
        return const Color(0xFF64D2FF);
      case MuscleGroup.legs:
        return AppColors.error;
      case MuscleGroup.glutes:
        return const Color(0xFFFF375F);
      case MuscleGroup.core:
        return AppColors.warning;
      case MuscleGroup.fullBody:
      case MuscleGroup.cardio:
      case MuscleGroup.other:
        return AppColors.textSecondary;
    }
  }
}
