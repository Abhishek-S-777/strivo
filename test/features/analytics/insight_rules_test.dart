import 'package:flutter_test/flutter_test.dart';
import 'package:strivo/features/analytics/domain/analytics_models.dart';
import 'package:strivo/features/analytics/domain/insights/insight_generator.dart';
import 'package:strivo/features/analytics/domain/insights/insight_rule.dart';
import 'package:strivo/features/analytics/domain/insights/insight_rules.dart';
import 'package:strivo/features/analytics/domain/weight_formatter.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/exercise_set.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';

class _Fmt implements WeightFormatter {
  const _Fmt();
  @override
  String get unitLabel => 'kg';
  @override
  double fromKg(double kg) => kg;
  @override
  String weight(double kg) => kg.toStringAsFixed(0);
  @override
  String weightLabel(double kg) => '${kg.toStringAsFixed(0)} kg';
}

final _now = DateTime(2026, 1, 15); // a Thursday

InsightContext _ctx({
  List<WorkoutSession> completed = const [],
  List<ExerciseTrend> trends = const [],
  TrainingStreak streak = const TrainingStreak(
    currentStreak: 0,
    longestStreak: 0,
    isActive: false,
  ),
  Map<MuscleGroup, double> muscleVolume = const {},
  DateTime? now,
}) {
  return InsightContext(
    completed: completed,
    trends: trends,
    streak: streak,
    muscleVolume: muscleVolume,
    now: now ?? _now,
    formatter: const _Fmt(),
  );
}

Exercise _ex(String id, {MuscleGroup muscle = MuscleGroup.chest}) {
  return Exercise(
    id: id,
    name: id,
    primaryMuscle: muscle,
    equipment: Equipment.barbell,
  );
}

ExerciseSet _set({double weight = 100, int reps = 5, bool pr = false}) {
  return ExerciseSet(
    id: 's$weight$reps$pr',
    setNumber: 1,
    weight: weight,
    reps: reps,
    isCompleted: true,
    isPR: pr,
  );
}

WorkoutSession _session(
  String id,
  DateTime start,
  List<WorkoutExercise> exercises,
) {
  return WorkoutSession(
    id: id,
    name: id,
    startTime: start,
    isCompleted: true,
    exercises: exercises,
  );
}

WorkoutExercise _we(Exercise exercise, List<ExerciseSet> sets) {
  return WorkoutExercise(
    id: 'we_${exercise.id}',
    exercise: exercise,
    sets: sets,
    order: 0,
  );
}

ExerciseTrend _trend({
  required TrendStatus status,
  int sessionCount = 3,
  double weightChange = 5,
}) {
  return ExerciseTrend(
    exerciseId: 'ex1',
    exerciseName: 'Bench',
    status: status,
    currentWeight: 100,
    weightChange: weightChange,
    weightChangePercent: 5,
    estimated1RM: 110,
    volumeTrend: TrendStatus.stagnant,
    lastPerformed: _now,
    sessionCount: sessionCount,
  );
}

