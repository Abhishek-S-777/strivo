import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';

/// A single selectable row in an [OptionPickerSheet].
class PickerOption {
  const PickerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// A bottom sheet that shows a title, an optional explanatory subtitle, and a
/// list of single-choice options with a check indicator on the selected one.
class OptionPickerSheet extends StatelessWidget {
  const OptionPickerSheet({
    required this.title,
    required this.options,
    this.subtitle,
    super.key,
  });
  final String title;
  final String? subtitle;
  final List<PickerOption> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
          const SizedBox(height: 12),
          for (final option in options)
            ListTile(
              title: Text(option.label),
              leading: Icon(
                option.selected ? LucideIcons.checkCircle : LucideIcons.circle,
                color: option.selected
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
              onTap: option.onTap,
            ),
        ],
      ),
    );
  }
}
