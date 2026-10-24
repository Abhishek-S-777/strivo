import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strivo/features/workout/data/exercise_repository_impl.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/exercise_repository.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';

/// In-memory [ExerciseRepository] for testing the library notifier.
class FakeExerciseRepository implements ExerciseRepository {
  final List<Exercise> store = [];
  final List<String> syncedCustomIds = [];

  @override
  List<Exercise> getAll() =>
      [...store]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<void> save(Exercise exercise) async {
    store
      ..removeWhere((e) => e.id == exercise.id)
      ..add(exercise);
    if (exercise.isCustom) syncedCustomIds.add(exercise.id);
  }
}

Exercise _ex(
  String id,
  String name, {
  MuscleGroup muscle = MuscleGroup.chest,
  bool custom = false,
}) {
  return Exercise(
    id: id,
    name: name,
    primaryMuscle: muscle,
    equipment: Equipment.barbell,
    isCustom: custom,
  );
}

void main() {
  late FakeExerciseRepository repo;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [exerciseRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => repo = FakeExerciseRepository());

  group('ExerciseLibraryNotifier', () {
    test('seeds state from the repository, sorted by name', () {
      repo.store.addAll([_ex('b', 'Bench'), _ex('a', 'Ab Wheel')]);
      final c = makeContainer();
      expect(
        c.read(exerciseLibraryProvider).map((e) => e.name),
        ['Ab Wheel', 'Bench'],
      );
    });

    test('addExercise persists and refreshes state', () async {
      final c = makeContainer();
      await c
          .read(exerciseLibraryProvider.notifier)
          .addExercise(_ex('a', 'Ab Wheel'));
      expect(c.read(exerciseLibraryProvider).map((e) => e.id), ['a']);
    });

    test('searchExercises matches name case-insensitively', () {
      repo.store.addAll([_ex('a', 'Bench Press'), _ex('b', 'Squat')]);
      final c = makeContainer();
      final notifier = c.read(exerciseLibraryProvider.notifier);
      expect(notifier.searchExercises('bench').map((e) => e.id), ['a']);
      expect(notifier.searchExercises('').length, 2);
    });

    test('filterByMuscle returns only matching primary muscle', () {
      repo.store.addAll([
        _ex('a', 'Bench'),
        _ex('b', 'Squat', muscle: MuscleGroup.legs),
      ]);
      final c = makeContainer();
      final notifier = c.read(exerciseLibraryProvider.notifier);
      expect(notifier.filterByMuscle(MuscleGroup.legs).map((e) => e.id), ['b']);
    });

    test('resolveByIds skips unknown ids and preserves order', () {
      repo.store.addAll([_ex('a', 'A'), _ex('b', 'B')]);
      final c = makeContainer();
      final notifier = c.read(exerciseLibraryProvider.notifier);
      expect(
        notifier.resolveByIds(['b', 'missing', 'a']).map((e) => e.id),
        ['b', 'a'],
      );
    });
  });
}
