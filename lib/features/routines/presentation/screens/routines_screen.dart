import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';
import 'package:strivo/features/workout/domain/entities/routine.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

// ── Routines Provider ──
final routinesProvider =
    StateNotifierProvider<RoutinesNotifier, List<Routine>>((ref) {
  return RoutinesNotifier();
});

class RoutinesNotifier extends StateNotifier<List<Routine>> {
  RoutinesNotifier() : super([]) {
    state = HiveService.getAllRoutines();
  }

  Future<void> saveRoutine(Routine routine) async {
    await HiveService.saveRoutine(routine);
    state = HiveService.getAllRoutines();
    // Cloud backup (no-op when signed out).
    FirestoreSyncService.instance.syncRoutine(routine);
  }

  Future<void> deleteRoutine(String id) async {
    await HiveService.deleteRoutine(id);
    state = HiveService.getAllRoutines();
    FirestoreSyncService.instance.deleteRoutine(id);
  }

  void refresh() {
    state = HiveService.getAllRoutines();
  }
}

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider);
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Routines',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/routines/builder'),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('New'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (routines.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.clipboardList,
                          size: 56, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text(
                        'No routines yet',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first routine to get started',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/routines/builder'),
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Create Routine'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final routine = routines[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RoutineDetailCard(
                          routine: routine,
                          onStart: () {
                            if (activeWorkout != null) {
                              _showActiveWorkoutDialog(context, ref);
                            } else {
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .startWorkout(routine: routine);
                              context.push('/workout/active');
                            }
                          },
                          onEdit: () => context.push(
                              '/routines/builder?routineId=${routine.id}'),
                          onDelete: () =>
                              _confirmDelete(context, ref, routine),
                        ),
                      );
                    },
                    childCount: routines.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showActiveWorkoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Active Workout'),
        content: const Text(
            'You have an active workout. Finish or discard it first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/workout/active');
            },
            child: const Text('Go to Workout'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Routine routine) {
    showDialog(
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
              ref.read(routinesProvider.notifier).deleteRoutine(routine.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RoutineDetailCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoutineDetailCard({
    required this.routine,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.moreVertical,
                      size: 18, color: AppColors.textTertiary),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Exercise list preview
            ...routine.exercises.take(4).map((re) => Padding(
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )),
            if (routine.exercises.length > 4)
              Text(
                '+${routine.exercises.length - 4} more exercises',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${routine.exerciseCount} exercises • ${routine.totalTargetSets} sets',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(LucideIcons.play, size: 16),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
