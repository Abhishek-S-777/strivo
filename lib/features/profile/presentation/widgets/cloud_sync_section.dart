import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/sync/cloud_sync_repository.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/auth/presentation/providers/auth_providers.dart';
import 'package:strivo/features/profile/presentation/widgets/settings_tile.dart';
import 'package:strivo/features/workout/presentation/providers/workout_providers.dart';
import 'package:strivo/shared/widgets/strivo_card.dart';

/// The cloud-sync card on the profile screen. Prompts sign-in when signed out;
/// otherwise offers a manual backup and sign-out.
class CloudSyncSection extends ConsumerWidget {
  const CloudSyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
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
          SettingsTile(
            icon: LucideIcons.cloud,
            title: 'Back Up Now',
            subtitle: 'Connected as ${user.email}',
            onTap: () => _backupNow(context, ref),
          ),
          const Divider(),
          SettingsTile(
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
      await ref.read(cloudSyncRepositoryProvider).pushAllLocal();
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
