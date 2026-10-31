import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/programs/data/program_repository_impl.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/programs/presentation/providers/program_providers.dart';
import 'package:strivo/features/programs/presentation/widgets/program_day_card.dart';
import 'package:strivo/features/programs/presentation/widgets/program_duration_card.dart';
import 'package:strivo/features/programs/presentation/widgets/week_targets_sheet.dart';
import 'package:strivo/features/workout/presentation/widgets/exercise_picker_sheet.dart';

class ProgramBuilderScreen extends ConsumerStatefulWidget {
  const ProgramBuilderScreen({super.key, this.programId});
  final String? programId;

  @override
  ConsumerState<ProgramBuilderScreen> createState() =>
      _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  int _weeks = 12;
  bool _ongoing = false;
  List<ProgramDay> _days = [];
  bool _isEditing = false;
  Program? _existing;

  int get _effectiveWeeks => _ongoing ? 1 : _weeks;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _desc = TextEditingController();
    if (widget.programId != null) {
      final p = ref.read(programRepositoryProvider).getById(widget.programId!);
      if (p != null) {
        _isEditing = true;
        _existing = p;
        _name.text = p.name;
        _desc.text = p.description ?? '';
        _ongoing = p.isOngoing;
        _weeks = p.isOngoing ? 12 : p.durationWeeks;
        _days = List.of(p.days);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _resizeAllTargets() {
    _days = _days
        .map(
          (d) => d.copyWith(
            exercises: d.exercises
                .map((e) => e.resizedTo(_effectiveWeeks))
                .toList(),
          ),
        )
        .toList();
  }

  void _addDay() {
    setState(() {
      _days = [
        ..._days,
        ProgramDay(
          id: IdGenerator.generate(),
          name: 'Day ${_days.length + 1}',
          exercises: const [],
        ),
      ];
    });
  }

  void _renameDay(int index) {
    final controller = TextEditingController(text: _days[index].name);
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Day Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Upper A, Push'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(
                  () => _days[index] = _days[index].copyWith(
                    name: controller.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _addExerciseToDay(int dayIndex) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExercisePickerSheet(
          onExerciseSelected: (exercise) {
            setState(() {
              final pe = ProgramExercise(
                id: IdGenerator.generate(),
                exercise: exercise,
                weeklyTargets: List.generate(
                  _effectiveWeeks,
                  (_) => const SetTarget(sets: 3, repsMin: 8, repsMax: 10),
                ),
              );
              _days[dayIndex] = _days[dayIndex].copyWith(
                exercises: [..._days[dayIndex].exercises, pe],
              );
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _editTargets(int dayIndex, int exIndex) async {
    final pe = _days[dayIndex].exercises[exIndex];
    final result = await showModalBottomSheet<List<SetTarget>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WeekTargetsSheet(
        exerciseName: pe.exercise.name,
        weeks: _effectiveWeeks,
        ongoing: _ongoing,
        initial: pe.resizedTo(_effectiveWeeks).weeklyTargets,
      ),
    );
    if (result != null) {
      setState(() {
        final exs = List.of(_days[dayIndex].exercises);
        exs[exIndex] = pe.copyWith(weeklyTargets: result);
        _days[dayIndex] = _days[dayIndex].copyWith(exercises: exs);
      });
    }
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please name your program')),
      );
      return;
    }
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one training day')),
      );
      return;
    }
    _resizeAllTargets();
    final now = DateTime.now();
    final program = (_existing ?? Program.create(name: name)).copyWith(
      name: name,
      description: _desc.text.trim(),
      durationWeeks: _ongoing ? 0 : _weeks,
      days: _days,
      updatedAt: now,
    );
    unawaited(ref.read(programsProvider.notifier).save(program));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Program' : 'New Program'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Program Name',
              hintText: 'e.g. Nippard PPL — Beginner',
            ),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ProgramDurationCard(
            ongoing: _ongoing,
            weeks: _weeks,
            onOngoingChanged: (v) => setState(() {
              _ongoing = v;
              _resizeAllTargets();
            }),
            onWeeksChanged: (w) => setState(() {
              _weeks = w.clamp(1, 52);
              _resizeAllTargets();
            }),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Training Days', style: theme.textTheme.titleLarge),
              const Spacer(),
              Text(
                '${_days.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _ongoing
                ? 'These cycle in order, forever (Push → Pull → Legs → …).'
                : 'These repeat each week for $_weeks weeks. Set per-week targets per exercise.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          ..._days.asMap().entries.map(
            (e) => ProgramDayCard(
              day: e.value,
              ongoing: _ongoing,
              onRename: () => _renameDay(e.key),
              onDelete: () => setState(() => _days.removeAt(e.key)),
              onAddExercise: () => _addExerciseToDay(e.key),
              onEditTargets: (exIndex) => _editTargets(e.key, exIndex),
              onRemoveExercise: (exIndex) => setState(() {
                final day = _days[e.key];
                final exs = List.of(day.exercises)..removeAt(exIndex);
                _days[e.key] = day.copyWith(exercises: exs);
              }),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addDay,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Training Day'),
            ),
          ),
        ],
      ),
    );
  }
}
