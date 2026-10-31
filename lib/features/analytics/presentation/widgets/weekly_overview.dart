import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:strivo/shared/widgets/volume_hero_card.dart';

/// The volume hero card, paged through history: swipe right (or tap ◀) for the
/// previous week, swipe left (or tap ▶) for the next — bounded by the first week
/// you trained and the current week.
class WeeklyOverview extends ConsumerStatefulWidget {
  const WeeklyOverview({super.key});

  @override
  ConsumerState<WeeklyOverview> createState() => _WeeklyOverviewState();
}

class _WeeklyOverviewState extends ConsumerState<WeeklyOverview> {
  int _offset = 0; // 0 = current week, negative = further back
  int _dir = 0; // last navigation direction, drives the slide transition

  void _go(int delta, int minOffset) {
    final next = _offset + delta;
    if (next > 0 || next < minOffset) return; // no future, no empty pre-history
    setState(() {
      _dir = delta;
      _offset = next;
    });
  }

  String _label(int offset) {
    switch (offset) {
      case 0:
        return 'This Week';
      case -1:
        return 'Last Week';
      default:
        return '${-offset} Weeks Ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = ref.watch(weeklyStatsForWeekProvider(_offset));
    final minOffset = ref.watch(earliestTrainedWeekOffsetProvider);
    final canOlder = _offset > minOffset;
    final canNewer = _offset < 0;
    final weekEnd = stats.weekStart.add(const Duration(days: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(stats.weekOffset),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM d').format(stats.weekStart)} – ${DateFormat('MMM d').format(weekEnd)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            _WeekNavButton(
              icon: LucideIcons.chevronLeft,
              enabled: canOlder,
              onTap: () => _go(-1, minOffset),
            ),
            const SizedBox(width: 6),
            _WeekNavButton(
              icon: LucideIcons.chevronRight,
              enabled: canNewer,
              onTap: () => _go(1, minOffset),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v > 120) {
              _go(-1, minOffset); // swipe right → previous (older) week
            } else if (v < -120) {
              _go(1, minOffset); // swipe left → next (newer) week
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              final begin = Offset(
                _dir == 0 ? 0 : (_dir > 0 ? 0.12 : -0.12),
                0,
              );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: begin,
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: VolumeHeroCard(
              key: ValueKey(stats.weekOffset),
              label: 'Total Volume',
              volumeKg: stats.totalVolume,
              diffPercent: stats.volumeDiffPercent,
              stats: [
                HeroStat('Workouts', '${stats.workoutCount}'),
                HeroStat('Sets', '${stats.totalSets}'),
                HeroStat(
                  'PRs',
                  '${stats.prCount}',
                  color: stats.prCount > 0 ? AppColors.pr : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekNavButton extends StatelessWidget {
  const _WeekNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.textSecondary
              : AppColors.textTertiary.withAlpha(60),
        ),
      ),
    );
  }
}
