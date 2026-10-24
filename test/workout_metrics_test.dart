import 'package:flutter_test/flutter_test.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/exercise_set.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';

ExerciseSet _set(
  double weight,
  int reps, {
  bool completed = true,
  bool warmup = false,
  bool pr = false,
}) {
  return ExerciseSet(
    id: 's${weight}_$reps${completed}_$warmup',
    setNumber: 1,
    weight: weight,
    reps: reps,
    isCompleted: completed,
    isWarmup: warmup,
    isPR: pr,
  );
}

WorkoutExercise _exercise(List<ExerciseSet> sets) {
  return WorkoutExercise(
    id: 'we',
    exercise: const Exercise(
      id: 'ex_bench',
      name: 'Bench Press',
      primaryMuscle: MuscleGroup.chest,
      equipment: Equipment.barbell,
    ),
    sets: sets,
    order: 0,
  );
}

void main() {
  group('ExerciseSet', () {
    test('volume is weight × reps', () {
      expect(_set(100, 5).volume, 500);
      expect(_set(0, 10).volume, 0);
    });

    test('fromPrevious copies load but resets completion & PR', () {
      final prev = _set(80, 8, pr: true);
      final next = ExerciseSet.fromPrevious(prev, 2);
      expect(next.weight, 80);
      expect(next.reps, 8);
      expect(next.setNumber, 2);
      expect(next.isCompleted, false);
      expect(next.isPR, false);
      expect(next.id, isNot(prev.id));
    });
  });

  group('WorkoutExercise', () {
    test('totalVolume only counts completed, non-warmup sets', () {
      final we = _exercise([
        _set(100, 5), // 500
        _set(100, 5, warmup: true), // excluded (warmup)
        _set(100, 5, completed: false), // excluded (not done)
        _set(60, 10), // 600
      ]);
      expect(we.totalVolume, 1100);
      expect(we.completedSets, 2);
      expect(we.maxWeight, 100);
    });

    test('bestSet is the highest-volume completed working set', () {
      final we = _exercise([
        _set(100, 3), // 300
        _set(80, 8), // 640
      ]);
      expect(we.bestSet?.volume, 640);
    });
  });

  group('WorkoutSession', () {
    final session = WorkoutSession(
      id: 'ws',
      name: 'Push',
      startTime: DateTime(2026, 1, 1, 10),
      endTime: DateTime(2026, 1, 1, 11, 5),
      isCompleted: true,
      exercises: [
        _exercise([_set(100, 5), _set(100, 5, pr: true)]),
        _exercise([_set(50, 10, warmup: true), _set(60, 10)]),
      ],
    );

    test('totalVolume sums across exercises', () {
      // 500 + 500 + 600 = 1600 (warmup excluded)
      expect(session.totalVolume, 1600);
    });

    test('totalCompletedSets excludes warmups', () {
      expect(session.totalCompletedSets, 3);
    });

    test('prCount counts PR sets', () {
      expect(session.prCount, 1);
    });

    test('duration & formatting', () {
      expect(session.duration, const Duration(hours: 1, minutes: 5));
      expect(session.durationFormatted, '1h 5m');
    });

    test('hasData reflects any completed set', () {
      expect(session.hasData, true);
    });

    test('round-trips through toMap/fromMap', () {
      final restored = WorkoutSession.fromMap(session.toMap());
      expect(restored.id, session.id);
      expect(restored.totalVolume, session.totalVolume);
      expect(restored.exercises.length, 2);
      expect(restored.prCount, 1);
    });
  });
}
