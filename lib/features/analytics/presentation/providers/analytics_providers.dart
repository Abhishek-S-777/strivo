import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';

class WeeklyStats {
  final int workoutCount;
  final double totalVolume;
  final int totalSets;
  final int prCount;
  final int workoutCountDiff; // vs last week
  final double volumeDiffPercent;
  final String trend; // 'increase', 'decrease', 'stagnant'
  final List<WorkoutSession> sessions;

  const WeeklyStats({
    this.workoutCount = 0,
    this.totalVolume = 0,
    this.totalSets = 0,
    this.prCount = 0,
    this.workoutCountDiff = 0,
    this.volumeDiffPercent = 0,
    this.trend = 'stagnant',
    this.sessions = const [],
  });
}

class ExerciseProgressData {
  final String exerciseName;
  final String exerciseId;
  final List<ExerciseProgressPoint> dataPoints;
  final double currentMax;
  final double previousMax;
  final double allTimeMax;

  const ExerciseProgressData({
    required this.exerciseName,
    required this.exerciseId,
    this.dataPoints = const [],
    this.currentMax = 0,
    this.previousMax = 0,
    this.allTimeMax = 0,
  });
}

class ExerciseProgressPoint {
  final DateTime date;
  final double maxWeight;
  final double totalVolume;
  final int totalReps;
  final int totalSets;

  const ExerciseProgressPoint({
    required this.date,
    required this.maxWeight,
    required this.totalVolume,
    required this.totalReps,
    required this.totalSets,
  });
}

// ── Weekly Stats Provider ──
final weeklyStatsProvider = Provider<WeeklyStats>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  return _calculateWeeklyStats(sessions);
});

WeeklyStats _calculateWeeklyStats(List<WorkoutSession> allSessions) {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDate =
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  final startOfLastWeek = startOfWeekDate.subtract(const Duration(days: 7));

  // Inclusive of Monday 00:00 (matches the insights engine's week boundary)
  // so the first workout of the week is never dropped.
  final thisWeekSessions = allSessions
      .where((s) => s.isCompleted && !s.startTime.isBefore(startOfWeekDate))
      .toList();

  final lastWeekSessions = allSessions
      .where((s) =>
          s.isCompleted &&
          !s.startTime.isBefore(startOfLastWeek) &&
          s.startTime.isBefore(startOfWeekDate))
      .toList();

  final thisWeekVolume =
      thisWeekSessions.fold(0.0, (sum, s) => sum + s.totalVolume);
  final lastWeekVolume =
      lastWeekSessions.fold(0.0, (sum, s) => sum + s.totalVolume);

  final thisWeekSets =
      thisWeekSessions.fold(0, (sum, s) => sum + s.totalCompletedSets);

  final prCount =
      thisWeekSessions.fold(0, (sum, s) => sum + s.prCount);

  double volumeDiffPercent = 0;
  if (lastWeekVolume > 0) {
    volumeDiffPercent =
        ((thisWeekVolume - lastWeekVolume) / lastWeekVolume) * 100;
  }

  String trend = 'stagnant';
  if (volumeDiffPercent > 5) {
    trend = 'increase';
  } else if (volumeDiffPercent < -5) {
    trend = 'decrease';
  }

  return WeeklyStats(
    workoutCount: thisWeekSessions.length,
    totalVolume: thisWeekVolume,
    totalSets: thisWeekSets,
    prCount: prCount,
    workoutCountDiff:
        thisWeekSessions.length - lastWeekSessions.length,
    volumeDiffPercent: volumeDiffPercent,
    trend: trend,
    sessions: thisWeekSessions,
  );
}

// ── Exercise Progress Provider ──
final exerciseProgressProvider =
    Provider.family<ExerciseProgressData, String>((ref, exerciseId) {
  final sessions = ref.watch(workoutSessionsProvider);
  return _calculateExerciseProgress(sessions, exerciseId);
});

ExerciseProgressData _calculateExerciseProgress(
    List<WorkoutSession> allSessions, String exerciseId) {
  final dataPoints = <ExerciseProgressPoint>[];
  String exerciseName = '';
  double allTimeMax = 0;

  // Go through sessions in chronological order
  final sorted = allSessions
      .where((s) => s.isCompleted)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  for (final session in sorted) {
    for (final exercise in session.exercises) {
      if (exercise.exercise.id == exerciseId) {
        exerciseName = exercise.exercise.name;
        final completedSets =
            exercise.sets.where((s) => s.isCompleted && !s.isWarmup);
        if (completedSets.isEmpty) continue;

        double maxWeight = 0;
        double totalVolume = 0;
        int totalReps = 0;

        for (final set in completedSets) {
          if (set.weight > maxWeight) maxWeight = set.weight;
          totalVolume += set.volume;
          totalReps += set.reps;
        }

        if (maxWeight > allTimeMax) allTimeMax = maxWeight;

        dataPoints.add(ExerciseProgressPoint(
          date: session.startTime,
          maxWeight: maxWeight,
          totalVolume: totalVolume,
          totalReps: totalReps,
          totalSets: completedSets.length,
        ));
      }
    }
  }

  return ExerciseProgressData(
    exerciseName: exerciseName,
    exerciseId: exerciseId,
    dataPoints: dataPoints,
    currentMax: dataPoints.isNotEmpty ? dataPoints.last.maxWeight : 0,
    previousMax:
        dataPoints.length > 1 ? dataPoints[dataPoints.length - 2].maxWeight : 0,
    allTimeMax: allTimeMax,
  );
}

