// Route service with mock implementation

import '../models/route.dart';
import 'mock_data_store.dart';

class RouteService {
  // Get routes assigned to a specific driver
  Future<List<Route>> getAssignedRoutes(String driverId) async {
    return await MockDataStore.simulateApiCall(() {
      // Get route IDs assigned to this driver
      final assignedRouteIds = MockDataStore.driverRouteAssignments[driverId] ?? [];
      
      // Filter and return routes assigned to this driver
      return MockDataStore.mockRoutes
          .where((route) => assignedRouteIds.contains(route.id))
          .toList();
    });
  }

  // Get a specific route by ID
  Future<Route?> getRouteById(String routeId) async {
    return await MockDataStore.simulateApiCall(() {
      try {
        return MockDataStore.mockRoutes.firstWhere((route) => route.id == routeId);
      } catch (e) {
        return null;
      }
    });
  }
}
