import 'package:flutter/material.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// A stat tile on the workout summary screen: an icon, a value, a label, and an
/// optional +/- delta versus the previous session.
class SummaryStatCard extends StatelessWidget {
  const SummaryStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.comparison,
    super.key,
  });
  final String label;
  final String value;
  final IconData icon;
  final double? comparison;

  @override
  Widget build(BuildContext context) {
    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: AppColors.textTertiary),
                if (comparison != null && comparison != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: comparison! > 0
                          ? AppColors.successMuted
                          : AppColors.errorMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${comparison! > 0 ? '+' : ''}${comparison!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: comparison! > 0
                            ? AppColors.increase
                            : AppColors.decrease,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
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
