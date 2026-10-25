import 'package:strivo/features/analytics/domain/analytics_models.dart';
import 'package:strivo/features/analytics/domain/one_rep_max.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';

/// Start of the ISO week (Monday 00:00) containing [date].
DateTime weekStart(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Weekly training-consistency streak as of [now].
TrainingStreak calculateStreak(List<WorkoutSession> sessions, DateTime now) {
  final completed = sessions.where((s) => s.isCompleted).toList();
  if (completed.isEmpty) {
    return const TrainingStreak(
      currentStreak: 0,
      longestStreak: 0,
      isActive: false,
    );
  }

  // Unique ISO weeks that have at least one workout.
  final weeksWithWorkout = <DateTime>{
    for (final s in completed) weekStart(s.startTime),
  };

  final sortedWeeks = weeksWithWorkout.toList()
    ..sort((a, b) => b.compareTo(a)); // newest first

  final currentWeek = weekStart(now);
  final isActive =
      sortedWeeks.first == currentWeek ||
      sortedWeeks.first == currentWeek.subtract(const Duration(days: 7));

  // Current consecutive streak, walking backwards.
  var currentStreak = 0;
  var expected = isActive ? sortedWeeks.first : currentWeek;
  for (final week in sortedWeeks) {
    if (week == expected) {
      currentStreak++;
      expected = expected.subtract(const Duration(days: 7));
    } else if (week.isBefore(expected)) {
      break;
    }
  }

  // Longest streak.
  var longestStreak = 0;
  var streak = 1;
  for (var i = 1; i < sortedWeeks.length; i++) {
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

/// Total volume per primary muscle group for the current week (as of [now]).
Map<MuscleGroup, double> calculateMuscleGroupVolume(
  List<WorkoutSession> sessions,
  DateTime now,
) {
  final weekStartDate = weekStart(now);
  final thisWeek = sessions.where(
    (s) => s.isCompleted && !s.startTime.isBefore(weekStartDate),
  );

  final volumes = <MuscleGroup, double>{};
  for (final session in thisWeek) {
    for (final we in session.exercises) {
      final muscle = we.exercise.primaryMuscle;
      volumes[muscle] = (volumes[muscle] ?? 0) + we.totalVolume;
    }
  }
  return volumes;
}

/// Per-week training-load summaries for the last 8 ISO weeks (oldest first).
List<WeeklyLoadSummary> calculateWeeklyLoadHistory(
  List<WorkoutSession> sessions,
  DateTime now,
) {
  final completed = sessions.where((s) => s.isCompleted).toList();
  if (completed.isEmpty) return [];

  final currentWeekStart = weekStart(now);
  final eightWeeksAgo = currentWeekStart.subtract(const Duration(days: 7 * 7));

  final relevant = completed.where(
    (s) => !s.startTime.isBefore(eightWeeksAgo),
  );

  final grouped = <DateTime, List<WorkoutSession>>{};
  for (final s in relevant) {
    grouped.putIfAbsent(weekStart(s.startTime), () => []).add(s);
  }

  final summaries = <WeeklyLoadSummary>[];
  for (var i = 0; i < 8; i++) {
    final ws = currentWeekStart.subtract(Duration(days: 7 * i));
    final weekSessions = grouped[ws] ?? [];

    if (weekSessions.isEmpty) {
      summaries.add(
        WeeklyLoadSummary(
          weekStart: ws,
          totalVolume: 0,
          totalSets: 0,
          totalReps: 0,
          workoutCount: 0,
          avgSessionDuration: Duration.zero,
          muscleGroupDistribution: const {},
          topExerciseByVolume: '',
        ),
      );
      continue;
    }

    double totalVolume = 0;
    var totalSets = 0;
    var totalReps = 0;
    var totalDuration = Duration.zero;
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

    final distribution = <MuscleGroup, double>{};
    if (totalVolume > 0) {
      for (final entry in muscleVolume.entries) {
        distribution[entry.key] = (entry.value / totalVolume) * 100;
      }
    }

    var topExercise = '';
    double topVol = 0;
    for (final entry in exerciseVolumes.entries) {
      if (entry.value > topVol) {
        topVol = entry.value;
        topExercise = entry.key;
      }
    }

    summaries.add(
      WeeklyLoadSummary(
        weekStart: ws,
        totalVolume: totalVolume,
        totalSets: totalSets,
        totalReps: totalReps,
        workoutCount: weekSessions.length,
        avgSessionDuration: Duration(
          seconds: totalDuration.inSeconds ~/ weekSessions.length,
        ),
        muscleGroupDistribution: distribution,
        topExerciseByVolume: topExercise,
      ),
    );
  }

  summaries.sort((a, b) => a.weekStart.compareTo(b.weekStart));
  return summaries;
}

/// Per-exercise strength/volume trends over the recent window (as of [now]).
List<ExerciseTrend> calculateExerciseTrends(
  List<WorkoutSession> sessions,
  DateTime now,
) {
  final completed = sessions.where((s) => s.isCompleted).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  if (completed.isEmpty) return [];

  final fourWeeksAgo = now.subtract(const Duration(days: 28));
  final eightWeeksAgo = now.subtract(const Duration(days: 56));

  // exerciseId → samples of (date, maxWeight, volume, bestReps, name)
  final exerciseData =
      <
        String,
        List<
          ({
            DateTime date,
            double maxWeight,
            double volume,
            int reps,
            String name,
          })
        >
      >{};

  for (final session in completed) {
    for (final we in session.exercises) {
      final completedSets = we.sets
          .where((s) => s.isCompleted && !s.isWarmup)
          .toList();
      if (completedSets.isEmpty) continue;

      double maxW = 0;
      double vol = 0;
      var bestReps = 0;
      double bestWeight = 0;
      for (final s in completedSets) {
        if (s.weight > maxW) maxW = s.weight;
        vol += s.volume;
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
    final recent = data.where((d) => !d.date.isBefore(fourWeeksAgo)).toList();
    final previous = data
        .where(
          (d) =>
              d.date.isBefore(fourWeeksAgo) && !d.date.isBefore(eightWeeksAgo),
        )
        .toList();

    final currentWeight = latest.maxWeight;

    double previousWeight;
    if (previous.isNotEmpty) {
      previousWeight =
          previous.fold<double>(0, (sum, d) => sum + d.maxWeight) /
          previous.length;
    } else if (data.length > 1) {
      previousWeight = data.first.maxWeight;
    } else {
      previousWeight = currentWeight;
    }

    final weightChange = currentWeight - previousWeight;
    final weightChangePercent = previousWeight > 0
        ? (weightChange / previousWeight) * 100
        : 0.0;

    TrendStatus status;
    if (weightChange > 2.5) {
      status = TrendStatus.progressing;
    } else if (weightChange < -2.5) {
      status = TrendStatus.regressing;
    } else {
      status = TrendStatus.stagnant;
    }

    double recentVolAvg = 0;
    double prevVolAvg = 0;
    if (recent.isNotEmpty) {
      recentVolAvg =
          recent.fold<double>(0, (sum, d) => sum + d.volume) / recent.length;
    }
    if (previous.isNotEmpty) {
      prevVolAvg =
          previous.fold<double>(0, (sum, d) => sum + d.volume) /
          previous.length;
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

    trends.add(
      ExerciseTrend(
        exerciseId: entry.key,
        exerciseName: latest.name,
        status: status,
        currentWeight: currentWeight,
        weightChange: weightChange,
        weightChangePercent: weightChangePercent,
        estimated1RM: estimatedOneRepMax(latest.maxWeight, latest.reps),
        volumeTrend: volumeTrend,
        lastPerformed: latest.date,
        sessionCount: data.length,
      ),
    );
  }

  trends.sort((a, b) => b.lastPerformed.compareTo(a.lastPerformed));
  return trends;
}
