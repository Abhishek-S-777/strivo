import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/features/analytics/presentation/widgets/exercise_history_chart_view.dart';
import 'package:strivo/features/analytics/presentation/widgets/exercise_history_table_view.dart';

class ExerciseHistoryScreen extends ConsumerStatefulWidget {
  const ExerciseHistoryScreen({
    required this.exerciseId,
    required this.exerciseName,
    super.key,
  });
  final String exerciseId;
  final String exerciseName;

  @override
  ConsumerState<ExerciseHistoryScreen> createState() =>
      _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends ConsumerState<ExerciseHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showVolume = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(exerciseProgressProvider(widget.exerciseId));
    ref.watch(weightUnitProvider); // rebuild on kg/lbs change

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.exerciseName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExerciseHistoryChartView(
            progress: progress,
            showVolume: _showVolume,
            onToggle: () => setState(() => _showVolume = !_showVolume),
          ),
          ExerciseHistoryTableView(progress: progress),
        ],
      ),
    );
  }
}
