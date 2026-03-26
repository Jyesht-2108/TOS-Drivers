// Route list screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/trip_provider.dart';
import '../../../providers/sse_provider.dart';
import '../../../providers/gps_provider.dart';
import '../../../services/route_service.dart';
import '../../../models/route.dart' as models;

final routeServiceProvider = Provider((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  return RouteService(baseUrl: baseUrl);
});

final assignedRoutesProvider = FutureProvider.autoDispose<List<models.Route>>((ref) async {
  final authState = ref.watch(authProvider);
  final routeService = ref.watch(routeServiceProvider);
  
  // Watch the refresh trigger to automatically reload when routes change
  final refreshTrigger = ref.watch(routeRefreshTriggerProvider);
  print('RouteList: Refresh trigger changed to $refreshTrigger');
  
  if (authState.user == null) {
    return [];
  }
  
  print('RouteList: Fetching routes for user ${authState.user!.id}');
  final routes = await routeService.getAssignedRoutes(authState.user!.id);
  print('RouteList: Fetched ${routes.length} routes');
  return routes;
});

class RouteListScreen extends ConsumerStatefulWidget {
  const RouteListScreen({super.key});

  @override
  ConsumerState<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends ConsumerState<RouteListScreen> {
  bool _hasLocationPermission = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    // Request location permissions when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermissions();
    });
  }

  Future<void> _checkLocationPermissions() async {
    final gpsService = ref.read(gpsServiceProvider);
    final hasPermission = await gpsService.requestLocationPermissions();
    
    setState(() {
      _hasLocationPermission = hasPermission;
      _permissionChecked = true;
    });

    if (!hasPermission && mounted) {
      // Show warning snackbar if permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'GPS tracking disabled. You can still start trips, but location won\'t be tracked.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  String _getRouteStatus(models.Route route, TripState tripState) {
    // Check if there's an active trip for this route
    if (tripState.activeTrip?.routeId == route.id) {
      return 'IN_PROGRESS';
    }
    
    // Check if this route has been completed today
    final today = DateTime.now();
    final completedToday = tripState.pastTrips.any((trip) =>
        trip.routeId == route.id &&
        trip.endTime != null &&
        trip.endTime!.year == today.year &&
        trip.endTime!.month == today.month &&
        trip.endTime!.day == today.day);
    
    if (completedToday) {
      return 'COMPLETED';
    }
    
    return 'NOT_STARTED';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return Icons.directions_bus;
      case 'COMPLETED':
        return Icons.check_circle;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed Today';
      default:
        return 'Not Started';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routesAsync = ref.watch(assignedRoutesProvider);
    final tripState = ref.watch(tripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => context.push('/students'),
            tooltip: 'Students',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/past-attendance'),
            tooltip: 'Trip History',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // GPS Warning Banner (persistent)
          if (_permissionChecked && !_hasLocationPermission)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange[900], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'GPS tracking is disabled. Trips can start but location won\'t be tracked.',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkLocationPermissions,
                    child: Text(
                      'RETRY',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Routes List
          Expanded(
            child: routesAsync.when(
        data: (routes) {
          if (routes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No routes assigned',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(assignedRoutesProvider);
              await ref.read(tripProvider.notifier).loadPastTrips();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                final status = _getRouteStatus(route, tripState);
                final statusColor = _getStatusColor(status);
                final isInProgress = status == 'IN_PROGRESS';
                final isCompleted = status == 'COMPLETED';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: isInProgress ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isInProgress
                        ? BorderSide(color: statusColor, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: isCompleted
                        ? null
                        : () {
                            if (isInProgress) {
                              context.push('/active-trip');
                            } else {
                              context.push('/trip-start?routeId=${route.id}');
                            }
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getStatusIcon(status),
                                  color: statusColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      route.name,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${route.students.length} students',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isInProgress) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, 
                                    size: 20, 
                                    color: Colors.blue[700]
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tap to continue this trip',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward, 
                                    size: 20, 
                                    color: Colors.blue[700]
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (isCompleted) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, 
                                    size: 20, 
                                    color: Colors.green[700]
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Trip completed for today',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (!isInProgress && !isCompleted) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.push('/trip-start?routeId=${route.id}'),
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Start Trip'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading routes',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(assignedRoutesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }
}
