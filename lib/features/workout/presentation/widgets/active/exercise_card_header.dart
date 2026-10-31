import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';

/// Header row of an exercise card: the name and equipment/muscle subtitle, plus
/// watch-video, swap, and overflow-menu actions.
class ExerciseCardHeader extends StatelessWidget {
  const ExerciseCardHeader({
    required this.exercise,
    required this.onWatchVideo,
    required this.onSwap,
    required this.onToggleNotes,
    required this.onRemove,
    super.key,
  });

  final Exercise exercise;
  final VoidCallback onWatchVideo;
  final VoidCallback onSwap;
  final VoidCallback onToggleNotes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.equipment.displayName} • ${exercise.primaryMuscle.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Watch a form video (pinned link or YouTube search).
          IconButton(
            tooltip: 'Watch video',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              LucideIcons.youtube,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: onWatchVideo,
          ),
          // Swap for an alternative (only when the exercise has any).
          if (exercise.hasAlternatives)
            IconButton(
              tooltip: 'Swap exercise',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(
                LucideIcons.repeat,
                size: 17,
                color: AppColors.primary,
              ),
              onPressed: onSwap,
            ),
          PopupMenuButton<String>(
            icon: const Icon(
              LucideIcons.moreVertical,
              size: 18,
              color: AppColors.textTertiary,
            ),
            onSelected: (value) {
              if (value == 'video') {
                onWatchVideo();
              } else if (value == 'swap') {
                onSwap();
              } else if (value == 'notes') {
                onToggleNotes();
              } else if (value == 'remove') {
                onRemove();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'video', child: Text('Watch Video')),
              if (exercise.hasAlternatives)
                const PopupMenuItem(
                  value: 'swap',
                  child: Text('Swap Exercise'),
                ),
              const PopupMenuItem(value: 'notes', child: Text('Add Notes')),
              const PopupMenuItem(
                value: 'remove',
                child: Text(
                  'Remove Exercise',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
