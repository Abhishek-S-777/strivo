import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';

/// A small inline stat shown in the hero card footer (e.g. Workouts • Sets • PRs).
class HeroStat {
  final String label;
  final String value;
  final Color? color;
  const HeroStat(this.label, this.value, {this.color});
}

/// Premium "Weekly Volume" hero card — big number, trend pill, and a smooth
/// sparkline of recent weekly volume. Reused on Home and Analytics.
class VolumeHeroCard extends StatelessWidget {
  final String label;
  final double volumeKg;
  final double diffPercent;

  /// Weekly volume series, oldest → newest. Drives the sparkline.
  final List<double> sparkline;
  final List<HeroStat> stats;

  const VolumeHeroCard({
    super.key,
    required this.label,
    required this.volumeKg,
    required this.diffPercent,
    this.sparkline = const [],
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTrend = diffPercent.abs() >= 0.05;
    final up = diffPercent >= 0;
    final trendColor = !hasTrend
        ? AppColors.stagnant
        : (up ? AppColors.increase : AppColors.decrease);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(14),
            AppColors.surface,
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasTrend)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withAlpha(22),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        up ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        size: 13,
                        color: trendColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${up ? '+' : ''}${diffPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatVolume(volumeKg),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'kg',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ),
          if (_sparkPoints.length >= 2) ...[
            const SizedBox(height: 16),
            SizedBox(height: 48, child: _Sparkline(values: _sparkPoints)),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats[i].value,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: stats[i].color ?? AppColors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stats[i].label.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < stats.length - 1)
                      Container(
                          width: 0.5, height: 28, color: AppColors.border),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Trim leading zero-weeks so the sparkline starts where training did.
  List<double> get _sparkPoints {
    final firstNonZero = sparkline.indexWhere((v) => v > 0);
    if (firstNonZero < 0) return const [];
    return sparkline.sublist(firstNonZero);
  }

  String _formatVolume(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  const _Sparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    // Pad the range so a flat line sits mid-card instead of on the edge.
    final span = (maxV - minV).abs();
    final pad = span == 0 ? (maxV == 0 ? 1.0 : maxV * 0.2) : span * 0.15;

    return LineChart(
      LineChartData(
        minY: minV - pad,
        maxY: maxV + pad,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.32,
            color: AppColors.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, bar) => spot.x == values.length - 1,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: AppColors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withAlpha(46),
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
