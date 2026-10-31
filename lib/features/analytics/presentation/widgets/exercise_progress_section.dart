import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/features/analytics/presentation/providers/insights_engine.dart';
import 'package:strivo/features/analytics/presentation/widgets/basic_exercise_card.dart';
import 'package:strivo/features/analytics/presentation/widgets/exercise_search_field.dart';
import 'package:strivo/features/analytics/presentation/widgets/exercise_trend_card.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// The "Exercise Progress" area: a searchable list of the user's trained lifts,
/// shown as rich trend cards when enough data exists and basic cards otherwise,
/// with empty states for no data and no matches.
class ExerciseProgressSection extends ConsumerWidget {
  const ExerciseProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesHistory = ref.watch(exercisesWithHistoryProvider);
    final exerciseTrends = ref.watch(exerciseTrendsProvider);
    ref.watch(weightUnitProvider); // rebuild weight labels on kg/lbs change
    final query = ref
        .watch(analyticsExerciseQueryProvider)
        .trim()
        .toLowerCase();

    final hasExerciseData =
        exerciseTrends.isNotEmpty || exercisesHistory.isNotEmpty;
    final useTrends = exerciseTrends.isNotEmpty;
    final filteredTrends = query.isEmpty
        ? exerciseTrends
        : exerciseTrends
              .where((t) => t.exerciseName.toLowerCase().contains(query))
              .toList();
    final filteredHistory = query.isEmpty
        ? exercisesHistory
        : exercisesHistory
              .where((p) => p.exerciseName.toLowerCase().contains(query))
              .toList();
    final matchCount = useTrends
        ? filteredTrends.length
        : filteredHistory.length;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Exercise Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),

        // Local search across the lifts you've logged.
        if (hasExerciseData)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(child: ExerciseSearchField()),
          ),

        if (!hasExerciseData)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            sliver: SliverToBoxAdapter(
              child: StrivoCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.barChart3,
                        size: 40,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No exercise data yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete workouts to see your progress',
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
        else if (matchCount == 0)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverToBoxAdapter(
              child: StrivoCard(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.search,
                        size: 34,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No exercises match your search',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
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
              delegate: SliverChildBuilderDelegate((context, index) {
                // Prefer rich trend cards; fall back to basic progress.
                if (useTrends) {
                  final trend = filteredTrends[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExerciseTrendCard(
                      trend: trend,
                      onTap: () => context.push(
                        '/analytics/exercise/${trend.exerciseId}?name=${Uri.encodeComponent(trend.exerciseName)}',
                      ),
                    ),
                  );
                }
                final progress = filteredHistory[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BasicExerciseCard(
                    progress: progress,
                    onTap: () => context.push(
                      '/analytics/exercise/${progress.exerciseId}?name=${Uri.encodeComponent(progress.exerciseName)}',
                    ),
                  ),
                );
              }, childCount: matchCount),
            ),
          ),
      ],
    );
  }
}
