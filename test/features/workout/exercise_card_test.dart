import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/exercise_set.dart';
import 'package:strivo/features/workout/domain/entities/workout_exercise.dart';
import 'package:strivo/features/workout/presentation/widgets/active/exercise_card.dart';

WorkoutExercise _exercise() => const WorkoutExercise(
  id: 'we1',
  order: 0,
  exercise: Exercise(
    id: 'e1',
    name: 'Bench Press',
    primaryMuscle: MuscleGroup.chest,
    equipment: Equipment.barbell,
  ),
  sets: [ExerciseSet(id: 's1', setNumber: 1, weight: 60, reps: 8)],
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required void Function(String setId) onSetCompleted,
  VoidCallback? onAddSet,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ExerciseCard(
          workoutExercise: _exercise(),
          onSetCompleted: onSetCompleted,
          onSetUpdated: (_, _) {},
          onAddSet: onAddSet ?? () {},
          onRemoveSet: (_) {},
          onRemoveExercise: () {},
          onNotesChanged: (_) {},
          onWatchVideo: () {},
          onSwap: () {},
        ),
      ),
    ),
  );
}

void main() {
  // The Units mirror normally hydrates from Hive on first read; seed it so the
  // set rows can format weights without a Hive box.
  setUp(() => Units.unit = WeightUnit.kg);

  testWidgets('tapping the complete button logs the set as done', (
    tester,
  ) async {
    String? completedId;
    await _pumpCard(tester, onSetCompleted: (id) => completedId = id);

    await tester.tap(find.byIcon(LucideIcons.check));
    await tester.pump();

    expect(completedId, 's1');
  });

  testWidgets('tapping Add Set requests another set', (tester) async {
    var addCount = 0;
    await _pumpCard(
      tester,
      onSetCompleted: (_) {},
      onAddSet: () => addCount++,
    );

    await tester.tap(find.text('Add Set'));
    await tester.pump();

    expect(addCount, 1);
  });
}
