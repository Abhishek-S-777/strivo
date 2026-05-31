import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/routines')) return 1;
    if (location.startsWith('/analytics')) return 2;
    // Progress tab temporarily disabled.
    // if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                context.go('/routines');
                break;
              case 2:
                context.go('/analytics');
                break;
              // Progress tab temporarily disabled.
              // case 3:
              //   context.go('/progress');
              //   break;
              case 3:
                context.go('/profile');
                break;
            }
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withAlpha(30),
          surfaceTintColor: Colors.transparent,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.dumbbell, size: 20),
              selectedIcon: Icon(LucideIcons.dumbbell,
                  size: 20, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.clipboardList, size: 20),
              selectedIcon: Icon(LucideIcons.clipboardList,
                  size: 20, color: AppColors.primary),
              label: 'Routines',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.barChart3, size: 20),
              selectedIcon: Icon(LucideIcons.barChart3,
                  size: 20, color: AppColors.primary),
              label: 'Analytics',
            ),
            // Progress tab temporarily disabled.
            // NavigationDestination(
            //   icon: Icon(LucideIcons.camera, size: 20),
            //   selectedIcon: Icon(LucideIcons.camera,
            //       size: 20, color: AppColors.primary),
            //   label: 'Progress',
            // ),
            NavigationDestination(
              icon: Icon(LucideIcons.user, size: 20),
              selectedIcon:
                  Icon(LucideIcons.user, size: 20, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
