// Active trip screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../models/trip.dart';
import '../../../models/route.dart' as models;
import '../../../providers/trip_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/gps_provider.dart';
import '../../../services/route_service.dart';
import '../../../shared/widgets/slide_button.dart';
import 'package:intl/intl.dart';

final activeRouteProvider = FutureProvider<models.Route?>((ref) async {
  final tripState = ref.watch(tripProvider);
  if (tripState.activeTrip == null) return null;
  
  final routeService = RouteService();
  return await routeService.getRouteById(tripState.activeTrip!.routeId);
});

class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isEndingTrip = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  // Default position (will be replaced by actual GPS)
  static const LatLng _defaultPosition = LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _getCurrentLocation();
    _startLocationUpdates();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        
        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
        
        print('ActiveTrip: Current location - Lat: ${position.latitude}, Lng: ${position.longitude}');
      }
    } catch (e) {
      print('ActiveTrip: Error getting location: $e');
    }
  }

  void _startLocationUpdates() {
    // Listen to position updates every 5 seconds
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        
        print('ActiveTrip: Location updated - Lat: ${position.latitude}, Lng: ${position.longitude}');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _handleEndTrip() async {
    setState(() {
      _isEndingTrip = true;
    });

    await ref.read(tripProvider.notifier).endTrip();

    if (mounted) {
      setState(() {
        _isEndingTrip = false;
      });

      final tripState = ref.read(tripProvider);
      if (tripState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tripState.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        context.go('/routes');
      }
    }
  }

  void _handleMarkAttendance() {
    final activeTrip = ref.read(tripProvider).activeTrip;
    if (activeTrip != null) {
      context.push('/attendance');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripState = ref.watch(tripProvider);
    final routeAsync = ref.watch(activeRouteProvider);

    final activeTrip = tripState.activeTrip;

    if (activeTrip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Trip')),
        body: const Center(child: Text('No active trip')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trip'),
        automaticallyImplyLeading: false,
      ),
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return const Center(child: Text('Route not found'));
          }

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Trip Details Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              route.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
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
                              activeTrip.tripType.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
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
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Started: ${DateFormat('hh:mm a').format(activeTrip.startTime)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.5 + (_pulseController.value * 0.5),
                                child: Icon(
                                  Icons.gps_fixed,
                                  color: Colors.green[700],
                                  size: 16,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'GPS Active',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Map View
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                          : _defaultPosition,
                      zoom: 15,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      // Move to current location once map is created
                      if (_currentPosition != null) {
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            15,
                          ),
                        );
                      }
                    },
                  ),
                ),

                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mark Attendance Button
                      OutlinedButton.icon(
                        onPressed: _handleMarkAttendance,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark Attendance'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // End Trip Slide Button
                      SlideButton(
                        text: 'Slide to End Trip',
                        icon: Icons.stop,
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        isLoading: _isEndingTrip,
                        onSlideComplete: !_isEndingTrip ? _handleEndTrip : () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
