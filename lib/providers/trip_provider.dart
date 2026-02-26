// Trip state management with Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

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

  TripNotifier(this._tripService) : super(const TripState()) {
    // Load active trip on initialization
    _loadActiveTrip();
  }

  // Load active trip
  void _loadActiveTrip() {
    final activeTrip = _tripService.getActiveTrip();
    if (activeTrip != null) {
      state = state.copyWith(activeTrip: activeTrip);
    }
  }

  // Start a new trip
  Future<void> startTrip(String routeId, TripType tripType) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final trip = await _tripService.startTrip(routeId, tripType);
      state = TripState(activeTrip: trip, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // End the active trip
  Future<void> endTrip() async {
    if (state.activeTrip == null) {
      state = state.copyWith(error: 'No active trip to end');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final endedTrip = await _tripService.endTrip(state.activeTrip!.id);
      
      // Add to past trips and clear active trip
      final updatedPastTrips = [endedTrip, ...state.pastTrips];
      state = TripState(
        activeTrip: null,
        pastTrips: updatedPastTrips,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
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
  void refreshActiveTrip() {
    _loadActiveTrip();
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }
}

// Provider for TripService
final tripServiceProvider = Provider<TripService>((ref) {
  return TripService();
});

// Provider for TripNotifier
final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  final tripService = ref.watch(tripServiceProvider);
  return TripNotifier(tripService);
});
