import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';

/// Program duration control: a rotation toggle plus a week-count stepper.
///
/// [onWeeksChanged] receives the requested new week count (the caller clamps
/// it to the allowed range).
class ProgramDurationCard extends StatelessWidget {
  const ProgramDurationCard({
    required this.ongoing,
    required this.weeks,
    required this.onOngoingChanged,
    required this.onWeeksChanged,
    super.key,
  });

  final bool ongoing;
  final int weeks;
  final ValueChanged<bool> onOngoingChanged;
  final ValueChanged<int> onWeeksChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'No fixed end (rotation)',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Switch(value: ongoing, onChanged: onOngoingChanged),
            ],
          ),
          if (!ongoing) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Program length',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.minus, size: 18),
                    onPressed: () => onWeeksChanged(weeks - 1),
                  ),
                  Text(
                    '$weeks wks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plus, size: 18),
                    onPressed: () => onWeeksChanged(weeks + 1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
