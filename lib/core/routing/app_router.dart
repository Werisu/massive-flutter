import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/exercises/exercise_detail_screen.dart';
import '../../features/exercises/exercises_screen.dart';
import '../../features/guide/guide_screen.dart';
import '../../features/guide/guide_topic_screen.dart';
import '../../features/history/history_detail_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/hiit/hiit_player_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/workout_session/workout_session_screen.dart';
import '../../features/workouts/workout_detail_screen.dart';
import '../../features/workouts/workouts_screen.dart';
import 'shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/workouts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WorkoutsScreen(),
            ),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProgressScreen(),
            ),
          ),
          GoRoute(
            path: '/exercises',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExercisesScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/workout/:planId',
        builder: (context, state) {
          final planId = state.pathParameters['planId']!;
          return WorkoutDetailScreen(planId: planId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/session/:planId',
        builder: (context, state) {
          final planId = state.pathParameters['planId']!;
          return WorkoutSessionScreen(planId: planId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/hiit/:protocolId',
        builder: (context, state) {
          final id = state.pathParameters['protocolId']!;
          return HiitPlayerScreen(protocolId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/exercise/:exerciseId',
        builder: (context, state) {
          final id = state.pathParameters['exerciseId']!;
          return ExerciseDetailScreen(exerciseId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/history/day/:dayId',
        builder: (context, state) {
          final id = state.pathParameters['dayId']!;
          return HistoryDayDetailScreen(dayId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/history/:sessionId',
        builder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          return HistoryDetailScreen(sessionId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/guide',
        builder: (context, state) => const GuideScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/guide/:topicId',
        builder: (context, state) {
          final id = state.pathParameters['topicId']!;
          return GuideTopicScreen(topicId: id);
        },
      ),
    ],
  );
});
