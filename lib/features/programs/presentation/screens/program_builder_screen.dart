import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/programs/data/program_repository_impl.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/programs/presentation/providers/program_providers.dart';
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
      builder: (_) => _WeekTargetsSheet(
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

          // Duration
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'No fixed end (rotation)',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Switch(
                      value: _ongoing,
                      onChanged: (v) => setState(() {
                        _ongoing = v;
                        _resizeAllTargets();
                      }),
                    ),
                  ],
                ),
                if (!_ongoing) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Program length',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.minus, size: 18),
                          onPressed: () => setState(() {
                            _weeks = (_weeks - 1).clamp(1, 52);
                            _resizeAllTargets();
                          }),
                        ),
                        Text(
                          '$_weeks wks',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.plus, size: 18),
                          onPressed: () => setState(() {
                            _weeks = (_weeks + 1).clamp(1, 52);
                            _resizeAllTargets();
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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

          ..._days.asMap().entries.map((e) => _dayCard(e.key, e.value)),

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

  Widget _dayCard(int dayIndex, ProgramDay day) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _renameDay(dayIndex),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            day.name,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.pencil,
                          size: 13,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: AppColors.error,
                  ),
                  onPressed: () => setState(() => _days.removeAt(dayIndex)),
                ),
              ],
            ),
          ),
          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'No exercises yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else
            ...day.exercises.asMap().entries.map((entry) {
              final pe = entry.value;
              final w1 = pe.weeklyTargets.isNotEmpty
                  ? pe.weeklyTargets.first.displayFull
                  : '—';
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  pe.exercise.name,
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  _ongoing ? w1 : 'Wk1: $w1 · tap to set all weeks',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  color: AppColors.textTertiary,
                  onPressed: () => setState(() {
                    final exs = List.of(day.exercises)..removeAt(entry.key);
                    _days[dayIndex] = day.copyWith(exercises: exs);
                  }),
                ),
                onTap: () => _editTargets(dayIndex, entry.key),
              );
            }),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextButton.icon(
              onPressed: () => _addExerciseToDay(dayIndex),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Exercise'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-week target editor. Lets you set sets/reps/RPE for each week, with a
/// "copy week 1 to all" shortcut to fill quickly.
class _WeekTargetsSheet extends StatefulWidget {
  const _WeekTargetsSheet({
    required this.exerciseName,
    required this.weeks,
    required this.ongoing,
    required this.initial,
  });
  final String exerciseName;
  final int weeks;
  final bool ongoing;
  final List<SetTarget> initial;

  @override
  State<_WeekTargetsSheet> createState() => _WeekTargetsSheetState();
}

class _WeekTargetsSheetState extends State<_WeekTargetsSheet> {
  late List<SetTarget> _targets;

  @override
  void initState() {
    super.initState();
    _targets = List.of(widget.initial);
    while (_targets.length < widget.weeks) {
      _targets.add(
        _targets.isNotEmpty
            ? _targets.last
            : const SetTarget(sets: 3, repsMin: 8, repsMax: 10),
      );
    }
  }

  void _update(int i, SetTarget t) => setState(() => _targets[i] = t);

  void _copyFirstToAll() {
    setState(() {
      final first = _targets.first;
      _targets = List.filled(widget.weeks, first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.exerciseName,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!widget.ongoing)
                    TextButton(
                      onPressed: _copyFirstToAll,
                      child: const Text('Wk1 → all'),
                    ),
                ],
              ),
              Text(
                'Sets × reps @ RPE',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.weeks,
                  separatorBuilder: (_, _) => const Divider(height: 14),
                  itemBuilder: (context, i) => _WeekRow(
                    label: widget.ongoing ? 'Target' : 'Week ${i + 1}',
                    target: _targets[i],
                    onChanged: (t) => _update(i, t),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _targets),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.label,
    required this.target,
    required this.onChanged,
  });
  final String label;
  final SetTarget target;
  final ValueChanged<SetTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _Stepper(
          label: 'sets',
          value: target.sets,
          min: 1,
          max: 20,
          onChanged: (v) => onChanged(target.copyWith(sets: v)),
        ),
        const SizedBox(width: 8),
        _Stepper(
          label: 'reps',
          value: target.repsMin,
          min: 1,
          max: 100,
          onChanged: (v) => onChanged(
            target.copyWith(
              repsMin: v,
              repsMax: (target.repsMax != null && target.repsMax! < v)
                  ? v
                  : target.repsMax,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _Stepper(
          label: 'rpe',
          value: (target.rpe ?? 0).round(),
          min: 0,
          max: 10,
          display: (target.rpe == null || target.rpe == 0)
              ? '—'
              : target.rpe!.toStringAsFixed(0),
          onChanged: (v) =>
              onChanged(target.copyWith(rpe: v == 0 ? null : v.toDouble())),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.display,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final String? display;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => onChanged((value - 1).clamp(min, max)),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      LucideIcons.minus,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Text(
                  display ?? '$value',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged((value + 1).clamp(min, max)),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      LucideIcons.plus,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
