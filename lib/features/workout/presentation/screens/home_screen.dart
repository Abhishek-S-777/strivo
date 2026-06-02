import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/features/auth/presentation/providers/auth_providers.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/programs/presentation/providers/program_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';
import 'package:strivo/shared/widgets/volume_hero_card.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/features/analytics/presentation/providers/insights_engine.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workoutSessionsProvider);
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final routines = HiveService.getAllRoutines();
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final weeklyLoad = ref.watch(weeklyLoadHistoryProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final firstName = _firstName(user?.displayName);
    ref.watch(weightUnitProvider); // rebuild when kg/lbs preference changes
    final activeProgram = ref.watch(activeProgramProvider);
    final showProgram = activeProgram != null &&
        !activeProgram.isComplete &&
        activeProgram.currentDay != null;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STRIVO',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                        ),
                        if (activeWorkout != null)
                          _ActiveWorkoutBadge(workout: activeWorkout),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Greeting
                    Text(
                      DateFormat('EEEE, MMM d')
                          .format(DateTime.now())
                          .toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firstName == null
                          ? '${_getGreeting()}.'
                          : 'Welcome back, $firstName',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Weekly Volume Hero ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: VolumeHeroCard(
                  label: 'Volume This Week',
                  volumeKg: weeklyStats.totalVolume,
                  diffPercent: weeklyStats.volumeDiffPercent,
                  sparkline:
                      weeklyLoad.map((w) => w.totalVolume).toList(),
                  stats: [
                    HeroStat('Workouts', '${weeklyStats.workoutCount}'),
                    HeroStat('Sets', '${weeklyStats.totalSets}'),
                    HeroStat(
                      'PRs',
                      '${weeklyStats.prCount}',
                      color: weeklyStats.prCount > 0 ? AppColors.pr : null,
                    ),
                  ],
                ),
              ),
            ),

            // ── Today's Workout (active program) ──
            if (showProgram)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Workout",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _TodayProgramCard(
                        program: activeProgram,
                        hasActiveWorkout: activeWorkout != null,
                        onStart: () {
                          if (activeWorkout != null) {
                            context.push('/workout/active');
                          } else {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .startProgramDay(activeProgram);
                            context.push('/workout/active');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )
            // ── Next Routine (fallback when no active program) ──
            else if (routines.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Routine',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _NextRoutineCard(
                        routine: routines.first,
                        hasActiveWorkout: activeWorkout != null,
                        onStart: () {
                          if (activeWorkout != null) {
                            context.push('/workout/active');
                          } else {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .startWorkout(routine: routines.first);
                            context.push('/workout/active');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // ── Quick Start Section ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Start',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    // Start empty workout button
                    _QuickStartButton(
                      onTap: () {
                        if (activeWorkout != null) {
                          context.push('/workout/active');
                        } else {
                          ref
                              .read(activeWorkoutProvider.notifier)
                              .startWorkout();
                          context.push('/workout/active');
                        }
                      },
                      hasActiveWorkout: activeWorkout != null,
                    ),
                  ],
                ),
              ),
            ),

            // ── Routines Horizontal List ──
            if (routines.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Routines',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () => context.go('/routines'),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      return _RoutineCard(
                        routine: routines[index],
                        onTap: () {
                          if (activeWorkout != null) {
                            _showActiveWorkoutDialog(context);
                          } else {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .startWorkout(routine: routines[index]);
                            context.push('/workout/active');
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],

            // ── Recent Workouts ──
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
                          Icon(
                            LucideIcons.dumbbell,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No workouts yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start your first workout to begin tracking your progress',
                            textAlign: TextAlign.center,
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
                      if (index >= sessions.length || index >= 10) return null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentWorkoutCard(session: sessions[index]),
                      );
                    },
                    childCount: sessions.length.clamp(0, 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String? _firstName(String? displayName) {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(' ').first;
  }

  void _showActiveWorkoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Active Workout'),
        content: const Text(
            'You have an active workout in progress. Would you like to continue it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/workout/active');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

// ── Active Workout Badge ──
class _ActiveWorkoutBadge extends StatelessWidget {
  final WorkoutSession workout;

  const _ActiveWorkoutBadge({required this.workout});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/workout/active'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'In Progress',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Next Routine Card (featured) ──
class _NextRoutineCard extends StatelessWidget {
  final Routine routine;
  final bool hasActiveWorkout;
  final VoidCallback onStart;

  const _NextRoutineCard({
    required this.routine,
    required this.hasActiveWorkout,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscles = routine.exercises
        .map((e) => e.exercise.primaryMuscle.displayName)
        .toSet()
        .take(3)
        .join(', ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 0.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2336), AppColors.surface],
          ),
        ),
        child: Stack(
          children: [
            // Watermark
            Positioned(
              right: -18,
              top: -18,
              child: Icon(
                LucideIcons.dumbbell,
                size: 130,
                color: AppColors.primary.withAlpha(15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    muscles.isEmpty
                        ? '${routine.exerciseCount} exercises • ${routine.totalTargetSets} sets'
                        : '$muscles • ${routine.totalTargetSets} sets',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onStart,
                      icon: Icon(
                        hasActiveWorkout
                            ? LucideIcons.arrowRight
                            : LucideIcons.play,
                        size: 18,
                      ),
                      label: Text(
                        hasActiveWorkout ? 'Resume Workout' : 'Start Workout',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Start Button ──
class _QuickStartButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasActiveWorkout;

  const _QuickStartButton({
    required this.onTap,
    required this.hasActiveWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withAlpha(25),
              AppColors.primary.withAlpha(10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                hasActiveWorkout ? LucideIcons.play : LucideIcons.plus,
                color: AppColors.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasActiveWorkout
                        ? 'Continue Workout'
                        : 'Start Empty Workout',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasActiveWorkout
                        ? 'Resume your active session'
                        : 'Start logging without a routine',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Routine Card (horizontal list) ──
class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback onTap;

  const _RoutineCard({required this.routine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${routine.exerciseCount} exercises',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${routine.timesUsed}x used',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(
                    LucideIcons.play,
                    size: 14,
                    color: AppColors.primary,
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

// ── Today's Program Workout Card ──
class _TodayProgramCard extends StatelessWidget {
  final Program program;
  final bool hasActiveWorkout;
  final VoidCallback onStart;

  const _TodayProgramCard({
    required this.program,
    required this.hasActiveWorkout,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = program.currentDay!;
    final week = program.currentWeek;
    final badge = program.isOngoing
        ? 'UP NEXT'
        : 'WEEK $week OF ${program.durationWeeks}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 0.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2336), AppColors.surface],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
              child: Icon(LucideIcons.calendarRange,
                  size: 120, color: AppColors.primary.withAlpha(15)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(28),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.primary,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(program.name,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(day.name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  ...day.exercises.take(4).map((pe) {
                    final t = pe.targetForWeek(week);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(pe.exercise.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(t.displayFull,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                    );
                  }),
                  if (day.exercises.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('+${day.exercises.length - 4} more',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textTertiary)),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onStart,
                      icon: Icon(
                        hasActiveWorkout
                            ? LucideIcons.arrowRight
                            : LucideIcons.play,
                        size: 18,
                      ),
                      label: Text(
                        hasActiveWorkout ? 'Resume Workout' : 'Start Workout',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Workout Card ──
class _RecentWorkoutCard extends StatelessWidget {
  final WorkoutSession session;

  const _RecentWorkoutCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM d').format(session.startTime),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (session.prCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.pr.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.trophy,
                            size: 12, color: AppColors.pr),
                        const SizedBox(width: 4),
                        Text(
                          '${session.prCount} PR${session.prCount > 1 ? 's' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.pr,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _WorkoutStat(
                  icon: LucideIcons.clock,
                  value: session.durationFormatted,
                ),
                const SizedBox(width: 16),
                _WorkoutStat(
                  icon: LucideIcons.layers,
                  value: '${session.totalExercises} exercises',
                ),
                const SizedBox(width: 16),
                _WorkoutStat(
                  icon: LucideIcons.barChart2,
                  value: Units.volumeLabel(session.totalVolume),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _WorkoutStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
