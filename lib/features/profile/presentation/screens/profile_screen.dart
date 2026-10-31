import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/profile/presentation/widgets/all_time_stats.dart';
import 'package:strivo/features/profile/presentation/widgets/cloud_sync_section.dart';
import 'package:strivo/features/profile/presentation/widgets/export_sheet.dart';
import 'package:strivo/features/profile/presentation/widgets/option_picker_sheet.dart';
import 'package:strivo/features/profile/presentation/widgets/plate_calculator_sheet.dart';
import 'package:strivo/features/profile/presentation/widgets/profile_user_card.dart';
import 'package:strivo/features/profile/presentation/widgets/settings_tile.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(weightUnitProvider);
    ref.watch(weightIncrementProvider); // rebuild on increment change
    final defaultRest = ref.watch(defaultRestSecondsProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 24),
              const ProfileUserCard(),
              const SizedBox(height: 24),
              const AllTimeStats(),
              const SizedBox(height: 28),
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              StrivoCard(
                child: Column(
                  children: [
                    SettingsTile(
                      icon: LucideIcons.ruler,
                      title: 'Weight Unit',
                      subtitle: unit == WeightUnit.kg
                          ? 'Kilograms (kg)'
                          : 'Pounds (lbs)',
                      onTap: () => _showWeightUnitPicker(context, ref),
                    ),
                    const Divider(),
                    SettingsTile(
                      icon: LucideIcons.timer,
                      title: 'Default Rest Timer',
                      subtitle: _restLabel(defaultRest),
                      onTap: () => _showRestTimerPicker(context, ref),
                    ),
                    const Divider(),
                    SettingsTile(
                      icon: LucideIcons.barChart3,
                      title: 'Weight Increments',
                      subtitle: '${Units.incrementLabel} per tap',
                      onTap: () => _showIncrementPicker(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StrivoCard(
                child: Column(
                  children: [
                    SettingsTile(
                      icon: LucideIcons.database,
                      title: 'Export Data',
                      subtitle: 'CSV, JSON, or an AI-ready report',
                      onTap: () => _showExportSheet(context, ref),
                    ),
                    const Divider(),
                    SettingsTile(
                      icon: LucideIcons.info,
                      title: 'About Strivo',
                      subtitle: 'Version 1.0.0',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Strivo',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'Precision tracking for serious lifters.',
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            'A fast, offline-first gym workout tracker with '
                            'strength analytics, smart insights, and cloud backup.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StrivoCard(
                child: SettingsTile(
                  icon: LucideIcons.calculator,
                  title: 'Plate Calculator',
                  subtitle: 'Calculate plates for your barbell',
                  onTap: () => _showPlateCalculator(context),
                ),
              ),
              const SizedBox(height: 24),
              Text('Cloud Sync', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const CloudSyncSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeightUnitPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(weightUnitProvider);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => OptionPickerSheet(
          title: 'Weight Unit',
          subtitle:
              'Applies across logging, analytics and exports. Existing data is converted automatically.',
          options: [
            for (final u in WeightUnit.values)
              PickerOption(
                label: u == WeightUnit.kg ? 'Kilograms (kg)' : 'Pounds (lbs)',
                selected: u == current,
                onTap: () {
                  ref.read(weightUnitProvider.notifier).setUnit(u);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRestTimerPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(defaultRestSecondsProvider);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => OptionPickerSheet(
          title: 'Default Rest Timer',
          subtitle:
              'Used between sets when a routine has no rest set for an exercise.',
          options: [
            for (final seconds in [45, 60, 90, 120, 180, 300])
              PickerOption(
                label:
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} min',
                selected: seconds == current,
                onTap: () {
                  ref
                      .read(defaultRestSecondsProvider.notifier)
                      .setSeconds(seconds);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showIncrementPicker(BuildContext context, WidgetRef ref) {
    final current = Units.stepDisplay;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => OptionPickerSheet(
          title: 'Weight Increments',
          subtitle:
              'How much the +/- buttons add or remove during logging (${Units.label}).',
          options: [
            for (final inc in Units.incrementOptions)
              PickerOption(
                label:
                    '${inc % 1 == 0 ? inc.toStringAsFixed(0) : inc.toStringAsFixed(1)} ${Units.label}',
                selected: inc == current,
                onTap: () {
                  ref.read(weightIncrementProvider.notifier).setIncrement(inc);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context, WidgetRef ref) {
    final sessions = ref
        .read(workoutSessionsProvider)
        .where((s) => s.isCompleted)
        .toList();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => ExportSheet(sessions: sessions),
      ),
    );
  }

  void _showPlateCalculator(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => const PlateCalculatorSheet(),
      ),
    );
  }

  String _restLabel(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')} min';
}
