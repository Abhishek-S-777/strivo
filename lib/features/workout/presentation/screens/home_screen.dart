import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/features/analytics/presentation/providers/insights_engine.dart';
import 'package:strivo/features/programs/presentation/providers/program_providers.dart';
import 'package:strivo/features/routines/data/routine_repository_impl.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/features/workout/presentation/widgets/home/home_header.dart';
import 'package:strivo/features/workout/presentation/widgets/home/home_routine_card.dart';
import 'package:strivo/features/workout/presentation/widgets/home/next_routine_card.dart';
import 'package:strivo/features/workout/presentation/widgets/home/quick_start_button.dart';
import 'package:strivo/features/workout/presentation/widgets/home/recent_workouts_section.dart';
import 'package:strivo/features/workout/presentation/widgets/home/today_program_card.dart';
import 'package:strivo/shared/widgets/volume_hero_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final routines = ref.read(routineRepositoryProvider).getAll();
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final weeklyLoad = ref.watch(weeklyLoadHistoryProvider);
    ref.watch(weightUnitProvider); // rebuild when kg/lbs preference changes
    final activeProgram = ref.watch(activeProgramProvider);
    final showProgram =
        activeProgram != null &&
        !activeProgram.isComplete &&
        activeProgram.currentDay != null;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const HomeHeader(),

            // ── Weekly Volume Hero ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: VolumeHeroCard(
                  label: 'Volume This Week',
                  volumeKg: weeklyStats.totalVolume,
                  diffPercent: weeklyStats.volumeDiffPercent,
                  sparkline: weeklyLoad.map((w) => w.totalVolume).toList(),
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
                      TodayProgramCard(
                        program: activeProgram,
                        hasActiveWorkout: activeWorkout != null,
                        onStart: () {
                          if (activeWorkout != null) {
                            unawaited(context.push('/workout/active'));
                          } else {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .startProgramDay(activeProgram);
                            unawaited(context.push('/workout/active'));
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
                      NextRoutineCard(
                        routine: routines.first,
                        hasActiveWorkout: activeWorkout != null,
                        onStart: () {
                          if (activeWorkout != null) {
                            unawaited(context.push('/workout/active'));
                          } else {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .startWorkout(routine: routines.first);
                            unawaited(context.push('/workout/active'));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // ── Quick Start ──
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
                    QuickStartButton(
                      onTap: () {
                        if (activeWorkout != null) {
                          unawaited(context.push('/workout/active'));
                        } else {
                          ref
                              .read(activeWorkoutProvider.notifier)
                              .startWorkout();
                          unawaited(context.push('/workout/active'));
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
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      return HomeRoutineCard(
                        routine: routines[index],
                        onTap: () {
                          if (activeWorkout != null) {
                            _showActiveWorkoutDialog(context);
                          } else {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .startWorkout(routine: routines[index]);
                            unawaited(context.push('/workout/active'));
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],

            const RecentWorkoutsSection(),
          ],
        ),
      ),
    );
  }

  void _showActiveWorkoutDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Active Workout'),
          content: const Text(
            'You have an active workout in progress. Would you like to continue it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(context.push('/workout/active'));
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
