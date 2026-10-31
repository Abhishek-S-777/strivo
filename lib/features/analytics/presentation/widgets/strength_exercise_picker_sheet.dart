import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';

/// Searchable bottom sheet for choosing which lift the strength-trend chart
/// shows. Pops the chosen exercise id.
class StrengthExercisePickerSheet extends StatefulWidget {
  const StrengthExercisePickerSheet({
    required this.exercises,
    this.selectedId,
    super.key,
  });
  final List<ExerciseProgressData> exercises;
  final String? selectedId;

  @override
  State<StrengthExercisePickerSheet> createState() =>
      _StrengthExercisePickerSheetState();
}

class _StrengthExercisePickerSheetState
    extends State<StrengthExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.exercises
        : widget.exercises
              .where((e) => e.exerciseName.toLowerCase().contains(q))
              .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Strength Trend',
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(LucideIcons.search, size: 18),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No exercises found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final e = items[i];
                      final sel = e.exerciseId == widget.selectedId;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary.withAlpha(28)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.dumbbell,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          e.exerciseName,
                          style: theme.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          '${e.dataPoints.length} sessions • Best ${Units.weightLabel(e.allTimeMax)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        trailing: sel
                            ? const Icon(
                                LucideIcons.check,
                                size: 18,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, e.exerciseId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
