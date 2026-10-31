import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';

/// Fast tap-to-edit numeric field for weight/reps during logging: tap the
/// sides to step, tap the middle to type an exact value, long-press to
/// decrement. Optionally shows a +/- delta versus the previous set.
class InlineNumberInput extends StatelessWidget {
  const InlineNumberInput({
    required this.value,
    required this.width,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDirectInput,
    this.isDecimal = false,
    this.comparison,
    this.unitLabel,
    super.key,
  });
  final double value;
  final double width;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final void Function(double) onDirectInput;
  final bool isDecimal;
  final double? comparison;
  final String? unitLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showInputDialog(context),
      onLongPress: onDecrement,
      child: Container(
        width: width,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Decrement tap zone
            GestureDetector(
              onTap: onDecrement,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 14,
                height: 36,
                child: Center(
                  child: Icon(
                    LucideIcons.minus,
                    size: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            // Value display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isDecimal
                          ? (value % 1 == 0
                                ? value.toInt().toString()
                                : value.toStringAsFixed(1))
                          : value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (comparison != null && comparison != 0)
                      Text(
                        '${comparison! > 0 ? '+' : ''}${comparison!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: comparison! > 0
                              ? AppColors.increase
                              : AppColors.decrease,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Increment tap zone
            GestureDetector(
              onTap: onIncrement,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 14,
                height: 36,
                child: Center(
                  child: Icon(
                    LucideIcons.plus,
                    size: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    final controller = TextEditingController(
      text: isDecimal
          ? (value % 1 == 0 ? value.toInt().toString() : value.toString())
          : value.toInt().toString(),
    );

    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            isDecimal ? 'Enter Weight (${unitLabel ?? 'kg'})' : 'Enter Reps',
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) {
                onDirectInput(parsed);
              }
              Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text);
                if (parsed != null) {
                  onDirectInput(parsed);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
