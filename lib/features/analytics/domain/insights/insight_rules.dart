import 'package:strivo/features/analytics/domain/analytics_calculations.dart';
import 'package:strivo/features/analytics/domain/analytics_models.dart';
import 'package:strivo/features/analytics/domain/insights/insight_rule.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';

/// Celebrates personal records set in the last two weeks.
class PersonalRecordRule implements InsightRule {
  const PersonalRecordRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final twoWeeksAgo = context.now.subtract(const Duration(days: 14));
    for (final session in context.completed) {
      if (session.startTime.isBefore(twoWeeksAgo)) break;
      for (final we in session.exercises) {
        final prSets = we.sets.where((s) => s.isPR && s.isCompleted);
        if (prSets.isEmpty) continue;
        final bestPR = prSets.reduce((a, b) => a.weight > b.weight ? a : b);
        insights.add(
          Insight(
            id: 'pr_${we.exercise.id}_${session.id}',
            type: InsightType.prAchieved,
            title: 'New PR on ${we.exercise.name}',
            description:
                'You hit ${context.formatter.weightLabel(bestPR.weight)} '
                '× ${bestPR.reps} reps — a new personal record. Keep pushing!',
            priority: 5,
            exerciseId: we.exercise.id,
            timestamp: session.startTime,
          ),
        );
      }
    }
    return insights;
  }
}

/// Surfaces climbing, plateaued, or dropping lifts from the trend data.
class StrengthTrendRule implements InsightRule {
  const StrengthTrendRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final fmt = context.formatter;
    final insights = <Insight>[];
    for (final trend in context.trends) {
      if (trend.sessionCount < 3) continue;
      switch (trend.status) {
        case TrendStatus.progressing:
          insights.add(
            Insight(
              id: 'strength_up_${trend.exerciseId}',
              type: InsightType.strengthIncreasing,
              title: '${trend.exerciseName} is climbing',
              description:
                  'Up ${fmt.weight(trend.weightChange)} ${fmt.unitLabel} '
                  '(${trend.weightChangePercent.toStringAsFixed(0)}%) over 4 '
                  'weeks. Your programming is working.',
              priority: 3,
              exerciseId: trend.exerciseId,
              timestamp: trend.lastPerformed,
            ),
          );
        case TrendStatus.stagnant:
          insights.add(
            Insight(
              id: 'strength_flat_${trend.exerciseId}',
              type: InsightType.strengthStagnant,
              title: '${trend.exerciseName} has plateaued',
              description:
                  'Weight has been flat for 4+ weeks. Try varying rep ranges '
                  'or adding intensity techniques.',
              priority: 2,
              exerciseId: trend.exerciseId,
              timestamp: trend.lastPerformed,
            ),
          );
        case TrendStatus.regressing:
          insights.add(
            Insight(
              id: 'strength_down_${trend.exerciseId}',
              type: InsightType.strengthDecreasing,
              title: '${trend.exerciseName} is dropping',
              description:
                  'Down ${fmt.weight(trend.weightChange.abs())} ${fmt.unitLabel} '
                  'over 4 weeks. Check recovery, sleep, and nutrition.',
              priority: 4,
              exerciseId: trend.exerciseId,
              timestamp: trend.lastPerformed,
            ),
          );
      }
    }
    return insights;
  }
}

/// Fires when lifetime volume crosses a round milestone (in the display unit).
class VolumeMilestoneRule implements InsightRule {
  const VolumeMilestoneRule();

  static const List<({double threshold, String label})> _milestones = [
    (threshold: 1000000, label: '1,000,000'),
    (threshold: 500000, label: '500,000'),
    (threshold: 250000, label: '250,000'),
    (threshold: 100000, label: '100,000'),
    (threshold: 50000, label: '50,000'),
    (threshold: 25000, label: '25,000'),
    (threshold: 10000, label: '10,000'),
  ];

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.completed.isEmpty) return const [];
    final fmt = context.formatter;
    final totalKg = context.completed.fold<double>(
      0,
      (sum, s) => sum + s.totalVolume,
    );
    final displayTotal = fmt.fromKg(totalKg);
    // completed is newest-first, so `first` is the session that may have just
    // crossed the threshold.
    final displayWithoutLast = fmt.fromKg(
      totalKg - context.completed.first.totalVolume,
    );

    for (final m in _milestones) {
      if (displayTotal >= m.threshold) {
        if (displayWithoutLast < m.threshold) {
          return [
            Insight(
              id: 'volume_milestone_${m.threshold.toInt()}',
              type: InsightType.volumeMilestone,
              title: '${m.label} ${fmt.unitLabel} total volume',
              description:
                  "You've lifted a lifetime total of ${m.label} "
                  "${fmt.unitLabel}. That's serious dedication.",
              priority: 4,
              timestamp: context.completed.first.startTime,
            ),
          ];
        }
        break; // Only the highest recently-crossed milestone.
      }
    }
    return const [];
  }
}

