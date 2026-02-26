// Routing configuration for TOS Driver App

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/routes/screens/route_list_screen.dart';
import '../../features/trip/screens/trip_start_screen.dart';
import '../../features/trip/screens/active_trip_screen.dart';
import '../../features/attendance/screens/attendance_marking_screen.dart';
import '../../features/attendance/screens/past_attendance_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/students/screens/student_list_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';

// Router provider - simplified without watching state
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      // Read state only when redirect is called, don't watch
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      // Authentication guard: redirect to login if not authenticated
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // If authenticated and on login page, redirect to routes
      if (isAuthenticated && isLoginRoute) {
        return '/routes';
      }

      // No other redirects - let screens handle their own state
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/routes',
        name: 'routes',
        builder: (context, state) => const RouteListScreen(),
      ),
      GoRoute(
        path: '/trip-start',
        name: 'trip-start',
        builder: (context, state) {
          final routeId = state.uri.queryParameters['routeId'];
          return TripStartScreen(routeId: routeId);
        },
      ),
      GoRoute(
        path: '/active-trip',
        name: 'active-trip',
        builder: (context, state) => const ActiveTripScreen(),
      ),
      GoRoute(
        path: '/attendance',
        name: 'attendance',
        builder: (context, state) => const AttendanceMarkingScreen(),
      ),
      GoRoute(
        path: '/past-attendance',
        name: 'past-attendance',
        builder: (context, state) => const PastAttendanceScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/students',
        name: 'students',
        builder: (context, state) => const StudentListScreen(),
      ),
    ],
  );
});
