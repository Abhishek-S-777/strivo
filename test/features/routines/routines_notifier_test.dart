import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strivo/features/routines/data/routine_repository_impl.dart';
import 'package:strivo/features/routines/domain/routine_repository.dart';
import 'package:strivo/features/routines/presentation/providers/routine_providers.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';

/// In-memory [RoutineRepository] for testing the routines notifier.
class FakeRoutineRepository implements RoutineRepository {
  final Map<String, Routine> store = {};
  final List<String> deletedIds = [];

  @override
  List<Routine> getAll() =>
      store.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Routine? getById(String id) => store[id];

  @override
  Future<void> save(Routine routine) async {
    store[routine.id] = routine;
  }

  @override
  Future<void> delete(String id) async {
    store.remove(id);
    deletedIds.add(id);
  }
}

Routine _routine(String id, {DateTime? updatedAt}) {
  return Routine(
    id: id,
    name: 'Routine $id',
    exercises: const [],
    createdAt: DateTime(2026),
    updatedAt: updatedAt ?? DateTime(2026),
  );
}

void main() {
  late FakeRoutineRepository repo;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [routineRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => repo = FakeRoutineRepository());

  group('RoutinesNotifier', () {
    test('seeds state from the repository, newest first', () {
      repo.store['old'] = _routine('old', updatedAt: DateTime(2026));
      repo.store['new'] = _routine('new', updatedAt: DateTime(2026, 6));
      final c = makeContainer();
      expect(c.read(routinesProvider).map((r) => r.id), ['new', 'old']);
    });

    test('saveRoutine persists and refreshes state', () async {
      final c = makeContainer();
      await c.read(routinesProvider.notifier).saveRoutine(_routine('x'));
      expect(repo.store.containsKey('x'), isTrue);
      expect(c.read(routinesProvider).map((r) => r.id), ['x']);
    });

    test('deleteRoutine removes locally and requests cloud delete', () async {
      final c = makeContainer();
      final notifier = c.read(routinesProvider.notifier);
      await notifier.saveRoutine(_routine('x'));
      await notifier.deleteRoutine('x');
      expect(repo.store.containsKey('x'), isFalse);
      expect(repo.deletedIds, ['x']);
      expect(c.read(routinesProvider), isEmpty);
    });
  });
}
