import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/services/export_service.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/profile/presentation/widgets/settings_tile.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';

/// Bottom sheet offering the three export formats. [sessions] are the completed
/// workouts to export.
class ExportSheet extends StatelessWidget {
  const ExportSheet({required this.sessions, super.key});

  final List<WorkoutSession> sessions;

  Future<void> _run(BuildContext context, ExportFormat fmt) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    if (sessions.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No completed workouts to export yet')),
      );
      return;
    }
    try {
      await ExportService.instance.share(fmt, sessions);
    } on Object catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not export. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Export Data', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${sessions.length} completed workouts · weights in ${Units.label}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 12),
          SettingsTile(
            icon: LucideIcons.sparkles,
            title: 'AI Training Report',
            subtitle:
                'Readable Markdown summary — paste to an AI to tune diet & recovery',
            onTap: () => _run(context, ExportFormat.report),
          ),
          const Divider(),
          SettingsTile(
            icon: LucideIcons.table,
            title: 'CSV (spreadsheet)',
            subtitle: 'One row per set — open in Excel/Sheets or diet apps',
            onTap: () => _run(context, ExportFormat.csv),
          ),
          const Divider(),
          SettingsTile(
            icon: LucideIcons.braces,
            title: 'JSON (full backup)',
            subtitle: 'Complete structured data (canonical kg)',
            onTap: () => _run(context, ExportFormat.json),
          ),
        ],
      ),
    );
  }
}
