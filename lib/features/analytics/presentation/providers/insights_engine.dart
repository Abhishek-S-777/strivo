import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum InsightType {
  prAchieved,
  strengthIncreasing,
  strengthStagnant,
  strengthDecreasing,
  volumeMilestone,
  consistencyStreak,
  muscleImbalance,
  overtrainingRisk,
  recoverySuggestion,
  newMilestone,
}

enum TrendStatus {
  progressing,
  stagnant,
  regressing,
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════════

@immutable
class TrainingInsight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final int priority;
  final IconData icon;
  final Color color;
  final String? exerciseId;
  final DateTime timestamp;

  const TrainingInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
    required this.color,
    this.exerciseId,
    required this.timestamp,
  });
}

@immutable
class ExerciseTrend {
  final String exerciseId;
  final String exerciseName;
  final TrendStatus status;
  final double currentWeight;
  final double weightChange;
  final double weightChangePercent;
  final double estimated1RM;
  final TrendStatus volumeTrend;
  final DateTime lastPerformed;
  final int sessionCount;

  const ExerciseTrend({
    required this.exerciseId,
    required this.exerciseName,
    required this.status,
    required this.currentWeight,
    required this.weightChange,
    required this.weightChangePercent,
    required this.estimated1RM,
    required this.volumeTrend,
    required this.lastPerformed,
    required this.sessionCount,
  });
}

@immutable
class WeeklyLoadSummary {
  final DateTime weekStart;
  final double totalVolume;
  final int totalSets;
  final int totalReps;
  final int workoutCount;
  final Duration avgSessionDuration;
  final Map<MuscleGroup, double> muscleGroupDistribution;
  final String topExerciseByVolume;

  const WeeklyLoadSummary({
    required this.weekStart,
    required this.totalVolume,
    required this.totalSets,
    required this.totalReps,
    required this.workoutCount,
    required this.avgSessionDuration,
    required this.muscleGroupDistribution,
    required this.topExerciseByVolume,
  });
}

@immutable
class TrainingStreak {
  final int currentStreak;
  final int longestStreak;
  final bool isActive;

  const TrainingStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.isActive,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER: ISO WEEK START (Monday 00:00)
// ═══════════════════════════════════════════════════════════════════════════════

DateTime _weekStart(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

// ── Training Streak ─────────────────────────────────────────────────────────

final trainingStreakProvider = Provider<TrainingStreak>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  return _calculateStreak(sessions);
});

TrainingStreak _calculateStreak(List<WorkoutSession> sessions) {
  final completed =
      sessions.where((s) => s.isCompleted).toList();
  if (completed.isEmpty) {
    return const TrainingStreak(
        currentStreak: 0, longestStreak: 0, isActive: false);
  }

  // Collect unique ISO weeks that have at least one workout
  final weeksWithWorkout = <DateTime>{};
  for (final s in completed) {
    weeksWithWorkout.add(_weekStart(s.startTime));
  }

  final sortedWeeks = weeksWithWorkout.toList()
    ..sort((a, b) => b.compareTo(a)); // newest first

  final currentWeek = _weekStart(DateTime.now());
  final bool isActive = sortedWeeks.first == currentWeek ||
      sortedWeeks.first == currentWeek.subtract(const Duration(days: 7));

  // Count current consecutive streak walking backwards
  int currentStreak = 0;
  DateTime expected = isActive ? sortedWeeks.first : currentWeek;
  for (final week in sortedWeeks) {
    if (week == expected) {
      currentStreak++;
      expected = expected.subtract(const Duration(days: 7));
    } else if (week.isBefore(expected)) {
      break;
    }
  }

  // Count longest streak
  int longestStreak = 0;
  int streak = 1;
  for (int i = 1; i < sortedWeeks.length; i++) {
    final diff = sortedWeeks[i - 1].difference(sortedWeeks[i]).inDays;
    if (diff == 7) {
      streak++;
    } else {
      if (streak > longestStreak) longestStreak = streak;
      streak = 1;
    }
  }
  if (streak > longestStreak) longestStreak = streak;

  return TrainingStreak(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    isActive: isActive,
  );
}

