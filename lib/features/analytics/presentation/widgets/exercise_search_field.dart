import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';

/// Search box for the "Exercise Progress" list, bound to
/// [analyticsExerciseQueryProvider].
class ExerciseSearchField extends ConsumerStatefulWidget {
  const ExerciseSearchField({super.key});

  @override
  ConsumerState<ExerciseSearchField> createState() =>
      _ExerciseSearchFieldState();
}

class _ExerciseSearchFieldState extends ConsumerState<ExerciseSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(analyticsExerciseQueryProvider);
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search your exercises...',
        prefixIcon: const Icon(LucideIcons.search, size: 18),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: () {
                  _controller.clear();
                  ref.read(analyticsExerciseQueryProvider.notifier).state = '';
                },
              ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (v) =>
          ref.read(analyticsExerciseQueryProvider.notifier).state = v,
    );
  }
}
