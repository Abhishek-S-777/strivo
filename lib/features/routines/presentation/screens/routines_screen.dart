import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/features/programs/presentation/providers/program_providers.dart';
import 'package:strivo/features/routines/presentation/providers/routine_providers.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  int _tab = 0; // 0 = routines, 1 = programs

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _tab == 0 ? 'Routines' : 'Programs',
                    style: theme.textTheme.displayMedium,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _tab == 0
                        ? context.push('/routines/builder')
                        : context.push('/programs/builder'),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('New'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Segmented toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    _segment('Routines', 0),
                    _segment('Programs', 1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _tab == 0 ? _routinesList() : _programsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, int index) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withAlpha(28) : null,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── Routines tab ──
  Widget _routinesList() {
    final routines = ref.watch(routinesProvider);
    final activeWorkout = ref.watch(activeWorkoutProvider);
    if (routines.isEmpty) {
      return _emptyState(
        icon: LucideIcons.clipboardList,
        title: 'No routines yet',
        subtitle: 'Create a reusable template you can start anytime',
        button: 'Create Routine',
        onTap: () => context.push('/routines/builder'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RoutineDetailCard(
            routine: routine,
            onStart: () {
              if (activeWorkout != null) {
                _activeWorkoutDialog();
              } else {
                ref
                    .read(activeWorkoutProvider.notifier)
                    .startWorkout(routine: routine);
                unawaited(context.push('/workout/active'));
              }
            },
            onEdit: () =>
                context.push('/routines/builder?routineId=${routine.id}'),
            onDelete: () => _confirmDeleteRoutine(routine),
          ),
        );
      },
    );
  }

  // ── Programs tab ──
  Widget _programsList() {
    final programs = ref.watch(programsProvider);
    final activeId = ref.watch(activeProgramIdProvider);
    if (programs.isEmpty) {
      return _emptyState(
        icon: LucideIcons.calendarRange,
        title: 'No programs yet',
        subtitle:
            'Build a multi-week plan (e.g. a 12-week program) with days & per-week targets',
        button: 'Create Program',
        onTap: () => context.push('/programs/builder'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ProgramCard(
            program: program,
            isActive: program.id == activeId,
            onSetActive: () {
              unawaited(
                ref.read(activeProgramIdProvider.notifier).set(program.id),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '"${program.name}" is active — see today\'s workout on Home',
                  ),
                ),
              );
            },
            onEdit: () =>
                context.push('/programs/builder?programId=${program.id}'),
            onRestart: () =>
                ref.read(programsProvider.notifier).restart(program.id),
            onDelete: () => _confirmDeleteProgram(program),
          ),
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String button,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(button),
            ),
          ],
        ),
      ),
    );
  }

  void _activeWorkoutDialog() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Active Workout'),
          content: const Text(
            'You have an active workout. Finish or discard it first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(context.push('/workout/active'));
              },
              child: const Text('Go to Workout'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRoutine(Routine routine) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Routine?'),
          content: Text('Are you sure you want to delete "${routine.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                unawaited(
                  ref.read(routinesProvider.notifier).deleteRoutine(routine.id),
                );
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProgram(Program program) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Program?'),
          content: Text('Delete "${program.name}" and its plan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                unawaited(
                  ref.read(programsProvider.notifier).delete(program.id),
                );
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Program Card ──
class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.isActive,
    required this.onSetActive,
    required this.onEdit,
    required this.onRestart,
    required this.onDelete,
  });
  final Program program;
  final bool isActive;
  final VoidCallback onSetActive;
  final VoidCallback onEdit;
  final VoidCallback onRestart;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = program.currentDay;
    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          program.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(28),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    LucideIcons.moreVertical,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'restart') onRestart();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'restart',
                      child: Text('Restart progress'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              program.isOngoing
                  ? '${program.dayCount}-day rotation · ongoing'
                  : '${program.durationWeeks} weeks · ${program.dayCount} days/week',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            if (!program.isOngoing) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: program.isComplete ? 1.0 : program.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceLight,
                  color: program.isComplete
                      ? AppColors.accent
                      : AppColors.primary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  program.isComplete
                      ? LucideIcons.checkCircle
                      : LucideIcons.mapPin,
                  size: 14,
                  color: program.isComplete
                      ? AppColors.accent
                      : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    program.isComplete
                        ? 'Completed 🎉 — restart to run again'
                        : '${program.positionLabel}${day != null ? ' · Next: ${day.name}' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isActive)
                  Text(
                    'Active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                    ),
                  )
                else
                  TextButton(
                    onPressed: onSetActive,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Set Active'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineDetailCard extends StatelessWidget {
  const _RoutineDetailCard({
    required this.routine,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });
  final Routine routine;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (routine.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Text(
                          routine.description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    LucideIcons.moreVertical,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...routine.exercises
                .take(4)
                .map(
                  (re) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${re.exercise.name} • ${re.targetSets}×${re.targetReps}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            if (routine.exercises.length > 4)
              Text(
                '+${routine.exercises.length - 4} more exercises',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${routine.exerciseCount} exercises • ${routine.totalTargetSets} sets',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(LucideIcons.play, size: 16),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
