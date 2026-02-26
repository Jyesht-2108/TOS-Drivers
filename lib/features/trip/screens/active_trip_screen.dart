// Active trip screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/trip.dart';
import '../../../models/route.dart' as models;
import '../../../providers/trip_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../services/route_service.dart';
import 'package:intl/intl.dart';

final activeRouteProvider = FutureProvider<models.Route?>((ref) async {
  final tripState = ref.watch(tripProvider);
  if (tripState.activeTrip == null) return null;
  
  final routeService = RouteService();
  return await routeService.getRouteById(tripState.activeTrip!.routeId);
});

class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isEndingTrip = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleEndTrip() async {
    setState(() {
      _isEndingTrip = true;
    });

    await ref.read(tripProvider.notifier).endTrip();

    if (mounted) {
      setState(() {
        _isEndingTrip = false;
      });

      final tripState = ref.read(tripProvider);
      if (tripState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tripState.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        context.go('/routes');
      }
    }
  }

  void _handleMarkAttendance() {
    final activeTrip = ref.read(tripProvider).activeTrip;
    if (activeTrip != null) {
      context.push('/attendance');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripState = ref.watch(tripProvider);
    final routeAsync = ref.watch(activeRouteProvider);

    final activeTrip = tripState.activeTrip;

    if (activeTrip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Trip')),
        body: const Center(child: Text('No active trip')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trip'),
        automaticallyImplyLeading: false,
      ),
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return const Center(child: Text('Route not found'));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Trip Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  route.name,
                                  style: theme.textTheme.headlineMedium,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  activeTrip.tripType.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Started: ${DateFormat('hh:mm a').format(activeTrip.startTime)}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // GPS Indicator
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.5 + (_pulseController.value * 0.5),
                                child: Icon(
                                  Icons.gps_fixed,
                                  color: Colors.green[700],
                                  size: 32,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GPS Streaming Active',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                                Text(
                                  'Location is being tracked',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Mark Attendance Button
                  OutlinedButton(
                    onPressed: _handleMarkAttendance,
                    child: const Text('Mark Attendance'),
                  ),
                  const SizedBox(height: 16),

                  // End Trip Button
                  ElevatedButton(
                    onPressed: !_isEndingTrip ? _handleEndTrip : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: _isEndingTrip
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('End Trip'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
