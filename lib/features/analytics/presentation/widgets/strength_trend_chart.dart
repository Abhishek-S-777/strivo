import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';

/// The 1RM/max-weight line chart for a single lift, plotted in the user's
/// display unit over [minY]–[maxY].
class StrengthTrendChart extends StatelessWidget {
  const StrengthTrendChart({
    required this.points,
    required this.minY,
    required this.maxY,
    super.key,
  });

  final List<ExerciseProgressPoint> points;
  final double minY;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    final labelEvery = points.length > 6 ? (points.length / 4).ceil() : 1;
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              const FlLine(color: AppColors.chartGrid, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) {
                  return const SizedBox.shrink();
                }
                return Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length || i % labelEvery != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM').format(points[i].date),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevated,
            getTooltipItems: (spots) => spots.map((s) {
              final p = points[s.x.toInt()];
              return LineTooltipItem(
                '${Units.weightLabel(p.maxWeight)}\n${DateFormat('MMM d').format(p.date)}',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), Units.fromKg(points[i].maxWeight)),
            ],
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: points.length <= 16,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary,
                strokeWidth: 1.5,
                strokeColor: AppColors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withAlpha(60),
                  AppColors.primary.withAlpha(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
