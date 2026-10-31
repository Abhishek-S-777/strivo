import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/features/analytics/presentation/providers/insights_engine.dart';
import 'package:strivo/features/analytics/presentation/widgets/consistency_card.dart';
import 'package:strivo/features/analytics/presentation/widgets/exercise_progress_section.dart';
import 'package:strivo/features/analytics/presentation/widgets/insight_card.dart';
import 'package:strivo/features/analytics/presentation/widgets/muscle_distribution_card.dart';
import 'package:strivo/features/analytics/presentation/widgets/overall_trend_card.dart';
import 'package:strivo/features/analytics/presentation/widgets/strength_trend_card.dart';
import 'package:strivo/features/analytics/presentation/widgets/weekly_overview.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesHistory = ref.watch(exercisesWithHistoryProvider);
    final insights = ref.watch(insightsProvider);
    final streak = ref.watch(trainingStreakProvider);
    final exerciseTrends = ref.watch(exerciseTrendsProvider);
    final muscleVolume = ref.watch(muscleGroupVolumeProvider);
    final consistency = ref.watch(consistencyProvider);
    ref.watch(weightUnitProvider); // rebuild weight-bearing sections on unit

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Analytics',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    if (streak.currentStreak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.warning.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.flame,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${streak.currentStreak}w streak',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Weekly Overview (swipe ◀ ▶ or tap the chevrons to page weeks) ──
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(child: WeeklyOverview()),
            ),

            // ── Smart Insights ──
            if (insights.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Insights',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                // Inset the viewport itself (not the scroll content) so cards
                // clip at a constant 20px gutter on both sides and slide *under*
                // the padding instead of reaching the screen edge when scrolled.
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: insights.length.clamp(0, 6),
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return InsightCard(insight: insights[index]);
                      },
                    ),
                  ),
                ),
              ),
            ],

            // ── Strength Trend (1RM curve) ──
            if (exercisesHistory.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: StrengthTrendCard(
                    exercises: exercisesHistory,
                    trends: exerciseTrends,
                  ),
                ),
              ),

            // ── Muscle Distribution ──
            if (muscleVolume.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: MuscleDistributionCard(muscleVolume: muscleVolume),
                ),
              ),

            // ── Consistency Heatmap ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: ConsistencyCard(data: consistency),
              ),
            ),

            // ── Overall Trend ──
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(child: OverallTrendCard()),
            ),

            // ── Exercise Progress (searchable) ──
            const ExerciseProgressSection(),
          ],
        ),
      ),
    );
  }
}
