import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  final String sessionId;

  const WorkoutSummaryScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(weightUnitProvider); // rebuild on kg/lbs change
    final session = HiveService.getSession(sessionId);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Workout not found')),
      );
    }

    // Get previous session for comparison
    WorkoutSession? previousSession;
    if (session.routineId != null) {
      final routineSessions =
          HiveService.getSessionsByRoutine(session.routineId!);
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMM d • h:mm a')
                          .format(session.startTime),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textTertiary),
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
                      child: _SummaryStatCard(
                        label: 'Duration',
                        value: session.durationFormatted,
                        icon: LucideIcons.clock,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryStatCard(
                        label: 'Volume',
                        value: Units.volumeLabel(session.totalVolume),
                        icon: LucideIcons.barChart2,
                        comparison: previousSession != null
                            ? Units.fromKg(session.totalVolume -
                                previousSession.totalVolume)
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
                      child: _SummaryStatCard(
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
                      child: _SummaryStatCard(
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
                        .where(
                            (e) => e.sets.any((s) => s.isPR))
                        .map((e) => Padding(
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
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                            Text(
                                              '${Units.weightLabel(e.maxWeight)} × ${e.bestSet?.reps ?? 0} reps',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.pr,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
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
                        .where(
                            (e) => e.exercise.id == exercise.exercise.id)
                        .firstOrNull;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ExerciseBreakdownCard(
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

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double? comparison;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.comparison,
  });

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
                Icon(icon, size: 16, color: AppColors.textTertiary),
                if (comparison != null && comparison != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: comparison! > 0
                          ? AppColors.successMuted
                          : AppColors.errorMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${comparison! > 0 ? '+' : ''}${comparison!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: comparison! > 0
                            ? AppColors.increase
                            : AppColors.decrease,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseBreakdownCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final WorkoutExercise? previousExercise;

  const _ExerciseBreakdownCard({
    required this.exercise,
    this.previousExercise,
  });

  /// RPE reads cleaner as a whole number when it is one ("RPE 8", not "8.0").
  String _rpeLabel(double rpe) =>
      rpe % 1 == 0 ? rpe.toStringAsFixed(0) : rpe.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final prev = previousExercise;
    final volumeDiff =
        prev != null ? exercise.totalVolume - prev.totalVolume : null;
    final completedSets =
        exercise.sets.where((s) => s.isCompleted).toList();

    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exercise.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (volumeDiff != null && volumeDiff != 0)
                  Text(
                    '${volumeDiff > 0 ? '+' : ''}${Units.fromKg(volumeDiff).toStringAsFixed(0)} ${Units.label} vol',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: volumeDiff > 0
                              ? AppColors.increase
                              : AppColors.decrease,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...completedSets.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${s.setNumber}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${Units.weightLabel(s.weight)} × ${s.reps} reps',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (s.isPR) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.pr.withAlpha(20),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'PR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pr,
                            ),
                          ),
                        ),
                      ],
                      if (s.rpe != null) ...[
                        const Spacer(),
                        Text(
                          'RPE ${_rpeLabel(s.rpe!)}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
