import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/services/export_service.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/auth/presentation/providers/auth_providers.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workoutSessionsProvider);
    final completedSessions = sessions.where((s) => s.isCompleted).toList();
    final totalVolume = completedSessions.fold<double>(
      0,
      (sum, s) => sum + s.totalVolume,
    );
    final totalSets = completedSessions.fold(
      0,
      (sum, s) => sum + s.totalCompletedSets,
    );
    final totalDuration = completedSessions.fold(
      Duration.zero,
      (sum, s) => sum + s.duration,
    );
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
              Text(
                'Profile',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 24),

              // User card with cloud sync status
              _buildUserCard(context, ref, completedSessions.length),

              const SizedBox(height: 24),

              // All-time stats
              Text(
                'All-Time Stats',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _AllTimeStatCard(
                      label: 'Workouts',
                      value: '${completedSessions.length}',
                      icon: LucideIcons.dumbbell,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AllTimeStatCard(
                      label: 'Total Volume',
                      value: Units.volumeLabel(totalVolume),
                      icon: LucideIcons.barChart2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _AllTimeStatCard(
                      label: 'Total Sets',
                      value: '$totalSets',
                      icon: LucideIcons.layers,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AllTimeStatCard(
                      label: 'Time Trained',
                      value: '${totalDuration.inHours}h',
                      icon: LucideIcons.clock,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Settings Section
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              StrivoCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: LucideIcons.ruler,
                      title: 'Weight Unit',
                      subtitle: unit == WeightUnit.kg
                          ? 'Kilograms (kg)'
                          : 'Pounds (lbs)',
                      onTap: () => _showWeightUnitPicker(context, ref),
                    ),
                    const Divider(),
                    _SettingsTile(
                      icon: LucideIcons.timer,
                      title: 'Default Rest Timer',
                      subtitle: _restLabel(defaultRest),
                      onTap: () => _showRestTimerPicker(context, ref),
                    ),
                    const Divider(),
                    _SettingsTile(
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
                    _SettingsTile(
                      icon: LucideIcons.database,
                      title: 'Export Data',
                      subtitle: 'CSV, JSON, or an AI-ready report',
                      onTap: () => _showExportSheet(context, ref),
                    ),
                    const Divider(),
                    _SettingsTile(
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

              // Plate Calculator
              StrivoCard(
                child: _SettingsTile(
                  icon: LucideIcons.calculator,
                  title: 'Plate Calculator',
                  subtitle: 'Calculate plates for your barbell',
                  onTap: () => _showPlateCalculator(context),
                ),
              ),

              const SizedBox(height: 24),

              // Cloud Sync Section
              Text(
                'Cloud Sync',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildCloudSyncSection(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, WidgetRef ref, int workoutCount) {
    final user = FirebaseAuth.instance.currentUser;
    final isSignedIn = user != null;

    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSignedIn ? LucideIcons.userCheck : LucideIcons.user,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSignedIn
                        ? ((user.displayName?.isNotEmpty ?? false)
                              ? user.displayName!
                              : (user.email ?? 'Athlete'))
                        : 'Strivo Athlete',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$workoutCount workouts completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (isSignedIn) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.cloud,
                                size: 10,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Synced',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudSyncSection(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isSignedIn = user != null;

    if (!isSignedIn) {
      return StrivoCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                LucideIcons.cloudOff,
                size: 32,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to back up your data',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Your workouts and routines will sync across devices',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/auth'),
                  icon: const Icon(LucideIcons.logIn, size: 18),
                  label: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StrivoCard(
      child: Column(
        children: [
          _SettingsTile(
            icon: LucideIcons.cloud,
            title: 'Back Up Now',
            subtitle: 'Connected as ${user.email}',
            onTap: () => _backupNow(context, ref),
          ),
          const Divider(),
          _SettingsTile(
            icon: LucideIcons.logOut,
            title: 'Sign Out',
            subtitle: 'Your local data will be preserved',
            onTap: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _backupNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final sessions = ref.read(workoutSessionsProvider);
    if (sessions.where((s) => s.isCompleted).isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nothing to back up yet')),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Backing up to cloud…')),
    );
    try {
      await FirestoreSyncService.instance.pushAllLocal();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('✓ Workouts backed up to cloud')),
        );
    } on Object catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Backup failed — check your connection.'),
          ),
        );
    }
  }

  void _showWeightUnitPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(weightUnitProvider);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weight Unit',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Applies across logging, analytics and exports. Existing data is converted automatically.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              for (final u in WeightUnit.values)
                ListTile(
                  title: Text(
                    u == WeightUnit.kg ? 'Kilograms (kg)' : 'Pounds (lbs)',
                  ),
                  leading: Icon(
                    u == current ? LucideIcons.checkCircle : LucideIcons.circle,
                    color: u == current
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                  onTap: () {
                    ref.read(weightUnitProvider.notifier).setUnit(u);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context, WidgetRef ref) {
    final sessions = ref
        .read(workoutSessionsProvider)
        .where((s) => s.isCompleted)
        .toList();

    Future<void> run(ExportFormat fmt) async {
      Navigator.pop(context);
      if (sessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No completed workouts to export yet')),
        );
        return;
      }
      try {
        await ExportService.instance.share(fmt, sessions);
      } on Object catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not export. Please try again.'),
            ),
          );
        }
      }
    }

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${sessions.length} completed workouts · weights in ${Units.label}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: LucideIcons.sparkles,
                title: 'AI Training Report',
                subtitle:
                    'Readable Markdown summary — paste to an AI to tune diet & recovery',
                onTap: () => run(ExportFormat.report),
              ),
              const Divider(),
              _SettingsTile(
                icon: LucideIcons.table,
                title: 'CSV (spreadsheet)',
                subtitle: 'One row per set — open in Excel/Sheets or diet apps',
                onTap: () => run(ExportFormat.csv),
              ),
              const Divider(),
              _SettingsTile(
                icon: LucideIcons.braces,
                title: 'JSON (full backup)',
                subtitle: 'Complete structured data (canonical kg)',
                onTap: () => run(ExportFormat.json),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _restLabel(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')} min';

  void _showRestTimerPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(defaultRestSecondsProvider);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Default Rest Timer',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Used between sets when a routine has no rest set for an exercise.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              for (final seconds in [45, 60, 90, 120, 180, 300])
                ListTile(
                  title: Text(
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} min',
                  ),
                  leading: Icon(
                    seconds == current
                        ? LucideIcons.checkCircle
                        : LucideIcons.circle,
                    color: seconds == current
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
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
      ),
    );
  }

  void _showIncrementPicker(BuildContext context, WidgetRef ref) {
    final current = Units.stepDisplay;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weight Increments',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'How much the +/- buttons add or remove during logging (${Units.label}).',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              for (final inc in Units.incrementOptions)
                ListTile(
                  title: Text(
                    '${inc % 1 == 0 ? inc.toStringAsFixed(0) : inc.toStringAsFixed(1)} ${Units.label}',
                  ),
                  leading: Icon(
                    inc == current
                        ? LucideIcons.checkCircle
                        : LucideIcons.circle,
                    color: inc == current
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                  onTap: () {
                    ref
                        .read(weightIncrementProvider.notifier)
                        .setIncrement(inc);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlateCalculator(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => const _PlateCalculatorSheet(),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign Out?'),
          content: const Text(
            'Your workouts stay backed up in the cloud and on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(ref.read(authControllerProvider).signOut());
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllTimeStatCard extends StatelessWidget {
  const _AllTimeStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return StrivoCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plate Calculator ──
class _PlateCalculatorSheet extends StatefulWidget {
  const _PlateCalculatorSheet();

  @override
  State<_PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<_PlateCalculatorSheet> {
  late final bool _isLbs = Units.isLbs;
  late final double _barWeight = _isLbs ? 45 : 20;
  late final double _step = _isLbs ? 5 : 2.5;
  late final double _maxTarget = _isLbs ? 1100 : 500;
  late double _targetWeight = _isLbs ? 135 : 60;

  // Standard plate sizes for the active unit.
  late final List<double> _plateSizes = _isLbs
      ? const [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]
      : const [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

  String get _unit => _isLbs ? 'lbs' : 'kg';

  List<double> _calculatePlates() {
    var remaining = (_targetWeight - _barWeight) / 2;
    if (remaining <= 0.001) return [];

    const epsilon = 0.001; // tolerate floating-point drift
    final plates = <double>[];
    for (final plateSize in _plateSizes) {
      while (remaining >= plateSize - epsilon) {
        plates.add(plateSize);
        remaining -= plateSize;
      }
    }
    return plates;
  }

  @override
  Widget build(BuildContext context) {
    final plates = _calculatePlates();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plate Calculator',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Bar weight: ${_barWeight.toStringAsFixed(0)} $_unit',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),

          // Weight input
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _targetWeight = (_targetWeight - _step).clamp(
                    _barWeight,
                    _maxTarget,
                  ),
                ),
                icon: const Icon(LucideIcons.minus),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_targetWeight.toStringAsFixed(_targetWeight % 1 == 0 ? 0 : 1)} $_unit',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Target Weight',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => _targetWeight = (_targetWeight + _step).clamp(
                    _barWeight,
                    _maxTarget,
                  ),
                ),
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Plates visualization
          Text(
            'Per side:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          if (plates.isEmpty)
            Text(
              'Just the bar!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plates
                  .map(
                    (p) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _getPlateColor(p).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getPlateColor(p).withAlpha(60),
                        ),
                      ),
                      child: Text(
                        '${p.toStringAsFixed(p == p.roundToDouble() ? 0 : 1)} $_unit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getPlateColor(p),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getPlateColor(double weight) {
    if (_isLbs) {
      if (weight >= 45) return AppColors.error;
      if (weight >= 35) return AppColors.primary;
      if (weight >= 25) return AppColors.warning;
      if (weight >= 10) return AppColors.success;
      if (weight >= 5) return AppColors.info;
      return AppColors.textSecondary;
    }
    if (weight >= 25) return AppColors.error;
    if (weight >= 20) return AppColors.primary;
    if (weight >= 15) return AppColors.warning;
    if (weight >= 10) return AppColors.success;
    if (weight >= 5) return AppColors.info;
    return AppColors.textSecondary;
  }
}
