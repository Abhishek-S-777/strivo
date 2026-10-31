import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/features/workout/presentation/widgets/home/recent_workout_card.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// The Home "Recent Workouts" sliver: a header followed by the most recent
/// completed sessions (up to 10), or an empty-state card when there are none.
class RecentWorkoutsSection extends ConsumerWidget {
  const RecentWorkoutsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workoutSessionsProvider);
    ref.watch(weightUnitProvider); // rebuild volume labels on unit change

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Recent Workouts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        if (sessions.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            sliver: SliverToBoxAdapter(
              child: StrivoCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.dumbbell,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workouts yet',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start your first workout to begin tracking your progress',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= sessions.length || index >= 10) return null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RecentWorkoutCard(session: sessions[index]),
                  );
                },
                childCount: sessions.length.clamp(0, 10),
              ),
            ),
          ),
      ],
    );
  }
}
