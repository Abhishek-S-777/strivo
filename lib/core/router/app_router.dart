import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strivo/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:strivo/features/analytics/presentation/screens/exercise_history_screen.dart';
import 'package:strivo/features/auth/presentation/providers/auth_providers.dart';
// Progress (photos) tab temporarily disabled — see commented route below.
// import 'package:strivo/features/progress_photos/presentation/screens/progress_photos_screen.dart';
import 'package:strivo/features/auth/presentation/screens/auth_screen.dart';
import 'package:strivo/features/auth/presentation/screens/splash_screen.dart';
import 'package:strivo/features/profile/presentation/screens/profile_screen.dart';
import 'package:strivo/features/programs/presentation/screens/program_builder_screen.dart';
import 'package:strivo/features/routines/presentation/screens/routine_builder_screen.dart';
import 'package:strivo/features/routines/presentation/screens/routines_screen.dart';
import 'package:strivo/features/workout/presentation/screens/active_workout_screen.dart';
import 'package:strivo/features/workout/presentation/screens/home_screen.dart';
import 'package:strivo/features/workout/presentation/screens/workout_summary_screen.dart';
import 'package:strivo/shared/widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Wait for Firebase to restore any persisted session.
      if (!auth.initialized) {
        return loc == '/splash' ? null : '/splash';
      }

      final loggedIn = auth.isAuthenticated;
      final atAuth = loc == '/auth';
      final atSplash = loc == '/splash';

      if (!loggedIn) {
        return atAuth ? null : '/auth';
      }
      // Signed in — bounce away from auth/splash into the app.
      if (atAuth || atSplash) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/routines',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RoutinesScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          // Progress (photos) tab temporarily disabled.
          // GoRoute(
          //   path: '/progress',
          //   pageBuilder: (context, state) => const NoTransitionPage(
          //     child: ProgressPhotosScreen(),
          //   ),
          // ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/workout/active',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final routineId = state.uri.queryParameters['routineId'];
          return ActiveWorkoutScreen(routineId: routineId);
        },
      ),
      GoRoute(
        path: '/workout/summary/:sessionId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return WorkoutSummaryScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/routines/builder',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final routineId = state.uri.queryParameters['routineId'];
          return RoutineBuilderScreen(routineId: routineId);
        },
      ),
      GoRoute(
        path: '/programs/builder',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final programId = state.uri.queryParameters['programId'];
          return ProgramBuilderScreen(programId: programId);
        },
      ),
      GoRoute(
        path: '/analytics/exercise/:exerciseId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId']!;
          final exerciseName = state.uri.queryParameters['name'] ?? 'Exercise';
          return ExerciseHistoryScreen(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
          );
        },
      ),
      GoRoute(
        path: '/auth',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuthScreen(),
      ),
    ],
  );
});
