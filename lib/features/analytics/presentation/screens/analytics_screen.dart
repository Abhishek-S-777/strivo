import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/features/analytics/presentation/providers/insights_engine.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';
import 'package:strivo/shared/widgets/volume_hero_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final exercisesHistory = ref.watch(exercisesWithHistoryProvider);
    final insights = ref.watch(insightsProvider);
    final streak = ref.watch(trainingStreakProvider);
    final weeklyLoad = ref.watch(weeklyLoadHistoryProvider);
    final exerciseTrends = ref.watch(exerciseTrendsProvider);
    final muscleVolume = ref.watch(muscleGroupVolumeProvider);
    final consistency = ref.watch(consistencyProvider);
    ref.watch(weightUnitProvider); // rebuild on kg/lbs change

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
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border:
                              Border.all(color: AppColors.warning.withAlpha(40)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.flame,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              '${streak.currentStreak}w streak',
                              style: TextStyle(
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

            // ── Weekly Overview ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Week',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    VolumeHeroCard(
                      label: 'Total Volume This Week',
                      volumeKg: weeklyStats.totalVolume,
                      diffPercent: weeklyStats.volumeDiffPercent,
                      stats: [
                        HeroStat('Workouts', '${weeklyStats.workoutCount}'),
                        HeroStat('Sets', '${weeklyStats.totalSets}'),
                        HeroStat(
                          'PRs',
                          '${weeklyStats.prCount}',
                          color:
                              weeklyStats.prCount > 0 ? AppColors.pr : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Smart Insights ──
            if (insights.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Icon(LucideIcons.sparkles,
                          size: 18, color: AppColors.primary),
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
                child: SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: insights.length.clamp(0, 6),
                    itemBuilder: (context, index) {
                      return _InsightCard(insight: insights[index]);
                    },
                  ),
                ),
              ),
            ],

            // ── Strength Trend (1RM curve) ──
            if (exercisesHistory.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _StrengthTrendCard(
                    exercises: exercisesHistory,
                    trends: exerciseTrends,
                  ),
                ),
              ),

            // ── Weekly Volume Chart ──
            if (weeklyLoad.length > 1)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _WeeklyVolumeChart(weeklyLoad: weeklyLoad),
                ),
              ),

            // ── Muscle Distribution ──
            if (muscleVolume.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _MuscleDistributionCard(muscleVolume: muscleVolume),
                ),
              ),

            // ── Consistency Heatmap ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _ConsistencyCard(data: consistency),
              ),
            ),

            // ── Strength Trend Badge ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: StrivoCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _getTrendColor(weeklyStats.trend)
                                .withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTrendIcon(weeklyStats.trend),
                            color: _getTrendColor(weeklyStats.trend),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Trend',
                                style:
                                    Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                _getTrendMessage(weeklyStats),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTrendColor(weeklyStats.trend)
                                .withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            weeklyStats.trend.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getTrendColor(weeklyStats.trend),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Exercise Trends ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Exercise Progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),

            if (exerciseTrends.isEmpty && exercisesHistory.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverToBoxAdapter(
                  child: StrivoCard(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(LucideIcons.barChart3,
                              size: 40, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            'No exercise data yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete workouts to see your progress',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
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
                      // Use exercise trends if available, fall back to basic progress
                      if (exerciseTrends.isNotEmpty &&
                          index < exerciseTrends.length) {
                        final trend = exerciseTrends[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ExerciseTrendCard(
                            trend: trend,
                            onTap: () => context.push(
                              '/analytics/exercise/${trend.exerciseId}?name=${Uri.encodeComponent(trend.exerciseName)}',
                            ),
                          ),
                        );
                      }
                      // Fallback for basic progress data
                      if (index < exercisesHistory.length) {
                        final progress = exercisesHistory[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _BasicExerciseCard(
                            progress: progress,
                            onTap: () => context.push(
                              '/analytics/exercise/${progress.exerciseId}?name=${Uri.encodeComponent(progress.exerciseName)}',
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    childCount: exerciseTrends.isNotEmpty
                        ? exerciseTrends.length
                        : exercisesHistory.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'increase':
        return AppColors.increase;
      case 'decrease':
        return AppColors.decrease;
      default:
        return AppColors.stagnant;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'increase':
        return LucideIcons.trendingUp;
      case 'decrease':
        return LucideIcons.trendingDown;
      default:
        return LucideIcons.minus;
    }
  }

  String _getTrendMessage(WeeklyStats stats) {
    switch (stats.trend) {
      case 'increase':
        return 'Volume up ${stats.volumeDiffPercent.abs().toStringAsFixed(1)}% vs last week';
      case 'decrease':
        return 'Volume down ${stats.volumeDiffPercent.abs().toStringAsFixed(1)}% vs last week';
      default:
        return 'Volume is consistent with last week';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INSIGHT CARD (horizontal scroll)
// ═══════════════════════════════════════════════════════════════════════════════

class _InsightCard extends StatelessWidget {
  final TrainingInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: insight.color.withAlpha(30)),
        gradient: LinearGradient(
          colors: [
            insight.color.withAlpha(8),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: insight.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(insight.icon, size: 16, color: insight.color),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: insight.color.withAlpha(15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _insightTypeLabel(insight.type),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: insight.color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  height: 1.3,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              insight.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    height: 1.4,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _insightTypeLabel(InsightType type) {
    switch (type) {
      case InsightType.prAchieved:
        return 'PR';
      case InsightType.strengthIncreasing:
        return 'GAINS';
      case InsightType.strengthStagnant:
        return 'PLATEAU';
      case InsightType.strengthDecreasing:
        return 'DECLINE';
      case InsightType.volumeMilestone:
        return 'MILESTONE';
      case InsightType.consistencyStreak:
        return 'STREAK';
      case InsightType.muscleImbalance:
        return 'BALANCE';
      case InsightType.overtrainingRisk:
        return 'CAUTION';
      case InsightType.recoverySuggestion:
        return 'RECOVERY';
      case InsightType.newMilestone:
        return 'MILESTONE';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEEKLY VOLUME BAR CHART
// ═══════════════════════════════════════════════════════════════════════════════

class _WeeklyVolumeChart extends StatelessWidget {
  final List<WeeklyLoadSummary> weeklyLoad;

  const _WeeklyVolumeChart({required this.weeklyLoad});

  @override
  Widget build(BuildContext context) {
    final maxVolume = weeklyLoad
        .map((w) => w.totalVolume)
        .fold(0.0, (a, b) => a > b ? a : b);

    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Volume',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Last 8 weeks',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVolume * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.surfaceElevated,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final week = weeklyLoad[group.x.toInt()];
                        return BarTooltipItem(
                          '${Units.volumeLabel(week.totalVolume)}\n',
                          TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${week.workoutCount} workouts',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= weeklyLoad.length) {
                            return const SizedBox.shrink();
                          }
                          final ws = weeklyLoad[idx].weekStart;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('d/M').format(ws),
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyLoad.asMap().entries.map((entry) {
                    final isCurrentWeek =
                        entry.key == weeklyLoad.length - 1;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.totalVolume,
                          width: 18,
                          color: isCurrentWeek
                              ? AppColors.primary
                              : AppColors.primary.withAlpha(60),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MUSCLE DISTRIBUTION
// ═══════════════════════════════════════════════════════════════════════════════

class _MuscleDistributionCard extends StatelessWidget {
  final Map<MuscleGroup, double> muscleVolume;

  const _MuscleDistributionCard({required this.muscleVolume});

  @override
  Widget build(BuildContext context) {
    final totalVolume =
        muscleVolume.values.fold(0.0, (sum, v) => sum + v);
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
              'This week\'s volume by muscle group',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            ...sorted.map((entry) {
              final percent = (entry.value / totalVolume * 100);
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${percent.toStringAsFixed(0)}% · ${Units.volumeLabel(entry.value)}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
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
      default:
        return AppColors.textSecondary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE TREND CARD (with 1RM + trend status)
// ═══════════════════════════════════════════════════════════════════════════════

class _ExerciseTrendCard extends StatelessWidget {
  final ExerciseTrend trend;
  final VoidCallback onTap;

  const _ExerciseTrendCard({
    required this.trend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StrivoCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Trend indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_statusIcon, size: 16, color: _statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trend.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        Units.weightLabel(trend.currentWeight),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      if (trend.weightChange.abs() > 0 &&
                          trend.sessionCount > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: trend.weightChange > 0
                                ? AppColors.successMuted
                                : trend.weightChange < 0
                                    ? AppColors.errorMuted
                                    : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${trend.weightChange > 0 ? '+' : ''}${Units.fromKg(trend.weightChange).toStringAsFixed(1)} ${Units.label}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: trend.weightChange > 0
                                  ? AppColors.increase
                                  : trend.weightChange < 0
                                      ? AppColors.decrease
                                      : AppColors.stagnant,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        'Est. 1RM: ${Units.weightLabel(trend.estimated1RM)}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trend.sessionCount} sessions',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight,
                size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (trend.status) {
      case TrendStatus.progressing:
        return AppColors.success;
      case TrendStatus.stagnant:
        return AppColors.stagnant;
      case TrendStatus.regressing:
        return AppColors.error;
    }
  }

  IconData get _statusIcon {
    switch (trend.status) {
      case TrendStatus.progressing:
        return LucideIcons.trendingUp;
      case TrendStatus.stagnant:
        return LucideIcons.minus;
      case TrendStatus.regressing:
        return LucideIcons.trendingDown;
    }
  }

  String get _statusLabel {
    switch (trend.status) {
      case TrendStatus.progressing:
        return '↑ GAINS';
      case TrendStatus.stagnant:
        return '— PLATEAU';
      case TrendStatus.regressing:
        return '↓ DECLINE';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BASIC EXERCISE CARD (fallback when no trend data)
// ═══════════════════════════════════════════════════════════════════════════════

class _BasicExerciseCard extends StatelessWidget {
  final ExerciseProgressData progress;
  final VoidCallback onTap;

  const _BasicExerciseCard({
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weightDiff = progress.currentMax - progress.previousMax;

    return StrivoCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        Units.weightLabel(progress.currentMax),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      if (weightDiff != 0 && progress.previousMax > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: weightDiff > 0
                                ? AppColors.successMuted
                                : AppColors.errorMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${weightDiff > 0 ? '+' : ''}${Units.fromKg(weightDiff).toStringAsFixed(1)} ${Units.label}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: weightDiff > 0
                                  ? AppColors.increase
                                  : AppColors.decrease,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${progress.dataPoints.length} sessions • Best: ${Units.weightLabel(progress.allTimeMax)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STRENGTH TREND CARD (1RM curve with exercise selector)
// ═══════════════════════════════════════════════════════════════════════════════

class _StrengthTrendCard extends StatefulWidget {
  final List<ExerciseProgressData> exercises;
  final List<ExerciseTrend> trends;

  const _StrengthTrendCard({required this.exercises, required this.trends});

  @override
  State<_StrengthTrendCard> createState() => _StrengthTrendCardState();
}

class _StrengthTrendCardState extends State<_StrengthTrendCard> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // Default to the most-trained lift for a meaningful curve.
    final sorted = [...widget.exercises]
      ..sort((a, b) => b.dataPoints.length.compareTo(a.dataPoints.length));
    _selectedId = sorted.isNotEmpty ? sorted.first.exerciseId : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.exercises.firstWhere(
      (e) => e.exerciseId == _selectedId,
      orElse: () => widget.exercises.first,
    );
    final trend = widget.trends
        .where((t) => t.exerciseId == selected.exerciseId)
        .firstOrNull;
    final points = selected.dataPoints;
    final hasCurve = points.length >= 2;

    // Plot in the user's display unit.
    final maxW = points.isEmpty
        ? 0.0
        : points
            .map((p) => Units.fromKg(p.maxWeight))
            .reduce((a, b) => a > b ? a : b);
    final minW = points.isEmpty
        ? 0.0
        : points
            .map((p) => Units.fromKg(p.maxWeight))
            .reduce((a, b) => a < b ? a : b);
    final span = (maxW - minW).abs();
    final pad = span == 0 ? (maxW == 0 ? 5.0 : maxW * 0.1) : span * 0.25;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withAlpha(12), AppColors.surface],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STRENGTH TREND',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected.exerciseName,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trend != null ? 'EST. 1RM' : 'BEST',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Units.weightLabel(
                        trend?.estimated1RM ?? selected.allTimeMax),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 170,
            child: hasCurve
                ? LineChart(_chartData(points, minW - pad, maxW + pad))
                : Center(
                    child: Text(
                      'Log this lift again to see your trend',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                  ),
          ),

          // Exercise selector
          if (widget.exercises.length > 1) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.exercises.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final ex = widget.exercises[i];
                  final isSel = ex.exerciseId == selected.exerciseId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedId = ex.exerciseId),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary.withAlpha(28)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary.withAlpha(90)
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        ex.exerciseName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSel
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  LineChartData _chartData(
      List<ExerciseProgressPoint> points, double minY, double maxY) {
    final labelEvery = points.length > 6 ? (points.length / 4).ceil() : 1;
    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) =>
            const FlLine(color: AppColors.chartGrid, strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (v, meta) {
              if (v == meta.max || v == meta.min) {
                return const SizedBox.shrink();
              }
              return Text(
                v.toInt().toString(),
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textTertiary),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= points.length || i % labelEvery != 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('MMM').format(points[i].date),
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textTertiary),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surfaceElevated,
          getTooltipItems: (spots) => spots.map((s) {
            final p = points[s.x.toInt()];
            return LineTooltipItem(
              '${Units.weightLabel(p.maxWeight)}\n${DateFormat('MMM d').format(p.date)}',
              const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < points.length; i++)
              FlSpot(i.toDouble(), Units.fromKg(points[i].maxWeight)),
          ],
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: points.length <= 16,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 3,
              color: AppColors.primary,
              strokeWidth: 1.5,
              strokeColor: AppColors.surface,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withAlpha(60),
                AppColors.primary.withAlpha(0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONSISTENCY HEATMAP (last 12 weeks)
// ═══════════════════════════════════════════════════════════════════════════════

class _ConsistencyCard extends StatelessWidget {
  final ConsistencyData data;

  const _ConsistencyCard({required this.data});

  Color _levelColor(int level) {
    switch (level) {
      case 1:
        return AppColors.primary.withAlpha(50);
      case 2:
        return AppColors.primary.withAlpha(120);
      case 3:
        return AppColors.primary;
      case 0:
        return const Color(0xFF1C1C1C);
      default:
        return Colors.transparent; // future days
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Consistency', style: theme.textTheme.titleSmall),
                Text(
                  '${data.activeDays} active days',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Last 12 weeks',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),

            // Grid: 7 rows (Mon→Sun) × 12 cols (weeks)
            LayoutBuilder(
              builder: (context, constraints) {
                const cols = 12, rows = 7, gap = 4.0;
                final cell = (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Column(
                  children: List.generate(rows, (r) {
                    return Padding(
                      padding:
                          EdgeInsets.only(bottom: r < rows - 1 ? gap : 0),
                      child: Row(
                        children: List.generate(cols, (c) {
                          final level = data.weeks[c][r];
                          return Padding(
                            padding: EdgeInsets.only(
                                right: c < cols - 1 ? gap : 0),
                            child: Container(
                              width: cell,
                              height: cell,
                              decoration: BoxDecoration(
                                color: _levelColor(level),
                                borderRadius: BorderRadius.circular(3),
                                border: level == 0
                                    ? Border.all(
                                        color: AppColors.border, width: 0.5)
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Less',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
                Row(
                  children: [
                    for (final lvl in [0, 1, 2, 3])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _levelColor(lvl),
                            borderRadius: BorderRadius.circular(2),
                            border: lvl == 0
                                ? Border.all(
                                    color: AppColors.border, width: 0.5)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Elite',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