// ── Muscle Group Volume (this week) ─────────────────────────────────────────

final muscleGroupVolumeProvider = Provider<Map<MuscleGroup, double>>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  return _calculateMuscleGroupVolume(sessions);
});

Map<MuscleGroup, double> _calculateMuscleGroupVolume(
    List<WorkoutSession> sessions) {
  final now = DateTime.now();
  final weekStartDate = _weekStart(now);

  final thisWeek = sessions.where((s) =>
      s.isCompleted &&
      !s.startTime.isBefore(weekStartDate));

  final volumes = <MuscleGroup, double>{};
  for (final session in thisWeek) {
    for (final we in session.exercises) {
      final muscle = we.exercise.primaryMuscle;
      volumes[muscle] = (volumes[muscle] ?? 0) + we.totalVolume;
    }
  }
  return volumes;
}

// ── Weekly Load History (last 8 weeks) ──────────────────────────────────────

final weeklyLoadHistoryProvider = Provider<List<WeeklyLoadSummary>>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  return _calculateWeeklyLoadHistory(sessions);
});

List<WeeklyLoadSummary> _calculateWeeklyLoadHistory(
    List<WorkoutSession> sessions) {
  final completed = sessions.where((s) => s.isCompleted).toList();
  if (completed.isEmpty) return [];

  final now = DateTime.now();
  final currentWeekStart = _weekStart(now);
  final eightWeeksAgo =
      currentWeekStart.subtract(const Duration(days: 7 * 7));

  final relevant = completed
      .where((s) => !s.startTime.isBefore(eightWeeksAgo))
      .toList();

  // Group by ISO week
  final grouped = <DateTime, List<WorkoutSession>>{};
  for (final s in relevant) {
    final ws = _weekStart(s.startTime);
    grouped.putIfAbsent(ws, () => []).add(s);
  }

  final summaries = <WeeklyLoadSummary>[];
  for (int i = 0; i < 8; i++) {
    final ws = currentWeekStart.subtract(Duration(days: 7 * i));
    final weekSessions = grouped[ws] ?? [];

    if (weekSessions.isEmpty) {
      summaries.add(WeeklyLoadSummary(
        weekStart: ws,
        totalVolume: 0,
        totalSets: 0,
        totalReps: 0,
        workoutCount: 0,
        avgSessionDuration: Duration.zero,
        muscleGroupDistribution: const {},
        topExerciseByVolume: '',
      ));
      continue;
    }

    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;
    Duration totalDuration = Duration.zero;
    final muscleVolume = <MuscleGroup, double>{};
    final exerciseVolumes = <String, double>{};

    for (final session in weekSessions) {
      totalVolume += session.totalVolume;
      totalSets += session.totalCompletedSets;
      totalDuration += session.duration;

      for (final we in session.exercises) {
        for (final s in we.sets.where((s) => s.isCompleted && !s.isWarmup)) {
          totalReps += s.reps;
        }
        final muscle = we.exercise.primaryMuscle;
        muscleVolume[muscle] = (muscleVolume[muscle] ?? 0) + we.totalVolume;

        exerciseVolumes[we.exercise.name] =
            (exerciseVolumes[we.exercise.name] ?? 0) + we.totalVolume;
      }
    }

    // Convert muscle volume to percentage distribution
    final distribution = <MuscleGroup, double>{};
    if (totalVolume > 0) {
      for (final entry in muscleVolume.entries) {
        distribution[entry.key] = (entry.value / totalVolume) * 100;
      }
    }

    // Top exercise by volume
    String topExercise = '';
    double topVol = 0;
    for (final entry in exerciseVolumes.entries) {
      if (entry.value > topVol) {
        topVol = entry.value;
        topExercise = entry.key;
      }
    }

    summaries.add(WeeklyLoadSummary(
      weekStart: ws,
      totalVolume: totalVolume,
      totalSets: totalSets,
      totalReps: totalReps,
      workoutCount: weekSessions.length,
      avgSessionDuration: weekSessions.isNotEmpty
          ? Duration(
              seconds: totalDuration.inSeconds ~/ weekSessions.length)
          : Duration.zero,
      muscleGroupDistribution: distribution,
      topExerciseByVolume: topExercise,
    ));
  }

  // Oldest first
  summaries.sort((a, b) => a.weekStart.compareTo(b.weekStart));
  return summaries;
}

