import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// A card in the Programs tab showing a program's progress and actions.
class ProgramCard extends StatelessWidget {
  const ProgramCard({
    required this.program,
    required this.isActive,
    required this.onSetActive,
    required this.onEdit,
    required this.onRestart,
    required this.onDelete,
    super.key,
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
