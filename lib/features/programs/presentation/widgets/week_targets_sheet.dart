import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/programs/domain/entities/program.dart';

/// Per-week target editor. Lets you set sets/reps/RPE for each week, with a
/// "copy week 1 to all" shortcut to fill quickly.
class WeekTargetsSheet extends StatefulWidget {
  const WeekTargetsSheet({
    required this.exerciseName,
    required this.weeks,
    required this.ongoing,
    required this.initial,
    super.key,
  });
  final String exerciseName;
  final int weeks;
  final bool ongoing;
  final List<SetTarget> initial;

  @override
  State<WeekTargetsSheet> createState() => _WeekTargetsSheetState();
}

class _WeekTargetsSheetState extends State<WeekTargetsSheet> {
  late List<SetTarget> _targets;

  @override
  void initState() {
    super.initState();
    _targets = List.of(widget.initial);
    while (_targets.length < widget.weeks) {
      _targets.add(
        _targets.isNotEmpty
            ? _targets.last
            : const SetTarget(sets: 3, repsMin: 8, repsMax: 10),
      );
    }
  }

  void _update(int i, SetTarget t) => setState(() => _targets[i] = t);

  void _copyFirstToAll() {
    setState(() {
      final first = _targets.first;
      _targets = List.filled(widget.weeks, first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.exerciseName,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!widget.ongoing)
                    TextButton(
                      onPressed: _copyFirstToAll,
                      child: const Text('Wk1 → all'),
                    ),
                ],
              ),
              Text(
                'Sets × reps @ RPE',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.weeks,
                  separatorBuilder: (_, _) => const Divider(height: 14),
                  itemBuilder: (context, i) => _WeekRow(
                    label: widget.ongoing ? 'Target' : 'Week ${i + 1}',
                    target: _targets[i],
                    onChanged: (t) => _update(i, t),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _targets),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.label,
    required this.target,
    required this.onChanged,
  });
  final String label;
  final SetTarget target;
  final ValueChanged<SetTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _Stepper(
          label: 'sets',
          value: target.sets,
          min: 1,
          max: 20,
          onChanged: (v) => onChanged(target.copyWith(sets: v)),
        ),
        const SizedBox(width: 8),
        _Stepper(
          label: 'reps',
          value: target.repsMin,
          min: 1,
          max: 100,
          onChanged: (v) => onChanged(
            target.copyWith(
              repsMin: v,
              repsMax: (target.repsMax != null && target.repsMax! < v)
                  ? v
                  : target.repsMax,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _Stepper(
          label: 'rpe',
          value: (target.rpe ?? 0).round(),
          min: 0,
          max: 10,
          display: (target.rpe == null || target.rpe == 0)
              ? '—'
              : target.rpe!.toStringAsFixed(0),
          onChanged: (v) =>
              onChanged(target.copyWith(rpe: v == 0 ? null : v.toDouble())),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.display,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final String? display;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => onChanged((value - 1).clamp(min, max)),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      LucideIcons.minus,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Text(
                  display ?? '$value',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged((value + 1).clamp(min, max)),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      LucideIcons.plus,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
