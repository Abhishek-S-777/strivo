import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/auth/domain/auth_repository.dart';
import 'package:strivo/features/auth/presentation/providers/auth_providers.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/programs/presentation/providers/program_providers.dart';
import 'package:strivo/features/routines/data/routine_repository_impl.dart';
import 'package:strivo/features/routines/domain/routine_repository.dart';
import 'package:strivo/features/workout/data/session_repository_impl.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';
import 'package:strivo/features/workout/domain/session_repository.dart';
import 'package:strivo/features/workout/presentation/screens/home_screen.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockRoutineRepository extends Mock implements RoutineRepository {}

/// Builds the provider overrides HomeScreen needs to render without Hive,
/// Firebase, or a live sync path. Everything resolves to empty by default;
/// pass [activeProgram] to exercise the "Today's Workout" branch.
List<Override> _overrides({Program? activeProgram}) {
  final session = _MockSessionRepository();
  final routine = _MockRoutineRepository();
  when(session.getAll).thenReturn(<WorkoutSession>[]);
  when(session.getActive).thenReturn(null);
  when(routine.getAll).thenReturn(<Routine>[]);
  return [
    sessionRepositoryProvider.overrideWithValue(session),
    routineRepositoryProvider.overrideWithValue(routine),
    currentUserProvider.overrideWith((ref) => Stream<AuthUser?>.value(null)),
    activeProgramProvider.overrideWithValue(activeProgram),
  ];
}

Program _programWithToday() {
  return Program(
    id: 'p1',
    name: 'PPL',
    durationWeeks: 4,
    days: const [
      ProgramDay(
        id: 'd1',
        name: 'Push',
        exercises: [
          ProgramExercise(
            id: 'pe1',
            exercise: Exercise(
              id: 'e1',
              name: 'Bench Press',
              primaryMuscle: MuscleGroup.chest,
              equipment: Equipment.barbell,
            ),
            weeklyTargets: [SetTarget(sets: 3, repsMin: 8, repsMax: 10)],
          ),
        ],
      ),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  // The Units mirror normally hydrates from Hive on first access; seed it
  // directly so the widget tree can read the unit without a Hive box.
  setUp(() => Units.unit = WeightUnit.kg);

  testWidgets('HomeScreen renders its sections with no data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('STRIVO'), findsOneWidget);
    expect(find.text('Quick Start'), findsOneWidget);
    expect(find.text('Recent Workouts'), findsOneWidget);
    expect(find.text('No workouts yet'), findsOneWidget);
  });

  testWidgets("HomeScreen shows today's workout for the active program", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(activeProgram: _programWithToday()),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Today's Workout"), findsOneWidget);
    expect(find.text('WEEK 1 OF 4'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);
  });
}
