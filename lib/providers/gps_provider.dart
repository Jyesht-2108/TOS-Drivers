import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/gps_service.dart';
import 'sse_provider.dart';

// GPS Service provider
final gpsServiceProvider = Provider<GpsService>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final service = GpsService(baseUrl: baseUrl);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

// GPS tracking state provider
final gpsTrackingStateProvider = StateProvider<bool>((ref) => false);

// Current location provider
final currentLocationProvider = StateProvider<Position?>((ref) => null);

// GPS error provider
final gpsErrorProvider = StateProvider<String?>((ref) => null);
