import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/domain/analytics_models.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/features/analytics/presentation/widgets/strength_exercise_picker_sheet.dart';
import 'package:strivo/features/analytics/presentation/widgets/strength_trend_chart.dart';

/// The 1RM strength-trend panel: a headline estimate, a line chart for the
/// selected lift, and a chip/search selector to switch lifts.
class StrengthTrendCard extends StatefulWidget {
  const StrengthTrendCard({
    required this.exercises,
    required this.trends,
    super.key,
  });
  final List<ExerciseProgressData> exercises;
  final List<ExerciseTrend> trends;

  @override
  State<StrengthTrendCard> createState() => _StrengthTrendCardState();
}

class _StrengthTrendCardState extends State<StrengthTrendCard> {
  String? _selectedId;
  final _chipScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Default to the most-trained lift for a meaningful curve.
    final sorted = [...widget.exercises]
      ..sort((a, b) => b.dataPoints.length.compareTo(a.dataPoints.length));
    _selectedId = sorted.isNotEmpty ? sorted.first.exerciseId : null;
  }

  @override
  void dispose() {
    _chipScroll.dispose();
    super.dispose();
  }

  /// Select a lift and float its chip to the front of the row, gliding the
  /// list back to the start so the active chip is always the first one in view.
  void _select(String id) {
    setState(() => _selectedId = id);
    if (_chipScroll.hasClients) {
      unawaited(
        _chipScroll.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.exercises.firstWhere(
      (e) => e.exerciseId == _selectedId,
      orElse: () => widget.exercises.first,
    );
    // Selected lift floats to the front of the chip row; the rest keep their
    // original order, so a previously-selected chip returns to its old spot.
    final ordered = [
      selected,
      for (final e in widget.exercises)
        if (e.exerciseId != selected.exerciseId) e,
    ];
    final trend = widget.trends
        .where((t) => t.exerciseId == selected.exerciseId)
        .firstOrNull;
    final points = selected.dataPoints;
    final hasCurve = points.length >= 2;

    // Plot in the user's display unit.
    final maxW = points.isEmpty
        ? 0.0
        : points
              .map((p) => Units.fromKg(p.maxWeight))
              .reduce((a, b) => a > b ? a : b);
    final minW = points.isEmpty
        ? 0.0
        : points
              .map((p) => Units.fromKg(p.maxWeight))
              .reduce((a, b) => a < b ? a : b);
    final span = (maxW - minW).abs();
    final pad = span == 0 ? (maxW == 0 ? 5.0 : maxW * 0.1) : span * 0.25;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withAlpha(12), AppColors.surface],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STRENGTH TREND',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected.exerciseName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trend != null ? 'EST. 1RM' : 'BEST',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Units.weightLabel(
                      trend?.estimated1RM ?? selected.allTimeMax,
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 170,
            child: hasCurve
                ? StrengthTrendChart(
                    points: points,
                    minY: minW - pad,
                    maxY: maxW + pad,
                  )
                : Center(
                    child: Text(
                      'Log this lift again to see your trend',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
          ),

          // Exercise selector — a pinned search button + quick-access chips,
          // so a lift at the end of the list is one tap (not a long swipe) away.
          if (widget.exercises.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openSearch(selected.exerciseId),
                  child: Container(
                    height: 32,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      LucideIcons.search,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView.separated(
                      controller: _chipScroll,
                      scrollDirection: Axis.horizontal,
                      itemCount: ordered.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final ex = ordered[i];
                        final isSel = ex.exerciseId == selected.exerciseId;
                        return GestureDetector(
                          onTap: () => _select(ex.exerciseId),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.primary.withAlpha(28)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.primary.withAlpha(90)
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              ex.exerciseName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Open a searchable picker so any lift (even one far down the chip row) is
  /// reachable without scrolling. Returns the chosen exercise id.
  Future<void> _openSearch(String currentId) async {
    final sorted = [...widget.exercises]
      ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StrengthExercisePickerSheet(
        exercises: sorted,
        selectedId: currentId,
      ),
    );
    if (id != null && mounted) _select(id);
  }
}