/// Rewards an active weekly training streak.
class ConsistencyStreakRule implements InsightRule {
  const ConsistencyStreakRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final streak = context.streak;
    if (streak.currentStreak < 2) return const [];

    var priority = 2;
    if (streak.currentStreak >= 8) {
      priority = 4;
    } else if (streak.currentStreak >= 4) {
      priority = 3;
    }

    return [
      Insight(
        id: 'streak_${streak.currentStreak}',
        type: InsightType.consistencyStreak,
        title: '${streak.currentStreak}-week streak',
        description: streak.currentStreak == streak.longestStreak
            ? "This is your longest streak ever. Don't break the chain!"
            : 'Your record is ${streak.longestStreak} weeks. Keep going!',
        priority: priority,
        timestamp: context.now,
      ),
    ];
  }
}

/// Flags a large volume imbalance between the most- and least-trained groups.
class MuscleImbalanceRule implements InsightRule {
  const MuscleImbalanceRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final muscleVolume = context.muscleVolume;
    if (muscleVolume.length < 2) return const [];

    final trainedGroups = muscleVolume.entries
        .where(
          (e) =>
              e.key != MuscleGroup.fullBody &&
              e.key != MuscleGroup.cardio &&
              e.key != MuscleGroup.other &&
              e.value > 0,
        )
        .toList();
    if (trainedGroups.length < 2) return const [];

    trainedGroups.sort((a, b) => b.value.compareTo(a.value));
    final highest = trainedGroups.first;
    final lowest = trainedGroups.last;
    if (lowest.value <= 0 || highest.value <= lowest.value * 3) return const [];

    final ratio = (highest.value / lowest.value).toStringAsFixed(1);
    return [
      Insight(
        id: 'imbalance_${highest.key.name}_${lowest.key.name}',
        type: InsightType.muscleImbalance,
        title:
            '${highest.key.displayName} vs ${lowest.key.displayName} imbalance',
        description:
            '${highest.key.displayName} volume is $ratio× higher than '
            '${lowest.key.displayName}. Consider balancing your training.',
        priority: 3,
        timestamp: context.now,
      ),
    ];
  }
}

/// Warns when a muscle group is trained four or more times in the week.
class OvertrainingRule implements InsightRule {
  const OvertrainingRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final weekStartDate = weekStart(context.now);
    final thisWeek = context.completed.where(
      (s) => !s.startTime.isBefore(weekStartDate),
    );

    final frequency = <MuscleGroup, int>{};
    for (final session in thisWeek) {
      final musclesHit = <MuscleGroup>{
        for (final we in session.exercises) we.exercise.primaryMuscle,
      };
      for (final m in musclesHit) {
        frequency[m] = (frequency[m] ?? 0) + 1;
      }
    }

    final insights = <Insight>[];
    for (final entry in frequency.entries) {
      if (entry.value >= 4 &&
          entry.key != MuscleGroup.core &&
          entry.key != MuscleGroup.fullBody &&
          entry.key != MuscleGroup.cardio) {
        insights.add(
          Insight(
            id: 'overtrain_${entry.key.name}',
            type: InsightType.overtrainingRisk,
            title: '${entry.key.displayName} hit ${entry.value}× this week',
            description:
                'Training the same muscle ${entry.value} times in one week may '
                'hinder recovery. Consider a rest day.',
            priority: 4,
            timestamp: context.now,
          ),
        );
      }
    }
    return insights;
  }
}

/// Nudges the lifter back after a long lay-off.
class RecoveryRule implements InsightRule {
  const RecoveryRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    if (context.completed.isEmpty) return const [];
    final daysSinceLast = context.now
        .difference(context.completed.first.startTime)
        .inDays;
    if (daysSinceLast < 5) return const [];

    return [
      Insight(
        id: 'recovery_$daysSinceLast',
        type: InsightType.recoverySuggestion,
        title: 'Time to get back at it',
        description:
            "It's been $daysSinceLast days since your last workout. A light "
            'session can help maintain your gains.',
        priority: 3,
        timestamp: context.now,
      ),
    ];
  }
}
