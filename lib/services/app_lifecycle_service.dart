import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sse_provider.dart';
import '../providers/gps_provider.dart';

/// Service to manage app lifecycle events for SSE and GPS
class AppLifecycleService {
  final Ref ref;
  
  AppLifecycleService(this.ref);
  
  /// Initialize SSE connection when driver logs in
  Future<void> onLogin(String driverId, String token) async {
    final sseService = ref.read(sseServiceProvider);
    
    // Set up event handlers
    sseService.onConnected = () {
      print('AppLifecycle: SSE connected');
      ref.read(sseConnectionStateProvider.notifier).state = true;
    };
    
    sseService.onStudentAssigned = (data) {
      print('AppLifecycle: Student assigned - ${data['studentName']}');
      ref.read(studentAssignedProvider.notifier).state = data;
      // TODO: Show notification to driver
      // TODO: Refresh route/student list
    };
    
    sseService.onStudentRemoved = (data) {
      print('AppLifecycle: Student removed - ${data['studentId']}');
      ref.read(studentRemovedProvider.notifier).state = data;
      // TODO: Show notification to driver
      // TODO: Refresh route/student list
    };
    
    sseService.onRouteUpdated = (data) {
      print('AppLifecycle: Route updated - ${data['routeId']}');
      ref.read(routeUpdatedProvider.notifier).state = data;
      // Trigger route list refresh
      ref.read(routeRefreshTriggerProvider.notifier).state++;
      // TODO: Show notification to driver
    };
    
    sseService.onRouteAssigned = (data) {
      print('AppLifecycle: ========================================');
      print('AppLifecycle: ROUTE_ASSIGNED event received!');
      print('AppLifecycle: Route: ${data['routeName']} (${data['routeId']})');
      print('AppLifecycle: Driver: ${data['driverName']} (${data['driverId']})');
      print('AppLifecycle: ========================================');
      
      ref.read(routeAssignedProvider.notifier).state = data;
      
      // Trigger route list refresh
      final currentTrigger = ref.read(routeRefreshTriggerProvider);
      final newTrigger = currentTrigger + 1;
      print('AppLifecycle: Incrementing refresh trigger from $currentTrigger to $newTrigger');
      ref.read(routeRefreshTriggerProvider.notifier).state = newTrigger;
      
      print('AppLifecycle: Route list should refresh now!');
      // TODO: Show notification to driver
    };
    
    sseService.onRouteUnassigned = (data) {
      print('AppLifecycle: Route unassigned - ${data['routeId']}');
      ref.read(routeUnassignedProvider.notifier).state = data;
      // Trigger route list refresh
      ref.read(routeRefreshTriggerProvider.notifier).state++;
      // TODO: Show notification to driver
    };
    
    sseService.onError = (error) {
      print('AppLifecycle: SSE error - $error');
      ref.read(sseConnectionStateProvider.notifier).state = false;
    };
    
    // Connect to SSE
    await sseService.connect(driverId, token);
  }
  
  /// Start GPS tracking when trip begins
  Future<void> onTripStart(String tripId, String driverId, String token) async {
    final gpsService = ref.read(gpsServiceProvider);
    
    // Set up GPS handlers
    gpsService.onLocationUpdate = (position) {
      print('AppLifecycle: GPS update - Lat: ${position.latitude}, Lng: ${position.longitude}');
      ref.read(currentLocationProvider.notifier).state = position;
      ref.read(gpsErrorProvider.notifier).state = null;
    };
    
    gpsService.onError = (error) {
      print('AppLifecycle: GPS error - $error');
      ref.read(gpsErrorProvider.notifier).state = error;
    };
    
    // Start tracking
    await gpsService.startTracking(tripId, driverId, token);
    ref.read(gpsTrackingStateProvider.notifier).state = true;
  }
  
  /// Stop GPS tracking when trip ends
  void onTripEnd() {
    final gpsService = ref.read(gpsServiceProvider);
    gpsService.stopTracking();
    ref.read(gpsTrackingStateProvider.notifier).state = false;
    ref.read(currentLocationProvider.notifier).state = null;
    print('AppLifecycle: GPS tracking stopped');
  }
  
  /// Disconnect SSE when driver logs out
  void onLogout() {
    // Stop GPS if running
    final gpsService = ref.read(gpsServiceProvider);
    if (gpsService.isTracking) {
      gpsService.stopTracking();
      ref.read(gpsTrackingStateProvider.notifier).state = false;
    }
    
    // Disconnect SSE
    final sseService = ref.read(sseServiceProvider);
    sseService.disconnect();
    ref.read(sseConnectionStateProvider.notifier).state = false;
    
    // Clear state
    ref.read(currentLocationProvider.notifier).state = null;
    ref.read(studentAssignedProvider.notifier).state = null;
    ref.read(studentRemovedProvider.notifier).state = null;
    ref.read(routeUpdatedProvider.notifier).state = null;
    ref.read(routeAssignedProvider.notifier).state = null;
    ref.read(routeUnassignedProvider.notifier).state = null;
    ref.read(routeRefreshTriggerProvider.notifier).state = 0;
    
    print('AppLifecycle: Logged out, all services disconnected');
  }
  
  /// Check GPS permissions
  Future<bool> checkGpsPermissions() async {
    final gpsService = ref.read(gpsServiceProvider);
    return await gpsService.checkPermissions();
  }
}

// Provider for AppLifecycleService
final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  return AppLifecycleService(ref);
});
