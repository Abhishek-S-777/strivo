import 'package:flutter/material.dart';
import 'package:strivo/core/theme/app_colors.dart';

/// Prompt for a tutorial video link for [exerciseName].
///
/// Returns the trimmed URL on save, an empty string when cleared (only offered
/// when [hasVideo] is true), or null when cancelled.
Future<String?> showEditVideoDialog(
  BuildContext context, {
  required String exerciseName,
  required String? currentUrl,
  required bool hasVideo,
}) {
  final controller = TextEditingController(text: currentUrl ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Video · $exerciseName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'YouTube / video link',
              hintText: 'https://youtu.be/…',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Leave empty to use an automatic YouTube search when you tap "watch" during a workout.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        if (hasVideo)
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