// ── Daily Comparison Provider ──
class DailyComparison {
  final String routineName;
  final int currentSets;
  final int previousSets;
  final double currentVolume;
  final double previousVolume;
  final Map<String, ExerciseComparison> exerciseComparisons;

  const DailyComparison({
    required this.routineName,
    required this.currentSets,
    required this.previousSets,
    required this.currentVolume,
    required this.previousVolume,
    required this.exerciseComparisons,
  });

  int get setDiff => currentSets - previousSets;
  double get volumeDiff => currentVolume - previousVolume;
}

class ExerciseComparison {
  final String exerciseName;
  final double currentWeight;
  final double previousWeight;
  final int currentReps;
  final int previousReps;

  const ExerciseComparison({
    required this.exerciseName,
    required this.currentWeight,
    required this.previousWeight,
    required this.currentReps,
    required this.previousReps,
  });

  double get weightDiff => currentWeight - previousWeight;
  int get repDiff => currentReps - previousReps;
}

final dailyComparisonProvider =
    Provider.family<DailyComparison?, String>((ref, sessionId) {
  final sessions = ref.watch(workoutSessionsProvider);
  final currentSession = sessions.firstWhere(
    (s) => s.id == sessionId,
    orElse: () => sessions.first,
  );

  if (currentSession.routineId == null) return null;

  // Find the previous session with same routine
  final routineSessions = sessions
      .where((s) =>
          s.routineId == currentSession.routineId &&
          s.id != sessionId &&
          s.isCompleted)
      .toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  if (routineSessions.isEmpty) return null;

  final previousSession = routineSessions.first;

  final exerciseComparisons = <String, ExerciseComparison>{};

  for (final exercise in currentSession.exercises) {
    final prev = previousSession.exercises
        .where((e) => e.exercise.id == exercise.exercise.id)
        .firstOrNull;
    if (prev != null) {
      exerciseComparisons[exercise.exercise.id] = ExerciseComparison(
        exerciseName: exercise.exercise.name,
        currentWeight: exercise.maxWeight,
        previousWeight: prev.maxWeight,
        currentReps: exercise.sets
            .where((s) => s.isCompleted)
            .fold(0, (sum, s) => sum + s.reps),
        previousReps: prev.sets
            .where((s) => s.isCompleted)
            .fold(0, (sum, s) => sum + s.reps),
      );
    }
  }

  return DailyComparison(
    routineName: currentSession.routineName ?? currentSession.name,
    currentSets: currentSession.totalCompletedSets,
    previousSets: previousSession.totalCompletedSets,
    currentVolume: currentSession.totalVolume,
    previousVolume: previousSession.totalVolume,
    exerciseComparisons: exerciseComparisons,
  );
});

// ── Consistency Heatmap (last 12 weeks, day-level) ──
class ConsistencyData {
  /// 12 weeks (oldest → newest); each is 7 day-levels (Mon→Sun).
  /// Levels: -1 future, 0 rest, 1 light, 2 solid, 3 elite.
  final List<List<int>> weeks;
  final int activeDays;
  final int totalDays;

  const ConsistencyData({
    required this.weeks,
    required this.activeDays,
    required this.totalDays,
  });

  bool get isEmpty => activeDays == 0;
}

final consistencyProvider = Provider<ConsistencyData>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  return _calculateConsistency(sessions);
});

ConsistencyData _calculateConsistency(List<WorkoutSession> sessions) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thisMonday = today.subtract(Duration(days: today.weekday - 1));
  final start = thisMonday.subtract(const Duration(days: 7 * 11));

  final dayVolume = <DateTime, double>{};
  for (final s in sessions.where((s) => s.isCompleted)) {
    final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
    if (d.isBefore(start) || d.isAfter(today)) continue;
    dayVolume[d] = (dayVolume[d] ?? 0) + s.totalVolume;
  }

  final maxVol = dayVolume.values.isEmpty
      ? 0.0
      : dayVolume.values.reduce((a, b) => a > b ? a : b);

  int activeDays = 0;
  final weeks = <List<int>>[];
  for (int w = 0; w < 12; w++) {
    final weekStart = start.add(Duration(days: 7 * w));
    final days = <int>[];
    for (int d = 0; d < 7; d++) {
      final day = weekStart.add(Duration(days: d));
      if (day.isAfter(today)) {
        days.add(-1);
        continue;
      }
      final vol = dayVolume[day] ?? 0;
      int level;
      if (vol <= 0) {
        level = 0;
      } else if (maxVol <= 0) {
        level = 1;
      } else if (vol >= maxVol * 0.66) {
        level = 3;
      } else if (vol >= maxVol * 0.33) {
        level = 2;
      } else {
        level = 1;
      }
      if (level > 0) activeDays++;
      days.add(level);
    }
    weeks.add(days);
  }

  return ConsistencyData(weeks: weeks, activeDays: activeDays, totalDays: 84);
}

// ── All Exercises With History ──
final exercisesWithHistoryProvider = Provider<List<ExerciseProgressData>>((ref) {
  final sessions = ref.watch(workoutSessionsProvider);
  final exerciseIds = <String>{};

  for (final session in sessions) {
    for (final exercise in session.exercises) {
      exerciseIds.add(exercise.exercise.id);
    }
  }

  return exerciseIds
      .map((id) => _calculateExerciseProgress(sessions, id))
      .where((p) => p.dataPoints.isNotEmpty)
      .toList()
    ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
});
