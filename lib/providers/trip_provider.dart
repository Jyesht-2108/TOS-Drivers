// Trip state management with Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';
import 'sse_provider.dart';
import 'gps_provider.dart';

// Trip state class
class TripState {
  final Trip? activeTrip;
  final List<Trip> pastTrips;
  final bool isLoading;
  final String? error;

  const TripState({
    this.activeTrip,
    this.pastTrips = const [],
    this.isLoading = false,
    this.error,
  });

  bool get hasActiveTrip => activeTrip != null;

  TripState copyWith({
    Trip? activeTrip,
    List<Trip>? pastTrips,
    bool? isLoading,
    String? error,
  }) {
    return TripState(
      activeTrip: activeTrip ?? this.activeTrip,
      pastTrips: pastTrips ?? this.pastTrips,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // Clear error
  TripState clearError() {
    return TripState(
      activeTrip: activeTrip,
      pastTrips: pastTrips,
      isLoading: isLoading,
      error: null,
    );
  }

  // Clear active trip
  TripState clearActiveTrip() {
    return TripState(
      activeTrip: null,
      pastTrips: pastTrips,
      isLoading: isLoading,
      error: error,
    );
  }
}

// Trip notifier
class TripNotifier extends StateNotifier<TripState> {
  final TripService _tripService;
  final Ref _ref;

  TripNotifier(this._tripService, this._ref) : super(const TripState()) {
    // Load active trip on initialization
    _loadActiveTrip();
  }

  // Load active trip
  Future<void> _loadActiveTrip() async {
    final activeTrip = await _tripService.getActiveTrip();
    if (activeTrip != null) {
      state = state.copyWith(activeTrip: activeTrip);
    }
  }

  // Start a new trip
  Future<void> startTrip(String routeId, TripType tripType) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final trip = await _tripService.startTrip(routeId, tripType);
      print('TripProvider: Trip started successfully - ID: ${trip.id}, Status: ${trip.status}');
      state = TripState(activeTrip: trip, isLoading: false);
      
      // Start GPS streaming ONLY if trip status is ACTIVE
      if (trip.status == TripStatus.ACTIVE) {
        print('TripProvider: Starting GPS streaming for ACTIVE trip');
        final gpsService = _ref.read(gpsServiceProvider);
        await gpsService.startGpsStreaming(trip.id);
      } else {
        print('TripProvider: Trip status is ${trip.status}, not starting GPS streaming');
      }
    } catch (e) {
      print('TripProvider: Error starting trip: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // End the active trip
  Future<void> endTrip() async {
    if (state.activeTrip == null) {
      print('TripProvider: No active trip to end');
      state = state.copyWith(error: 'No active trip to end');
      return;
    }

    print('TripProvider: Attempting to end trip ID: ${state.activeTrip!.id}');
    
    // STRICTLY stop GPS streaming and cleanup when trip ends
    print('TripProvider: Stopping GPS streaming and cleaning up');
    final gpsService = _ref.read(gpsServiceProvider);
    await gpsService.stopGpsStreaming();
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final endedTrip = await _tripService.endTrip(state.activeTrip!.id);
      print('TripProvider: Trip ended successfully - ID: ${endedTrip.id}');
      
      // Add to past trips and clear active trip
      final updatedPastTrips = [endedTrip, ...state.pastTrips];
      state = TripState(
        activeTrip: null,
        pastTrips: updatedPastTrips,
        isLoading: false,
      );
    } catch (e) {
      print('TripProvider: Error ending trip: $e');
      
      // If trip not found (404), it means it's already ended - clear the active trip
      if (e.toString().contains('not found') || e.toString().contains('already ended')) {
        print('TripProvider: Trip already ended, clearing active trip state');
        state = TripState(
          activeTrip: null,
          pastTrips: state.pastTrips,
          isLoading: false,
          error: 'Trip was already ended',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  // Load past trips
  Future<void> loadPastTrips() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final trips = await _tripService.getPastTrips();
      state = state.copyWith(pastTrips: trips, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Refresh active trip
  Future<void> refreshActiveTrip() async {
    print('TripProvider: Refreshing active trip state');
    final activeTrip = await _tripService.getActiveTrip();
    if (activeTrip != null) {
      print('TripProvider: Found active trip - ID: ${activeTrip.id}, Status: ${activeTrip.status}');
      state = state.copyWith(activeTrip: activeTrip);
    } else {
      print('TripProvider: No active trip found, clearing state');
      state = state.clearActiveTrip();
    }
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }
}

// Provider for TripService
final tripServiceProvider = Provider<TripService>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  return TripService(baseUrl: baseUrl);
});

// Provider for TripNotifier
final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  final tripService = ref.watch(tripServiceProvider);
  return TripNotifier(tripService, ref);
});
