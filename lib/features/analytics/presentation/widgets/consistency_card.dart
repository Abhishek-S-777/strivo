import 'package:flutter/material.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// A GitHub-style heatmap of the last 12 weeks of training (7 rows × 12 cols),
/// with an intensity legend.
class ConsistencyCard extends StatelessWidget {
  const ConsistencyCard({required this.data, super.key});
  final ConsistencyData data;

  Color _levelColor(int level) {
    switch (level) {
      case 1:
        return AppColors.primary.withAlpha(50);
      case 2:
        return AppColors.primary.withAlpha(120);
      case 3:
        return AppColors.primary;
      case 0:
        return const Color(0xFF1C1C1C);
      default:
        return Colors.transparent; // future days
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Consistency', style: theme.textTheme.titleSmall),
                Text(
                  '${data.activeDays} active days',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Last 12 weeks',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),

            // Grid: 7 rows (Mon→Sun) × 12 cols (weeks)
            LayoutBuilder(
              builder: (context, constraints) {
                const cols = 12;
                const rows = 7;
                const gap = 4.0;
                final cell = (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Column(
                  children: List.generate(rows, (r) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: r < rows - 1 ? gap : 0),
                      child: Row(
                        children: List.generate(cols, (c) {
                          final level = data.weeks[c][r];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: c < cols - 1 ? gap : 0,
                            ),
                            child: Container(
                              width: cell,
                              height: cell,
                              decoration: BoxDecoration(
                                color: _levelColor(level),
                                borderRadius: BorderRadius.circular(3),
                                border: level == 0
                                    ? Border.all(
                                        color: AppColors.border,
                                        width: 0.5,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Less',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Row(
                  children: [
                    for (final lvl in [0, 1, 2, 3])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _levelColor(lvl),
                            borderRadius: BorderRadius.circular(2),
                            border: lvl == 0
                                ? Border.all(
                                    color: AppColors.border,
                                    width: 0.5,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Elite',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
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
