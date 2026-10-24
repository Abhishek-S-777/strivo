import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    final exerciseTrends = ref.watch(exerciseTrendsProvider);
    final muscleVolume = ref.watch(muscleGroupVolumeProvider);
    final consistency = ref.watch(consistencyProvider);
    ref.watch(weightUnitProvider); // rebuild on kg/lbs change

    // Exercise Progress search — a local filter over the user's trained lifts.
    final exerciseQuery = ref
        .watch(analyticsExerciseQueryProvider)
        .trim()
        .toLowerCase();
    final hasExerciseData =
        exerciseTrends.isNotEmpty || exercisesHistory.isNotEmpty;
    final useTrends = exerciseTrends.isNotEmpty;
    final filteredTrends = exerciseQuery.isEmpty
        ? exerciseTrends
        : exerciseTrends
              .where(
                (t) => t.exerciseName.toLowerCase().contains(exerciseQuery),
              )
              .toList();
    final filteredHistory = exerciseQuery.isEmpty
        ? exercisesHistory
        : exercisesHistory
              .where(
                (p) => p.exerciseName.toLowerCase().contains(exerciseQuery),
              )
              .toList();
    final matchCount = useTrends
        ? filteredTrends.length
        : filteredHistory.length;

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
              sliver: SliverToBoxAdapter(child: _WeeklyOverview()),
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
                        return _InsightCard(insight: insights[index]);
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
                  child: _StrengthTrendCard(
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
                            color: _getTrendColor(
                              weeklyStats.trend,
                            ).withAlpha(20),
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
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                _getTrendMessage(weeklyStats),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTrendColor(
                              weeklyStats.trend,
                            ).withAlpha(20),
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

            // ── Exercise Progress (searchable) ──
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
                sliver: SliverToBoxAdapter(child: _ExerciseSearchField()),
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete workouts to see your progress',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
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
                        child: _ExerciseTrendCard(
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
                      child: _BasicExerciseCard(
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
  const _InsightCard({required this.insight});
  final TrainingInsight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: insight.color.withAlpha(30)),
        gradient: LinearGradient(
          colors: [insight.color.withAlpha(8), AppColors.surface],
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontSize: 13, height: 1.3),
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
// WEEKLY OVERVIEW (swipeable hero card)
// ═══════════════════════════════════════════════════════════════════════════════

/// The volume hero card, paged through history: swipe right (or tap ◀) for the
/// previous week, swipe left (or tap ▶) for the next — bounded by the first week
/// you trained and the current week.
class _WeeklyOverview extends ConsumerStatefulWidget {
  const _WeeklyOverview();

  @override
  ConsumerState<_WeeklyOverview> createState() => _WeeklyOverviewState();
}

class _WeeklyOverviewState extends ConsumerState<_WeeklyOverview> {
  int _offset = 0; // 0 = current week, negative = further back
  int _dir = 0; // last navigation direction, drives the slide transition

  void _go(int delta, int minOffset) {
    final next = _offset + delta;
    if (next > 0 || next < minOffset) return; // no future, no empty pre-history
    setState(() {
      _dir = delta;
      _offset = next;
    });
  }

  String _label(int offset) {
    switch (offset) {
      case 0:
        return 'This Week';
      case -1:
        return 'Last Week';
      default:
        return '${-offset} Weeks Ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = ref.watch(weeklyStatsForWeekProvider(_offset));
    final minOffset = ref.watch(earliestTrainedWeekOffsetProvider);
    final canOlder = _offset > minOffset;
    final canNewer = _offset < 0;
    final weekEnd = stats.weekStart.add(const Duration(days: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(stats.weekOffset),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM d').format(stats.weekStart)} – ${DateFormat('MMM d').format(weekEnd)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            _WeekNavButton(
              icon: LucideIcons.chevronLeft,
              enabled: canOlder,
              onTap: () => _go(-1, minOffset),
            ),
            const SizedBox(width: 6),
            _WeekNavButton(
              icon: LucideIcons.chevronRight,
              enabled: canNewer,
              onTap: () => _go(1, minOffset),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v > 120) {
              _go(-1, minOffset); // swipe right → previous (older) week
            } else if (v < -120) {
              _go(1, minOffset); // swipe left → next (newer) week
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              final begin = Offset(
                _dir == 0 ? 0 : (_dir > 0 ? 0.12 : -0.12),
                0,
              );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: begin,
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: VolumeHeroCard(
              key: ValueKey(stats.weekOffset),
              label: 'Total Volume',
              volumeKg: stats.totalVolume,
              diffPercent: stats.volumeDiffPercent,
              stats: [
                HeroStat('Workouts', '${stats.workoutCount}'),
                HeroStat('Sets', '${stats.totalSets}'),
                HeroStat(
                  'PRs',
                  '${stats.prCount}',
                  color: stats.prCount > 0 ? AppColors.pr : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekNavButton extends StatelessWidget {
  const _WeekNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.textSecondary
              : AppColors.textTertiary.withAlpha(60),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE PROGRESS SEARCH
// ═══════════════════════════════════════════════════════════════════════════════

/// Search query for the "Exercise Progress" list. Auto-disposes (resets to '')
/// when the Analytics screen leaves the tree.
final AutoDisposeStateProvider<String> analyticsExerciseQueryProvider =
    StateProvider.autoDispose<String>(
      (ref) => '',
    );

class _ExerciseSearchField extends ConsumerStatefulWidget {
  const _ExerciseSearchField();

  @override
  ConsumerState<_ExerciseSearchField> createState() =>
      _ExerciseSearchFieldState();
}

class _ExerciseSearchFieldState extends ConsumerState<_ExerciseSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(analyticsExerciseQueryProvider);
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search your exercises...',
        prefixIcon: const Icon(LucideIcons.search, size: 18),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: () {
                  _controller.clear();
                  ref.read(analyticsExerciseQueryProvider.notifier).state = '';
                },
              ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (v) =>
          ref.read(analyticsExerciseQueryProvider.notifier).state = v,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STRENGTH-TREND EXERCISE PICKER (searchable bottom sheet)
// ═══════════════════════════════════════════════════════════════════════════════

class _StrengthExercisePickerSheet extends StatefulWidget {
  const _StrengthExercisePickerSheet({
    required this.exercises,
    this.selectedId,
  });
  final List<ExerciseProgressData> exercises;
  final String? selectedId;

  @override
  State<_StrengthExercisePickerSheet> createState() =>
      _StrengthExercisePickerSheetState();
}

class _StrengthExercisePickerSheetState
    extends State<_StrengthExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.exercises
        : widget.exercises
              .where((e) => e.exerciseName.toLowerCase().contains(q))
              .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Strength Trend',
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
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
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No exercises found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final e = items[i];
                      final sel = e.exerciseId == widget.selectedId;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary.withAlpha(28)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.dumbbell,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          e.exerciseName,
                          style: theme.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          '${e.dataPoints.length} sessions • Best ${Units.weightLabel(e.allTimeMax)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        trailing: sel
                            ? const Icon(
                                LucideIcons.check,
                                size: 18,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, e.exerciseId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MUSCLE DISTRIBUTION
// ═══════════════════════════════════════════════════════════════════════════════

class _MuscleDistributionCard extends StatelessWidget {
  const _MuscleDistributionCard({required this.muscleVolume});
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

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE TREND CARD (with 1RM + trend status)
// ═══════════════════════════════════════════════════════════════════════════════

class _ExerciseTrendCard extends StatelessWidget {
  const _ExerciseTrendCard({required this.trend, required this.onTap});
  final ExerciseTrend trend;
  final VoidCallback onTap;

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
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textTertiary,
            ),
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
  const _BasicExerciseCard({required this.progress, required this.onTap});
  final ExerciseProgressData progress;
  final VoidCallback onTap;

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
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
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
  const _StrengthTrendCard({required this.exercises, required this.trends});
  final List<ExerciseProgressData> exercises;
  final List<ExerciseTrend> trends;

  @override
  State<_StrengthTrendCard> createState() => _StrengthTrendCardState();
}

class _StrengthTrendCardState extends State<_StrengthTrendCard> {
  String? _selectedId;
  final _chipScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Default to the most-trained lift for a meaningful curve.
    final sorted = [...widget.exercises]
      ..sort((a, b) => b.dataPoints.length.compareTo(a.dataPoints.length));
    _selectedId = sorted.isNotEmpty ? sorted.first.exerciseId : null;
  }

  @override
  void dispose() {
    _chipScroll.dispose();
    super.dispose();
  }

  /// Select a lift and float its chip to the front of the row, gliding the
  /// list back to the start so the active chip is always the first one in view.
  void _select(String id) {
    setState(() => _selectedId = id);
    if (_chipScroll.hasClients) {
      unawaited(
        _chipScroll.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.exercises.firstWhere(
      (e) => e.exerciseId == _selectedId,
      orElse: () => widget.exercises.first,
    );
    // Selected lift floats to the front of the chip row; the rest keep their
    // original order, so a previously-selected chip returns to its old spot.
    final ordered = [
      selected,
      for (final e in widget.exercises)
        if (e.exerciseId != selected.exerciseId) e,
    ];
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                      trend?.estimated1RM ?? selected.allTimeMax,
                    ),
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
          ),

          // Exercise selector — a pinned search button + quick-access chips,
          // so a lift at the end of the list is one tap (not a long swipe) away.
          if (widget.exercises.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openSearch(selected.exerciseId),
                  child: Container(
                    height: 32,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      LucideIcons.search,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView.separated(
                      controller: _chipScroll,
                      scrollDirection: Axis.horizontal,
                      itemCount: ordered.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final ex = ordered[i];
                        final isSel = ex.exerciseId == selected.exerciseId;
                        return GestureDetector(
                          onTap: () => _select(ex.exerciseId),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.primary.withAlpha(28)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
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
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Open a searchable picker so any lift (even one far down the chip row) is
  /// reachable without scrolling. Returns the chosen exercise id.
  Future<void> _openSearch(String currentId) async {
    final sorted = [...widget.exercises]
      ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StrengthExercisePickerSheet(
        exercises: sorted,
        selectedId: currentId,
      ),
    );
    if (id != null && mounted) _select(id);
  }

  LineChartData _chartData(
    List<ExerciseProgressPoint> points,
    double minY,
    double maxY,
  ) {
    final labelEvery = points.length > 6 ? (points.length / 4).ceil() : 1;
    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) =>
            const FlLine(color: AppColors.chartGrid, strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
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
                  fontSize: 9,
                  color: AppColors.textTertiary,
                ),
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
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
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
  const _ConsistencyCard({required this.data});
  final ConsistencyData data;

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
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),

            // Grid: 7 rows (Mon→Sun) × 12 cols (weeks)
            LayoutBuilder(
              builder: (context, constraints) {
                const cols = 12;
                const rows = 7;
                const gap = 4.0;
                final cell = (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Column(
                  children: List.generate(rows, (r) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: r < rows - 1 ? gap : 0),
                      child: Row(
                        children: List.generate(cols, (c) {
                          final level = data.weeks[c][r];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: c < cols - 1 ? gap : 0,
                            ),
                            child: Container(
                              width: cell,
                              height: cell,
                              decoration: BoxDecoration(
                                color: _levelColor(level),
                                borderRadius: BorderRadius.circular(3),
                                border: level == 0
                                    ? Border.all(
                                        color: AppColors.border,
                                        width: 0.5,
                                      )
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
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
                                    color: AppColors.border,
                                    width: 0.5,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Elite',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
