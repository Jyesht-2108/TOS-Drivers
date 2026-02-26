// Attendance marking screen - With confirmation step

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

class AttendanceMarkingScreen extends ConsumerStatefulWidget {
  const AttendanceMarkingScreen({super.key});

  @override
  ConsumerState<AttendanceMarkingScreen> createState() => _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends ConsumerState<AttendanceMarkingScreen> {
  // Track temporary selections before confirmation
  final Map<String, AttendanceStatus> _tempSelections = {};

  void _selectAttendance(String studentId, AttendanceStatus status) {
    setState(() {
      _tempSelections[studentId] = status;
    });
  }

  Future<void> _confirmAttendance(
    String studentId,
    String tripId,
    AttendanceStatus status,
  ) async {
    await ref.read(attendanceProvider.notifier).markAttendance(
          studentId,
          tripId,
          status,
        );

    if (mounted) {
      setState(() {
        _tempSelections.remove(studentId);
      });

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

  void _cancelSelection(String studentId) {
    setState(() {
      _tempSelections.remove(studentId);
    });
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
                          '${attendanceState.markedCount}/${route.students.length} confirmed',
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
                    final tempSelection = _tempSelections[student.id];
                    final hasSelection = tempSelection != null;
                    final isPresent = status == AttendanceStatus.PRESENT;
                    final isAbsent = status == AttendanceStatus.ABSENT;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isLocked ? 0 : (hasSelection ? 3 : 2),
                      color: isLocked
                          ? (isPresent ? Colors.green[50] : Colors.red[50])
                          : (hasSelection 
                              ? (tempSelection == AttendanceStatus.PRESENT 
                                  ? Colors.green[50] 
                                  : Colors.red[50])
                              : null),
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
                                      : (hasSelection
                                          ? (tempSelection == AttendanceStatus.PRESENT
                                              ? Colors.green[300]
                                              : Colors.red[300])
                                          : Colors.grey[300]),
                                  child: Text(
                                    student.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: (isLocked || hasSelection) ? Colors.white : Colors.grey[700],
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
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: isPresent ? Colors.green[700] : Colors.red[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isPresent ? 'Confirmed Present' : 'Confirmed Absent',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isPresent ? Colors.green[700] : Colors.red[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        )
                                      else if (hasSelection)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: tempSelection == AttendanceStatus.PRESENT 
                                                  ? Colors.green[700] 
                                                  : Colors.red[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              tempSelection == AttendanceStatus.PRESENT 
                                                  ? 'Selected Present - Tap confirm' 
                                                  : 'Selected Absent - Tap confirm',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: tempSelection == AttendanceStatus.PRESENT 
                                                    ? Colors.green[700] 
                                                    : Colors.red[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
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
                              if (!hasSelection)
                                // Initial selection buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _selectAttendance(
                                              student.id,
                                              AttendanceStatus.PRESENT,
                                            ),
                                        icon: const Icon(Icons.check, size: 20),
                                        label: const Text('Present'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.successGreen,
                                          side: BorderSide(color: AppTheme.successGreen),
                                          minimumSize: const Size(0, 44),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _selectAttendance(
                                              student.id,
                                              AttendanceStatus.ABSENT,
                                            ),
                                        icon: const Icon(Icons.close, size: 20),
                                        label: const Text('Absent'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.errorRed,
                                          side: BorderSide(color: AppTheme.errorRed),
                                          minimumSize: const Size(0, 44),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                // Confirmation buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _cancelSelection(student.id),
                                        icon: const Icon(Icons.undo, size: 20),
                                        label: const Text('Change'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey[700],
                                          side: BorderSide(color: Colors.grey[400]!),
                                          minimumSize: const Size(0, 44),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _confirmAttendance(
                                              student.id,
                                              activeTrip.id,
                                              tempSelection,
                                            ),
                                        icon: const Icon(Icons.check_circle, size: 20),
                                        label: const Text('Confirm & Lock'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: tempSelection == AttendanceStatus.PRESENT
                                              ? AppTheme.successGreen
                                              : AppTheme.errorRed,
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
