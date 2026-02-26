// Past attendance screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/trip.dart';
import '../../../models/route.dart' as models;
import '../../../models/attendance_record.dart';
import '../../../providers/trip_provider.dart';
import '../../../services/route_service.dart';
import '../../../services/attendance_service.dart';
import '../../../core/theme/app_theme.dart';

final pastTripsProvider = FutureProvider<List<Trip>>((ref) async {
  final tripService = ref.watch(tripServiceProvider);
  return await tripService.getPastTrips();
});

class PastAttendanceScreen extends ConsumerStatefulWidget {
  const PastAttendanceScreen({super.key});

  @override
  ConsumerState<PastAttendanceScreen> createState() => _PastAttendanceScreenState();
}

class _PastAttendanceScreenState extends ConsumerState<PastAttendanceScreen> {
  final Set<String> _expandedTrips = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pastTripsAsync = ref.watch(pastTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Trips'),
      ),
      body: pastTripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No past trips',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completed trips will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final isExpanded = _expandedTrips.contains(trip.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedTrips.remove(trip.id);
                          } else {
                            _expandedTrips.add(trip.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FutureBuilder<models.Route?>(
                                    future: RouteService().getRouteById(trip.routeId),
                                    builder: (context, snapshot) {
                                      final routeName = snapshot.data?.name ?? 'Loading...';
                                      return Text(
                                        routeName,
                                        style: theme.textTheme.headlineSmall,
                                      );
                                    },
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
                                    trip.tripType.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(trip.startTime),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${DateFormat('hh:mm a').format(trip.startTime)} - ${trip.endTime != null ? DateFormat('hh:mm a').format(trip.endTime!) : 'N/A'}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  isExpanded ? 'Hide Details' : 'View Details',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      FutureBuilder<List<AttendanceRecord>>(
                        future: AttendanceService().getAttendanceForTrip(trip.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No attendance records',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          }

                          final records = snapshot.data!;
                          return FutureBuilder<models.Route?>(
                            future: RouteService().getRouteById(trip.routeId),
                            builder: (context, routeSnapshot) {
                              if (!routeSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final route = routeSnapshot.data!;
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attendance Records',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...records.map((record) {
                                      final student = route.students.firstWhere(
                                        (s) => s.id == record.studentId,
                                        orElse: () => route.students.first,
                                      );
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                student.name,
                                                style: theme.textTheme.bodyMedium,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: record.status == AttendanceStatus.PRESENT
                                                    ? AppTheme.successGreen
                                                    : record.status == AttendanceStatus.ABSENT
                                                        ? AppTheme.errorRed
                                                        : Colors.grey,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                record.status.name,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading past trips',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