// ── Exercise Trends ─────────────────────────────────────────────────────────

final exerciseTrendsProvider = Provider<List<ExerciseTrend>>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  return _calculateExerciseTrends(sessions);
});

List<ExerciseTrend> _calculateExerciseTrends(List<WorkoutSession> sessions) {
  final completed = sessions.where((s) => s.isCompleted).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  if (completed.isEmpty) return [];

  final now = DateTime.now();
  final fourWeeksAgo = now.subtract(const Duration(days: 28));
  final eightWeeksAgo = now.subtract(const Duration(days: 56));

  // Collect per-exercise data
  // exerciseId → list of (date, maxWeight, totalVolume)
  final exerciseData =
      <String, List<({DateTime date, double maxWeight, double volume, int reps, String name})>>{};

  for (final session in completed) {
    for (final we in session.exercises) {
      final completedSets =
          we.sets.where((s) => s.isCompleted && !s.isWarmup).toList();
      if (completedSets.isEmpty) continue;

      double maxW = 0;
      double vol = 0;
      int bestReps = 0;
      double bestWeight = 0;
      for (final s in completedSets) {
        if (s.weight > maxW) maxW = s.weight;
        vol += s.volume;
        // Track the set with highest weight for 1RM calc
        if (s.weight > bestWeight ||
            (s.weight == bestWeight && s.reps > bestReps)) {
          bestWeight = s.weight;
          bestReps = s.reps;
        }
      }

      exerciseData.putIfAbsent(we.exercise.id, () => []).add((
        date: session.startTime,
        maxWeight: maxW,
        volume: vol,
        reps: bestReps,
        name: we.exercise.name,
      ));
    }
  }

  final trends = <ExerciseTrend>[];

  for (final entry in exerciseData.entries) {
    final data = entry.value;
    if (data.isEmpty) continue;

    final latest = data.last;
    final lastPerformed = latest.date;
    final sessionCount = data.length;

    // Recent = last 4 weeks, previous = 4-8 weeks ago
    final recent =
        data.where((d) => !d.date.isBefore(fourWeeksAgo)).toList();
    final previous = data
        .where((d) =>
            d.date.isBefore(fourWeeksAgo) &&
            !d.date.isBefore(eightWeeksAgo))
        .toList();

    // Current weight = latest max weight
    final currentWeight = latest.maxWeight;

    // Weight 4 weeks ago = avg max weight in previous period
    double previousWeight = 0;
    if (previous.isNotEmpty) {
      previousWeight =
          previous.fold(0.0, (sum, d) => sum + d.maxWeight) /
              previous.length;
    } else if (data.length > 1) {
      previousWeight = data.first.maxWeight;
    } else {
      previousWeight = currentWeight;
    }

    final weightChange = currentWeight - previousWeight;
    final weightChangePercent =
        previousWeight > 0 ? (weightChange / previousWeight) * 100 : 0.0;

    // Strength trend
    TrendStatus status;
    if (weightChange > 2.5) {
      status = TrendStatus.progressing;
    } else if (weightChange < -2.5) {
      status = TrendStatus.regressing;
    } else {
      status = TrendStatus.stagnant;
    }

    // Volume trend
    double recentVolAvg = 0;
    double prevVolAvg = 0;
    if (recent.isNotEmpty) {
      recentVolAvg =
          recent.fold(0.0, (sum, d) => sum + d.volume) / recent.length;
    }
    if (previous.isNotEmpty) {
      prevVolAvg =
          previous.fold(0.0, (sum, d) => sum + d.volume) / previous.length;
    }
    TrendStatus volumeTrend;
    if (previous.isEmpty) {
      volumeTrend = TrendStatus.stagnant;
    } else if (recentVolAvg > prevVolAvg * 1.05) {
      volumeTrend = TrendStatus.progressing;
    } else if (recentVolAvg < prevVolAvg * 0.95) {
      volumeTrend = TrendStatus.regressing;
    } else {
      volumeTrend = TrendStatus.stagnant;
    }

    // Estimated 1RM via Epley formula: weight × (1 + reps / 30)
    final bestReps = latest.reps;
    final bestWeight = latest.maxWeight;
    final estimated1RM =
        bestReps > 0 ? bestWeight * (1 + bestReps / 30) : bestWeight;

    trends.add(ExerciseTrend(
      exerciseId: entry.key,
      exerciseName: latest.name,
      status: status,
      currentWeight: currentWeight,
      weightChange: weightChange,
      weightChangePercent: weightChangePercent,
      estimated1RM: estimated1RM,
      volumeTrend: volumeTrend,
      lastPerformed: lastPerformed,
      sessionCount: sessionCount,
    ));
  }

  // Sort by most recently performed first
  trends.sort((a, b) => b.lastPerformed.compareTo(a.lastPerformed));
  return trends;
}

