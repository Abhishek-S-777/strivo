import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';

/// Barbell plate calculator. Given a target weight, shows the plates to load
/// per side using standard plate sizes for the active unit.
class PlateCalculatorSheet extends StatefulWidget {
  const PlateCalculatorSheet({super.key});

  @override
  State<PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<PlateCalculatorSheet> {
  late final bool _isLbs = Units.isLbs;
  late final double _barWeight = _isLbs ? 45 : 20;
  late final double _step = _isLbs ? 5 : 2.5;
  late final double _maxTarget = _isLbs ? 1100 : 500;
  late double _targetWeight = _isLbs ? 135 : 60;

  // Standard plate sizes for the active unit.
  late final List<double> _plateSizes = _isLbs
      ? const [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]
      : const [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

  String get _unit => _isLbs ? 'lbs' : 'kg';

  List<double> _calculatePlates() {
    var remaining = (_targetWeight - _barWeight) / 2;
    if (remaining <= 0.001) return [];

    const epsilon = 0.001; // tolerate floating-point drift
    final plates = <double>[];
    for (final plateSize in _plateSizes) {
      while (remaining >= plateSize - epsilon) {
        plates.add(plateSize);
        remaining -= plateSize;
      }
    }
    return plates;
  }

  @override
  Widget build(BuildContext context) {
    final plates = _calculatePlates();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plate Calculator',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Bar weight: ${_barWeight.toStringAsFixed(0)} $_unit',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),

          // Weight input
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _targetWeight = (_targetWeight - _step).clamp(
                    _barWeight,
                    _maxTarget,
                  ),
                ),
                icon: const Icon(LucideIcons.minus),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_targetWeight.toStringAsFixed(_targetWeight % 1 == 0 ? 0 : 1)} $_unit',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Target Weight',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => _targetWeight = (_targetWeight + _step).clamp(
                    _barWeight,
                    _maxTarget,
                  ),
                ),
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Plates visualization
          Text(
            'Per side:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          if (plates.isEmpty)
            Text(
              'Just the bar!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plates
                  .map(
                    (p) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _getPlateColor(p).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getPlateColor(p).withAlpha(60),
                        ),
                      ),
                      child: Text(
                        '${p.toStringAsFixed(p == p.roundToDouble() ? 0 : 1)} $_unit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getPlateColor(p),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getPlateColor(double weight) {
    if (_isLbs) {
      if (weight >= 45) return AppColors.error;
      if (weight >= 35) return AppColors.primary;
      if (weight >= 25) return AppColors.warning;
      if (weight >= 10) return AppColors.success;
      if (weight >= 5) return AppColors.info;
      return AppColors.textSecondary;
    }
    if (weight >= 25) return AppColors.error;
    if (weight >= 20) return AppColors.primary;
    if (weight >= 15) return AppColors.warning;
    if (weight >= 10) return AppColors.success;
    if (weight >= 5) return AppColors.info;
    return AppColors.textSecondary;
  }
}
