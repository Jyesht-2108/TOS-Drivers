// Attendance marking screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/attendance_record.dart';
import '../../../models/route.dart' as models;
import '../../../models/student.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/trip_provider.dart';
import '../../../services/route_service.dart';
import '../../../core/theme/app_theme.dart';

final attendanceRouteProvider = FutureProvider<models.Route?>((ref) async {
  final tripState = ref.watch(tripProvider);
  if (tripState.activeTrip == null) return null;
  
  final routeService = RouteService();
  return await routeService.getRouteById(tripState.activeTrip!.routeId);
});

class AttendanceMarkingScreen extends ConsumerStatefulWidget {
  const AttendanceMarkingScreen({super.key});

  @override
  ConsumerState<AttendanceMarkingScreen> createState() => _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends ConsumerState<AttendanceMarkingScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize attendance when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripState = ref.read(tripProvider);
      final routeAsync = ref.read(attendanceRouteProvider);
      
      if (tripState.activeTrip != null) {
        routeAsync.whenData((route) {
          if (route != null) {
            ref.read(attendanceProvider.notifier).initializeAttendance(
                  tripState.activeTrip!.id,
                  route.students,
                );
          }
        });
      }
    });
  }

  Future<void> _markAttendance(String studentId, String tripId, AttendanceStatus status) async {
    await ref.read(attendanceProvider.notifier).markAttendance(
          studentId,
          tripId,
          status,
        );

    if (mounted) {
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
  Widget build(BuildContext context) {
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

          return Column(
            children: [
              // Header with trip info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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
                        Text(
                          '${attendanceState.markedCount}/${route.students.length} marked',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Student list
              Expanded(
                child: attendanceState.records.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
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

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          student.name,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isLocked ? Colors.grey[600] : null,
                                          ),
                                        ),
                                      ),
                                      if (isLocked)
                                        Icon(
                                          Icons.check_circle,
                                          color: status == AttendanceStatus.PRESENT
                                              ? AppTheme.successGreen
                                              : AppTheme.errorRed,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: isLocked
                                              ? null
                                              : () => _markAttendance(
                                                    student.id,
                                                    activeTrip.id,
                                                    AttendanceStatus.PRESENT,
                                                  ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Present'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isLocked && status == AttendanceStatus.PRESENT
                                                ? AppTheme.successGreen
                                                : null,
                                            foregroundColor: isLocked && status == AttendanceStatus.PRESENT
                                                ? Colors.white
                                                : AppTheme.successGreen,
                                            minimumSize: const Size(0, 48),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: isLocked
                                              ? null
                                              : () => _markAttendance(
                                                    student.id,
                                                    activeTrip.id,
                                                    AttendanceStatus.ABSENT,
                                                  ),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Absent'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isLocked && status == AttendanceStatus.ABSENT
                                                ? AppTheme.errorRed
                                                : null,
                                            foregroundColor: isLocked && status == AttendanceStatus.ABSENT
                                                ? Colors.white
                                                : AppTheme.errorRed,
                                            minimumSize: const Size(0, 48),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
