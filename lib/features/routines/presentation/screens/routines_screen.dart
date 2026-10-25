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
import 'package:strivo/features/routines/presentation/widgets/program_card.dart';
import 'package:strivo/features/routines/presentation/widgets/routine_detail_card.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/shared/widgets/empty_state.dart';

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
      return EmptyState(
        icon: LucideIcons.clipboardList,
        title: 'No routines yet',
        subtitle: 'Create a reusable template you can start anytime',
        buttonLabel: 'Create Routine',
        onPressed: () => context.push('/routines/builder'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RoutineDetailCard(
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
      return EmptyState(
        icon: LucideIcons.calendarRange,
        title: 'No programs yet',
        subtitle:
            'Build a multi-week plan (e.g. a 12-week program) with days & '
            'per-week targets',
        buttonLabel: 'Create Program',
        onPressed: () => context.push('/programs/builder'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProgramCard(
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
