// Attendance marking screen - Optimized

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/attendance_record.dart';
import '../../../models/route.dart' as models;
import '../../../providers/attendance_provider.dart';
import '../../../providers/trip_provider.dart';
import '../../../services/route_service.dart';
import '../../../core/theme/app_theme.dart';

final attendanceRouteProvider = FutureProvider.autoDispose<models.Route?>((ref) async {
  final tripState = ref.watch(tripProvider);
  if (tripState.activeTrip == null) return null;
  
  final routeService = RouteService();
  final route = await routeService.getRouteById(tripState.activeTrip!.routeId);
  
  // Initialize attendance immediately when route is loaded
  if (route != null && tripState.activeTrip != null) {
    ref.read(attendanceProvider.notifier).initializeAttendance(
      tripState.activeTrip!.id,
      route.students,
    );
  }
  
  return route;
});

class AttendanceMarkingScreen extends ConsumerWidget {
  const AttendanceMarkingScreen({super.key});

  Future<void> _markAttendance(
    WidgetRef ref,
    BuildContext context,
    String studentId,
    String tripId,
    AttendanceStatus status,
  ) async {
    await ref.read(attendanceProvider.notifier).markAttendance(
          studentId,
          tripId,
          status,
        );

    if (context.mounted) {
      final attendanceState = ref.read(attendanceProvider);
      if (attendanceState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendanceState.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tripState = ref.watch(tripProvider);
    final routeAsync = ref.watch(attendanceRouteProvider);
    final attendanceState = ref.watch(attendanceProvider);

    final activeTrip = tripState.activeTrip;

    if (activeTrip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mark Attendance')),
        body: const Center(child: Text('No active trip')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
      ),
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return const Center(child: Text('Route not found'));
          }

          if (attendanceState.records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing attendance...'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header with trip info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activeTrip.tripType.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${attendanceState.markedCount}/${route.students.length} marked',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Student list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: route.students.length,
                  itemBuilder: (context, index) {
                    final student = route.students[index];
                    final record = attendanceState.getRecordForStudent(student.id);
                    
                    if (record == null) {
                      return const SizedBox.shrink();
                    }

                    final isLocked = record.isLocked;
                    final status = record.status;
                    final isPresent = status == AttendanceStatus.PRESENT;
                    final isAbsent = status == AttendanceStatus.ABSENT;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isLocked ? 0 : 2,
                      color: isLocked
                          ? (isPresent ? Colors.green[50] : Colors.red[50])
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isLocked
                                      ? (isPresent ? Colors.green : Colors.red)
                                      : Colors.grey[300],
                                  child: Text(
                                    student.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isLocked ? Colors.white : Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isLocked ? Colors.grey[700] : null,
                                        ),
                                      ),
                                      if (isLocked)
                                        Text(
                                          isPresent ? 'Marked Present' : 'Marked Absent',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isPresent ? Colors.green[700] : Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isLocked)
                                  Icon(
                                    Icons.lock,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                              ],
                            ),
                            if (!isLocked) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _markAttendance(
                                            ref,
                                            context,
                                            student.id,
                                            activeTrip.id,
                                            AttendanceStatus.PRESENT,
                                          ),
                                      icon: const Icon(Icons.check, size: 20),
                                      label: const Text('Present'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.successGreen,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 44),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _markAttendance(
                                            ref,
                                            context,
                                            student.id,
                                            activeTrip.id,
                                            AttendanceStatus.ABSENT,
                                          ),
                                      icon: const Icon(Icons.close, size: 20),
                                      label: const Text('Absent'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.errorRed,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 44),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading students...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error loading attendance'),
            ],
          ),
        ),
      ),
    );
  }
}
