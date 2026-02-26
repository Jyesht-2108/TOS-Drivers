// Trip service with mock implementation

import '../models/trip.dart';
import 'mock_data_store.dart';

class TripService {
  // In-memory storage for trips
  final List<Trip> _trips = [];
  int _tripIdCounter = 1;

  // Start a new trip
  Future<Trip> startTrip(String routeId, TripType tripType) async {
    return await MockDataStore.simulateApiCall(() {
      // Check if there's already an active trip for this route
      final existingActiveTrip = _trips.firstWhere(
        (trip) => trip.routeId == routeId && trip.status == TripStatus.ACTIVE,
        orElse: () => Trip(
          id: '',
          routeId: '',
          tripType: TripType.PICKUP,
          status: TripStatus.ENDED,
          startTime: DateTime.now(),
        ),
      );

      if (existingActiveTrip.id.isNotEmpty) {
        throw Exception('A trip is already active for this route');
      }

      // Create new trip
      final trip = Trip(
        id: 'trip_${_tripIdCounter++}',
        routeId: routeId,
        tripType: tripType,
        status: TripStatus.ACTIVE,
        startTime: DateTime.now(),
      );

      _trips.add(trip);
      return trip;
    });
  }

  // End an active trip
  Future<Trip> endTrip(String tripId) async {
    return await MockDataStore.simulateApiCall(() {
      final tripIndex = _trips.indexWhere((trip) => trip.id == tripId);
      
      if (tripIndex == -1) {
        throw Exception('Trip not found');
      }

      final trip = _trips[tripIndex];
      
      if (trip.status == TripStatus.ENDED) {
        throw Exception('Trip is already ended');
      }

      // Create updated trip with ENDED status
      final endedTrip = Trip(
        id: trip.id,
        routeId: trip.routeId,
        tripType: trip.tripType,
        status: TripStatus.ENDED,
        startTime: trip.startTime,
        endTime: DateTime.now(),
      );

      _trips[tripIndex] = endedTrip;
      return endedTrip;
    });
  }

  // Get the currently active trip
  Trip? getActiveTrip() {
    try {
      return _trips.firstWhere((trip) => trip.status == TripStatus.ACTIVE);
    } catch (e) {
      return null;
    }
  }

  // Get all past trips
  Future<List<Trip>> getPastTrips() async {
    return await MockDataStore.simulateApiCall(() {
      return _trips
          .where((trip) => trip.status == TripStatus.ENDED)
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Most recent first
    });
  }
}
