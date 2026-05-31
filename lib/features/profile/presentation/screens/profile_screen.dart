import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/auth/presentation/providers/auth_providers.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workoutSessionsProvider);
    final completedSessions =
        sessions.where((s) => s.isCompleted).toList();
    final totalVolume =
        completedSessions.fold(0.0, (sum, s) => sum + s.totalVolume);
    final totalSets =
        completedSessions.fold(0, (sum, s) => sum + s.totalCompletedSets);
    final totalDuration = completedSessions.fold(
        Duration.zero, (sum, s) => sum + s.duration);

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
                      value: _formatVolume(totalVolume),
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
                      subtitle: 'Kilograms (kg)',
                      onTap: () => _showWeightUnitPicker(context),
                    ),
                    const Divider(),
                    _SettingsTile(
                      icon: LucideIcons.timer,
                      title: 'Default Rest Timer',
                      subtitle: '90 seconds',
                      onTap: () => _showRestTimerPicker(context),
                    ),
                    const Divider(),
                    _SettingsTile(
                      icon: LucideIcons.barChart3,
                      title: 'Weight Increments',
                      subtitle: '2.5 kg',
                      onTap: () {},
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
                      subtitle: 'Export your workout history',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data export is coming soon'),
                        ),
                      ),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      if (isSignedIn) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.cloud,
                                  size: 10, color: AppColors.success),
                              const SizedBox(width: 3),
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
              Icon(LucideIcons.cloudOff,
                  size: 32, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(
                'Sign in to back up your data',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Your workouts and routines will sync across devices',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
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
            title: 'Cloud Backup',
            subtitle: 'Connected as ${user.email}',
            onTap: () {},
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

  String _formatVolume(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M kg';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k kg';
    return '${v.toStringAsFixed(0)} kg';
  }

  void _showWeightUnitPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight Unit',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Kilograms (kg)'),
              leading: const Icon(LucideIcons.check, color: AppColors.primary),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Pounds (lbs)'),
              leading: const Icon(LucideIcons.circle,
                  color: AppColors.textTertiary),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestTimerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Rest Timer',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (final seconds in [60, 90, 120, 180, 300])
              ListTile(
                title: Text(
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'),
                leading: Icon(
                  seconds == 90
                      ? LucideIcons.check
                      : LucideIcons.circle,
                  color: seconds == 90
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
                onTap: () => Navigator.pop(ctx),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlateCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _PlateCalculatorSheet(),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
            'Your workouts stay backed up in the cloud and on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authControllerProvider).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _AllTimeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AllTimeStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

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
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 18, color: AppColors.textTertiary),
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
  double _targetWeight = 60;
  final double _barWeight = 20;

  // Standard plate sizes (kg)
  static const _plateSizes = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

  List<double> _calculatePlates() {
    double remaining = (_targetWeight - _barWeight) / 2;
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
          Text('Plate Calculator',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Bar weight: ${_barWeight.toStringAsFixed(1)} kg',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),

          // Weight input
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                    () => _targetWeight = (_targetWeight - 2.5).clamp(20, 500)),
                icon: const Icon(LucideIcons.minus),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_targetWeight.toStringAsFixed(1)} kg',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    Text(
                      'Target Weight',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(
                    () => _targetWeight = (_targetWeight + 2.5).clamp(20, 500)),
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Plates visualization
          Text(
            'Per side:',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          if (plates.isEmpty)
            Text(
              'Just the bar!',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textTertiary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plates
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _getPlateColor(p).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: _getPlateColor(p).withAlpha(60)),
                        ),
                        child: Text(
                          '${p.toStringAsFixed(p == p.roundToDouble() ? 0 : 1)} kg',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getPlateColor(p),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getPlateColor(double weight) {
    if (weight >= 25) return AppColors.error;
    if (weight >= 20) return AppColors.primary;
    if (weight >= 15) return AppColors.warning;
    if (weight >= 10) return AppColors.success;
    if (weight >= 5) return AppColors.info;
    return AppColors.textSecondary;
  }
}