void main() {
  group('PersonalRecordRule', () {
    const rule = PersonalRecordRule();

    test('fires for a PR set within the last two weeks', () {
      final session = _session('s1', _now.subtract(const Duration(days: 3)), [
        _we(_ex('ex_bench'), [_set(weight: 120, reps: 3, pr: true)]),
      ]);
      final result = rule.evaluate(_ctx(completed: [session]));
      expect(result, hasLength(1));
      expect(result.first.type, InsightType.prAchieved);
      expect(result.first.title, contains('ex_bench'));
      expect(result.first.description, contains('120 kg'));
    });

    test('ignores PRs older than two weeks', () {
      final session = _session('s1', _now.subtract(const Duration(days: 20)), [
        _we(_ex('ex_bench'), [_set(pr: true)]),
      ]);
      expect(rule.evaluate(_ctx(completed: [session])), isEmpty);
    });
  });

  group('StrengthTrendRule', () {
    const rule = StrengthTrendRule();

    test('maps each trend status to the matching insight', () {
      expect(
        rule
            .evaluate(_ctx(trends: [_trend(status: TrendStatus.progressing)]))
            .single
            .type,
        InsightType.strengthIncreasing,
      );
      expect(
        rule
            .evaluate(_ctx(trends: [_trend(status: TrendStatus.stagnant)]))
            .single
            .type,
        InsightType.strengthStagnant,
      );
      expect(
        rule
            .evaluate(_ctx(trends: [_trend(status: TrendStatus.regressing)]))
            .single
            .type,
        InsightType.strengthDecreasing,
      );
    });

    test('skips exercises with fewer than three sessions', () {
      final trends = [_trend(status: TrendStatus.progressing, sessionCount: 2)];
      expect(rule.evaluate(_ctx(trends: trends)), isEmpty);
    });
  });

  group('VolumeMilestoneRule', () {
    const rule = VolumeMilestoneRule();

    test('fires when the latest session crosses a milestone', () {
      final newest = _session('new', _now, [
        _we(_ex('ex_a'), [_set(weight: 200, reps: 10)]), // 2000
      ]);
      final older = _session('old', _now.subtract(const Duration(days: 5)), [
        _we(_ex('ex_a'), [_set(weight: 900, reps: 10)]), // 9000
      ]);
      // newest-first; total 11000 crosses 10,000, prior total 9000 did not.
      final result = rule.evaluate(_ctx(completed: [newest, older]));
      expect(result, hasLength(1));
      expect(result.first.type, InsightType.volumeMilestone);
      expect(result.first.title, contains('10,000'));
    });

    test('does not fire below the first milestone', () {
      final s = _session('s', _now, [
        _we(_ex('ex_a'), [_set(reps: 10)]), // 100 x 10 = 1000
      ]);
      expect(rule.evaluate(_ctx(completed: [s])), isEmpty);
    });
  });

  group('ConsistencyStreakRule', () {
    const rule = ConsistencyStreakRule();

    test('fires with escalating priority for longer streaks', () {
      final four = rule
          .evaluate(
            _ctx(
              streak: const TrainingStreak(
                currentStreak: 4,
                longestStreak: 6,
                isActive: true,
              ),
            ),
          )
          .single;
      expect(four.type, InsightType.consistencyStreak);
      expect(four.priority, 3);
    });

    test('stays quiet below a two-week streak', () {
      const streak = TrainingStreak(
        currentStreak: 1,
        longestStreak: 3,
        isActive: true,
      );
      expect(rule.evaluate(_ctx(streak: streak)), isEmpty);
    });
  });

  group('MuscleImbalanceRule', () {
    const rule = MuscleImbalanceRule();

    test('fires when one group exceeds another by more than 3x', () {
      final result = rule.evaluate(
        _ctx(muscleVolume: {MuscleGroup.chest: 1000, MuscleGroup.back: 100}),
      );
      expect(result.single.type, InsightType.muscleImbalance);
      expect(result.single.description, contains('10.0'));
    });

    test('stays quiet when groups are balanced', () {
      final result = rule.evaluate(
        _ctx(muscleVolume: {MuscleGroup.chest: 100, MuscleGroup.back: 90}),
      );
      expect(result, isEmpty);
    });
  });

  group('OvertrainingRule', () {
    const rule = OvertrainingRule();

    test('fires when a muscle is trained 4+ times this week', () {
      final days = [12, 13, 14, 15]; // all in the week of _now (Mon 12th)
      final completed = [
        for (final d in days)
          _session('s$d', DateTime(2026, 1, d), [
            _we(_ex('ex_$d'), [_set()]),
          ]),
      ];
      final result = rule.evaluate(_ctx(completed: completed));
      expect(result.single.type, InsightType.overtrainingRisk);
      expect(result.single.title, contains('4'));
    });

    test('stays quiet below 4 sessions for a muscle', () {
      final completed = [
        _session('s1', DateTime(2026, 1, 13), [
          _we(_ex('ex_a'), [_set()]),
        ]),
        _session('s2', DateTime(2026, 1, 14), [
          _we(_ex('ex_b'), [_set()]),
        ]),
      ];
      expect(rule.evaluate(_ctx(completed: completed)), isEmpty);
    });
  });

  group('RecoveryRule', () {
    const rule = RecoveryRule();

    test('fires after 5+ days since the last workout', () {
      final s = _session('s', _now.subtract(const Duration(days: 6)), [
        _we(_ex('ex_a'), [_set()]),
      ]);
      expect(
        rule.evaluate(_ctx(completed: [s])).single.type,
        InsightType.recoverySuggestion,
      );
    });

    test('stays quiet within the recovery window', () {
      final s = _session('s', _now.subtract(const Duration(days: 2)), [
        _we(_ex('ex_a'), [_set()]),
      ]);
      expect(rule.evaluate(_ctx(completed: [s])), isEmpty);
    });
  });

  group('generateInsights', () {
    test('returns nothing when there are no completed sessions', () {
      expect(generateInsights(_ctx()), isEmpty);
    });

    test('sorts by priority and caps at ten', () {
      final session = _session('s1', _now.subtract(const Duration(days: 1)), [
        _we(_ex('ex_bench'), [_set(weight: 120, reps: 3, pr: true)]),
      ]);
      final result = generateInsights(
        _ctx(
          completed: [session],
          streak: const TrainingStreak(
            currentStreak: 4,
            longestStreak: 4,
            isActive: true,
          ),
        ),
      );
      expect(result.length, lessThanOrEqualTo(10));
      // PR (priority 5) outranks the streak (priority 3).
      expect(result.first.type, InsightType.prAchieved);
    });
  });
}
