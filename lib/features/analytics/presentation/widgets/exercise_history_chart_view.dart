import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// The "Chart" tab of the exercise history screen: summary stat cards and a
/// weight/volume line chart that toggles between the two series.
class ExerciseHistoryChartView extends StatelessWidget {
  const ExerciseHistoryChartView({
    required this.progress,
    required this.showVolume,
    required this.onToggle,
    super.key,
  });
  final ExerciseProgressData progress;
  final bool showVolume;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (progress.dataPoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.barChart3,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No data yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _ProgressStatCard(
                  label: 'Current',
                  value: Units.weightLabel(progress.currentMax),
                  icon: LucideIcons.target,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProgressStatCard(
                  label: 'All-Time Best',
                  value: Units.weightLabel(progress.allTimeMax),
                  icon: LucideIcons.trophy,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProgressStatCard(
                  label: 'Sessions',
                  value: '${progress.dataPoints.length}',
                  icon: LucideIcons.calendar,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Toggle button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showVolume ? 'Volume Progression' : 'Weight Progression',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    showVolume ? 'Show Weight' : 'Show Volume',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chart
          StrivoCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
              child: SizedBox(
                height: 240,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: AppColors.chartGrid,
                        strokeWidth: 0.5,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: progress.dataPoints.length > 8
                              ? (progress.dataPoints.length / 4).ceilToDouble()
                              : 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= progress.dataPoints.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              DateFormat(
                                'M/d',
                              ).format(progress.dataPoints[index].date),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textTertiary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: progress.dataPoints
                            .asMap()
                            .entries
                            .map(
                              (e) => FlSpot(
                                e.key.toDouble(),
                                Units.fromKg(
                                  showVolume
                                      ? e.value.totalVolume
                                      : e.value.maxWeight,
                                ),
                              ),
                            )
                            .toList(),
                        isCurved: true,
                        color: showVolume
                            ? AppColors.chartVolume
                            : AppColors.chartLine,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: progress.dataPoints.length <= 20,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: showVolume
                                  ? AppColors.chartVolume
                                  : AppColors.chartLine,
                              strokeWidth: 1.5,
                              strokeColor: AppColors.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              (showVolume
                                      ? AppColors.chartVolume
                                      : AppColors.chartLine)
                                  .withAlpha(25),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            AppColors.surfaceElevated,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final point = progress.dataPoints[spot.x.toInt()];
                            return LineTooltipItem(
                              '${showVolume ? Units.volumeValue(point.totalVolume) : Units.weight(point.maxWeight)} ${Units.label}${showVolume ? ' vol' : ''}\n${DateFormat('MMM d').format(point.date)}',
                              const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  const _ProgressStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: highlight ? AppColors.pr : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.pr : AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
