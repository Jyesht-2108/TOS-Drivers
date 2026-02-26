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
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final tripState = ref.watch(tripProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState.isAuthenticated;
      final hasActiveTrip = tripState.hasActiveTrip;
      final isLoginRoute = state.matchedLocation == '/login';
      final isActiveTripRoute = state.matchedLocation == '/active-trip';
      final isAttendanceRoute = state.matchedLocation == '/attendance';

      // Authentication guard: redirect to login if not authenticated
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // If authenticated and on login page, redirect to routes
      if (isAuthenticated && isLoginRoute) {
        return '/routes';
      }

      // Active trip guard: redirect to routes if no active trip
      // but trying to access active trip or attendance screens
      if (isAuthenticated && !hasActiveTrip && (isActiveTripRoute || isAttendanceRoute)) {
        return '/routes';
      }

      return null; // No redirect needed
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
    ],
  );
});
