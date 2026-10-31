import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// Summary card showing this week's overall volume trend versus last week
/// (up / down / consistent) with a matching icon and message.
class OverallTrendCard extends ConsumerWidget {
  const OverallTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStats = ref.watch(weeklyStatsProvider);
    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getTrendColor(weeklyStats.trend).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTrendIcon(weeklyStats.trend),
                color: _getTrendColor(weeklyStats.trend),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Trend',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    _getTrendMessage(weeklyStats),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getTrendColor(weeklyStats.trend).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                weeklyStats.trend.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _getTrendColor(weeklyStats.trend),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'increase':
        return AppColors.increase;
      case 'decrease':
        return AppColors.decrease;
      default:
        return AppColors.stagnant;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'increase':
        return LucideIcons.trendingUp;
      case 'decrease':
        return LucideIcons.trendingDown;
      default:
        return LucideIcons.minus;
    }
  }

  String _getTrendMessage(WeeklyStats stats) {
    switch (stats.trend) {
      case 'increase':
        return 'Volume up ${stats.volumeDiffPercent.abs().toStringAsFixed(1)}% vs last week';
      case 'decrease':
        return 'Volume down ${stats.volumeDiffPercent.abs().toStringAsFixed(1)}% vs last week';
      default:
        return 'Volume is consistent with last week';
    }
  }
}
