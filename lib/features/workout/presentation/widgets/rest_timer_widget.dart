import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';

class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);

    if (!timer.isRunning) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          // Timer circle
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: timer.progress,
                  strokeWidth: 3,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    timer.remainingSeconds <= 10
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
                Center(
                  child: Icon(
                    LucideIcons.timer,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest Timer',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
                Text(
                  timer.displayTime,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: timer.remainingSeconds <= 10
                            ? AppColors.error
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
          // Add 30s
          GestureDetector(
            onTap: () => ref.read(restTimerProvider.notifier).addTime(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+30s',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Stop
          GestureDetector(
            onTap: () => ref.read(restTimerProvider.notifier).stopTimer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.x, size: 16, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
