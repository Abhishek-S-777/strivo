import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strivo/features/workout/data/session_repository_impl.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/domain/session_repository.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';

/// In-memory [SessionRepository] for testing presentation logic without Hive or
/// Firestore. Records cloud-sync and delete calls so tests can assert on them.
class FakeSessionRepository implements SessionRepository {
  final Map<String, WorkoutSession> store = {};
  final List<String> syncedIds = [];
  final List<String> deletedIds = [];
  WorkoutSession? active;
  final Map<String, Map<String, dynamic>> history = {};

  @override
  List<WorkoutSession> getAll() =>
      store.values.toList()..sort((a, b) => b.startTime.compareTo(a.startTime));

  @override
  WorkoutSession? getById(String id) => store[id];

  @override
  List<WorkoutSession> getByRoutine(String routineId) =>
      getAll().where((s) => s.routineId == routineId && s.isCompleted).toList();

  @override
  WorkoutSession? getLastByRoutine(String routineId) =>
      getByRoutine(routineId).firstOrNull;

  @override
  List<WorkoutSession> getInRange(DateTime start, DateTime end) => getAll()
      .where(
        (s) =>
            s.isCompleted &&
            s.startTime.isAfter(start) &&
            s.startTime.isBefore(end),
      )
      .toList();

  @override
  Future<void> save(WorkoutSession session) async {
    store[session.id] = session;
  }

  @override
  Future<void> delete(String id) async {
    store.remove(id);
    deletedIds.add(id);
  }

  @override
  Future<void> syncToCloud(WorkoutSession session) async {
    syncedIds.add(session.id);
  }

  @override
  WorkoutSession? getActive() => active;

  @override
  Future<void> saveActive(WorkoutSession session) async {
    active = session;
  }

  @override
  Future<void> clearActive() async {
    active = null;
  }

  @override
  Map<String, dynamic>? getHistory(String exerciseId) => history[exerciseId];

  @override
  Future<void> updateHistory(
    String exerciseId,
    Map<String, dynamic> data,
  ) async {
    history[exerciseId] = data;
  }
}

WorkoutSession _session(
  String id, {
  String? routineId,
  bool completed = true,
  DateTime? start,
}) {
  return WorkoutSession(
    id: id,
    name: 'Session $id',
    startTime: start ?? DateTime(2026),
    routineId: routineId,
    isCompleted: completed,
    exercises: const [],
  );
}

void main() {
  late FakeSessionRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeSessionRepository();
    container = ProviderContainer(
      overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  WorkoutSessionsNotifier notifier() =>
      container.read(workoutSessionsProvider.notifier);

  group('WorkoutSessionsNotifier', () {
    test('loads existing sessions from the repository on creation', () {
      repo.store['a'] = _session('a');
      // Re-create the container so the notifier reads the seeded repo.
      final c = ProviderContainer(
        overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      expect(c.read(workoutSessionsProvider).map((s) => s.id), ['a']);
    });

    test('saveSession persists and refreshes state', () async {
      await notifier().saveSession(_session('x'));
      expect(repo.store.containsKey('x'), isTrue);
      expect(container.read(workoutSessionsProvider).map((s) => s.id), ['x']);
    });

    test('deleteSession removes locally and requests cloud delete', () async {
      await notifier().saveSession(_session('x'));
      await notifier().deleteSession('x');
      expect(repo.store.containsKey('x'), isFalse);
      expect(repo.deletedIds, ['x']);
      expect(container.read(workoutSessionsProvider), isEmpty);
    });

    test('getLastSessionForProgramDay filters by program and day', () async {
      final s = _session('p1').copyWith(
        programId: 'prog',
        programDayName: 'Day 1',
      );
      await notifier().saveSession(s);
      final found = notifier().getLastSessionForProgramDay('prog', 'Day 1');
      expect(found?.id, 'p1');
      expect(notifier().getLastSessionForProgramDay('prog', 'Day 2'), isNull);
    });

    test('getSessionsInRange delegates to the repository', () async {
      await notifier().saveSession(
        _session('old', start: DateTime(2025)),
      );
      await notifier().saveSession(
        _session('new', start: DateTime(2026, 6)),
      );
      final inRange = notifier().getSessionsInRange(
        DateTime(2026),
        DateTime(2026, 12, 31),
      );
      expect(inRange.map((s) => s.id), ['new']);
    });
  });
}
