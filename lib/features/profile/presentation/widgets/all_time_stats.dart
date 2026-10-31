import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// The "All-Time Stats" block: total workouts, volume, sets, and time trained
/// across every completed session.
class AllTimeStats extends ConsumerWidget {
  const AllTimeStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workoutSessionsProvider);
    ref.watch(weightUnitProvider); // rebuild volume label on unit change
    final completed = sessions.where((s) => s.isCompleted).toList();
    final totalVolume = completed.fold<double>(
      0,
      (sum, s) => sum + s.totalVolume,
    );
    final totalSets = completed.fold(
      0,
      (sum, s) => sum + s.totalCompletedSets,
    );
    final totalDuration = completed.fold(
      Duration.zero,
      (sum, s) => sum + s.duration,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All-Time Stats', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AllTimeStatCard(
                label: 'Workouts',
                value: '${completed.length}',
                icon: LucideIcons.dumbbell,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AllTimeStatCard(
                label: 'Total Volume',
                value: Units.volumeLabel(totalVolume),
                icon: LucideIcons.barChart2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _AllTimeStatCard(
                label: 'Total Sets',
                value: '$totalSets',
                icon: LucideIcons.layers,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AllTimeStatCard(
                label: 'Time Trained',
                value: '${totalDuration.inHours}h',
                icon: LucideIcons.clock,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AllTimeStatCard extends StatelessWidget {
  const _AllTimeStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
