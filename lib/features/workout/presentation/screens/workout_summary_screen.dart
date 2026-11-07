import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/data/session_repository_impl.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/presentation/widgets/summary/exercise_breakdown_card.dart';
import 'package:strivo/features/workout/presentation/widgets/summary/summary_stat_card.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(weightUnitProvider); // rebuild on kg/lbs change
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final session = sessionRepo.getById(sessionId);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Workout not found')),
      );
    }

    // Get previous session for comparison
    WorkoutSession? previousSession;
    if (session.routineId != null) {
      final routineSessions = sessionRepo.getByRoutine(session.routineId!);
      if (routineSessions.length > 1) {
        previousSession = routineSessions[1]; // Second most recent
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    // Celebration icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        session.prCount > 0
                            ? LucideIcons.trophy
                            : LucideIcons.check,
                        size: 32,
                        color: session.prCount > 0
                            ? AppColors.pr
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      session.prCount > 0
                          ? 'New Records! 🔥'
                          : 'Workout Complete!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'EEEE, MMM d • h:mm a',
                      ).format(session.startTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats Grid ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: SummaryStatCard(
                        label: 'Duration',
                        value: session.durationFormatted,
                        icon: LucideIcons.clock,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryStatCard(
                        label: 'Volume',
                        value: Units.volumeLabel(session.totalVolume),
                        icon: LucideIcons.barChart2,
                        comparison: previousSession != null
                            ? Units.fromKg(
                                session.totalVolume -
                                    previousSession.totalVolume,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: SummaryStatCard(
                        label: 'Sets',
                        value: '${session.totalCompletedSets}',
                        icon: LucideIcons.layers,
                        comparison: previousSession != null
                            ? (session.totalCompletedSets -
                                      previousSession.totalCompletedSets)
                                  .toDouble()
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryStatCard(
                        label: 'Exercises',
                        value: '${session.totalExercises}',
                        icon: LucideIcons.dumbbell,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── PRs Section ──
            if (session.prCount > 0) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Personal Records 🏆',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    session.exercises
                        .where((e) => e.sets.any((s) => s.isPR))
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: StrivoCard(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.pr.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        LucideIcons.trophy,
                                        size: 18,
                                        color: AppColors.pr,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.exercise.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),
                                          Text(
                                            '${Units.weightLabel(e.maxWeight)} × ${e.bestSet?.reps ?? 0} reps',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
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
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],

            // ── Exercise Breakdown ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Exercise Breakdown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final exercise = session.exercises[index];
                    // Find previous exercise for comparison
                    final prevExercise = previousSession?.exercises
                        .where((e) => e.exercise.id == exercise.exercise.id)
                        .firstOrNull;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ExerciseBreakdownCard(
                        exercise: exercise,
                        previousExercise: prevExercise,
                      ),
                    );
                  },
                  childCount: session.exercises.length,
                ),
              ),
            ),

            // ── Done Button ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