// ── Smart Insights ──────────────────────────────────────────────────────────

final insightsProvider = Provider<List<TrainingInsight>>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  final trends = ref.watch(exerciseTrendsProvider);
  final streak = ref.watch(trainingStreakProvider);
  final muscleVolume = ref.watch(muscleGroupVolumeProvider);
  ref.watch(weightUnitProvider); // regenerate insight text on kg/lbs change
  return _generateInsights(sessions, trends, streak, muscleVolume);
});

List<TrainingInsight> _generateInsights(
  List<WorkoutSession> sessions,
  List<ExerciseTrend> trends,
  TrainingStreak streak,
  Map<MuscleGroup, double> muscleVolume,
) {
  final completed = sessions.where((s) => s.isCompleted).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  if (completed.isEmpty) return [];

  final insights = <TrainingInsight>[];
  final now = DateTime.now();

  // ── 1. PR Detection ────────────────────────────────────────────────────
  // Look for PRs in the last 2 weeks
  final twoWeeksAgo = now.subtract(const Duration(days: 14));
  for (final session in completed) {
    if (session.startTime.isBefore(twoWeeksAgo)) break;
    for (final we in session.exercises) {
      final prSets = we.sets.where((s) => s.isPR && s.isCompleted);
      if (prSets.isNotEmpty) {
        final bestPR = prSets.reduce(
            (a, b) => a.weight > b.weight ? a : b);
        insights.add(TrainingInsight(
          id: 'pr_${we.exercise.id}_${session.id}',
          type: InsightType.prAchieved,
          title: '🏆 New PR on ${we.exercise.name}!',
          description:
              'You hit ${Units.weightLabel(bestPR.weight)} × ${bestPR.reps} reps — a new personal record. Keep pushing!',
          priority: 5,
          icon: LucideIcons.trophy,
          color: AppColors.pr,
          exerciseId: we.exercise.id,
          timestamp: session.startTime,
        ));
      }
    }
  }

  // ── 2. Strength Trends ─────────────────────────────────────────────────
  for (final trend in trends) {
    if (trend.sessionCount < 3) continue;

    switch (trend.status) {
      case TrendStatus.progressing:
        insights.add(TrainingInsight(
          id: 'strength_up_${trend.exerciseId}',
          type: InsightType.strengthIncreasing,
          title: '📈 ${trend.exerciseName} is climbing',
          description:
              'Up ${Units.weight(trend.weightChange)} ${Units.label} (${trend.weightChangePercent.toStringAsFixed(0)}%) over 4 weeks. Your programming is working.',
          priority: 3,
          icon: LucideIcons.trendingUp,
          color: AppColors.success,
          exerciseId: trend.exerciseId,
          timestamp: trend.lastPerformed,
        ));
        break;
      case TrendStatus.stagnant:
        insights.add(TrainingInsight(
          id: 'strength_flat_${trend.exerciseId}',
          type: InsightType.strengthStagnant,
          title: '⏸ ${trend.exerciseName} has plateaued',
          description:
              'Weight has been flat for 4+ weeks. Try varying rep ranges or adding intensity techniques.',
          priority: 2,
          icon: LucideIcons.minus,
          color: AppColors.stagnant,
          exerciseId: trend.exerciseId,
          timestamp: trend.lastPerformed,
        ));
        break;
      case TrendStatus.regressing:
        insights.add(TrainingInsight(
          id: 'strength_down_${trend.exerciseId}',
          type: InsightType.strengthDecreasing,
          title: '📉 ${trend.exerciseName} is dropping',
          description:
              'Down ${Units.weight(trend.weightChange.abs())} ${Units.label} over 4 weeks. Check recovery, sleep, and nutrition.',
          priority: 4,
          icon: LucideIcons.trendingDown,
          color: AppColors.error,
          exerciseId: trend.exerciseId,
          timestamp: trend.lastPerformed,
        ));
        break;
    }
  }

  // ── 3. Volume Milestones ───────────────────────────────────────────────
  // Milestones are evaluated in the user's display unit (same round numbers
  // in kg or lbs), so a lbs user celebrates "100,000 lbs", not an odd figure.
  final totalLifetimeVolume =
      completed.fold(0.0, (sum, s) => sum + s.totalVolume);
  final displayTotal = Units.fromKg(totalLifetimeVolume);
  final displayWithoutLast = Units.fromKg(totalLifetimeVolume -
      (completed.isNotEmpty ? completed.first.totalVolume : 0));

  const milestones = [
    (threshold: 1000000.0, label: '1,000,000'),
    (threshold: 500000.0, label: '500,000'),
    (threshold: 250000.0, label: '250,000'),
    (threshold: 100000.0, label: '100,000'),
    (threshold: 50000.0, label: '50,000'),
    (threshold: 25000.0, label: '25,000'),
    (threshold: 10000.0, label: '10,000'),
  ];

  for (final m in milestones) {
    if (displayTotal >= m.threshold) {
      // Only fire when this session is what crossed the threshold.
      if (displayWithoutLast < m.threshold) {
        insights.add(TrainingInsight(
          id: 'volume_milestone_${m.threshold.toInt()}',
          type: InsightType.volumeMilestone,
          title: '🎯 ${m.label} ${Units.label} Total Volume!',
          description:
              'You\'ve lifted a lifetime total of ${m.label} ${Units.label}. That\'s serious dedication.',
          priority: 4,
          icon: LucideIcons.award,
          color: AppColors.primary,
          timestamp: completed.first.startTime,
        ));
      }
      break; // Only show the highest recently-crossed milestone
    }
  }

  // ── 4. Consistency Streak ──────────────────────────────────────────────
  if (streak.currentStreak >= 2) {
    int priority = 2;
    String emoji = '🔥';
    if (streak.currentStreak >= 8) {
      priority = 4;
      emoji = '⚡';
    } else if (streak.currentStreak >= 4) {
      priority = 3;
    }

    insights.add(TrainingInsight(
      id: 'streak_${streak.currentStreak}',
      type: InsightType.consistencyStreak,
      title: '$emoji ${streak.currentStreak}-week streak!',
      description: streak.currentStreak == streak.longestStreak
          ? 'This is your longest streak ever. Don\'t break the chain!'
          : 'Your record is ${streak.longestStreak} weeks. Keep going!',
      priority: priority,
      icon: LucideIcons.flame,
      color: AppColors.warning,
      timestamp: now,
    ));
  }

  // ── 5. Muscle Imbalance ────────────────────────────────────────────────
  if (muscleVolume.length >= 2) {
    final trainedGroups = muscleVolume.entries
        .where((e) =>
            e.key != MuscleGroup.fullBody &&
            e.key != MuscleGroup.cardio &&
            e.key != MuscleGroup.other &&
            e.value > 0)
        .toList();

    if (trainedGroups.length >= 2) {
      trainedGroups.sort((a, b) => b.value.compareTo(a.value));
      final highest = trainedGroups.first;
      final lowest = trainedGroups.last;

      if (lowest.value > 0 && highest.value > lowest.value * 3) {
        insights.add(TrainingInsight(
          id: 'imbalance_${highest.key.name}_${lowest.key.name}',
          type: InsightType.muscleImbalance,
          title: '⚖️ ${highest.key.displayName} vs ${lowest.key.displayName} imbalance',
          description:
              '${highest.key.displayName} volume is ${(highest.value / lowest.value).toStringAsFixed(1)}× higher than ${lowest.key.displayName}. Consider balancing your training.',
          priority: 3,
          icon: LucideIcons.scale,
          color: AppColors.warning,
          timestamp: now,
        ));
      }
    }
  }

  // ── 6. Overtraining Risk ───────────────────────────────────────────────
  // Check if any muscle group was trained 4+ times this week
  final weekStartDate = _weekStart(now);
  final thisWeekSessions = completed
      .where((s) => !s.startTime.isBefore(weekStartDate))
      .toList();

  final weeklyMuscleFrequency = <MuscleGroup, int>{};
  for (final session in thisWeekSessions) {
    final musclesHit = <MuscleGroup>{};
    for (final we in session.exercises) {
      musclesHit.add(we.exercise.primaryMuscle);
    }
    for (final m in musclesHit) {
      weeklyMuscleFrequency[m] = (weeklyMuscleFrequency[m] ?? 0) + 1;
    }
  }

  for (final entry in weeklyMuscleFrequency.entries) {
    if (entry.value >= 4 &&
        entry.key != MuscleGroup.core &&
        entry.key != MuscleGroup.fullBody &&
        entry.key != MuscleGroup.cardio) {
      insights.add(TrainingInsight(
        id: 'overtrain_${entry.key.name}',
        type: InsightType.overtrainingRisk,
        title: '⚠️ ${entry.key.displayName} hit ${entry.value}× this week',
        description:
            'Training the same muscle ${entry.value} times in one week may hinder recovery. Consider a rest day.',
        priority: 4,
        icon: LucideIcons.alertTriangle,
        color: AppColors.error,
        timestamp: now,
      ));
    }
  }

  // ── 7. Recovery Suggestion ─────────────────────────────────────────────
  if (completed.isNotEmpty) {
    final daysSinceLast =
        now.difference(completed.first.startTime).inDays;
    if (daysSinceLast >= 5) {
      insights.add(TrainingInsight(
        id: 'recovery_$daysSinceLast',
        type: InsightType.recoverySuggestion,
        title: '💪 Time to get back at it',
        description:
            'It\'s been $daysSinceLast days since your last workout. A light session can help maintain your gains.',
        priority: 3,
        icon: LucideIcons.heartPulse,
        color: AppColors.info,
        timestamp: now,
      ));
    }
  }

  // ── Sort & Cap ─────────────────────────────────────────────────────────
  insights.sort((a, b) {
    final priorityCmp = b.priority.compareTo(a.priority);
    if (priorityCmp != 0) return priorityCmp;
    return b.timestamp.compareTo(a.timestamp);
  });

  return insights.take(10).toList();
}
