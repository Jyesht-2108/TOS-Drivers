import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sse_service.dart';

// Base URL provider - can be overridden for different environments
final baseUrlProvider = Provider<String>((ref) {
  // Physical device - using computer's IP address
  return 'http://192.168.1.101:8082';
  
  // Android emulator
  // return 'http://10.0.2.2:8082';
  
  // iOS simulator
  // return 'http://localhost:8082';
});

// SSE Service provider
final sseServiceProvider = Provider<SseService>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final service = SseService(baseUrl: baseUrl);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

// SSE connection state provider
final sseConnectionStateProvider = StateProvider<bool>((ref) => false);

// Event notification providers
final studentAssignedProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final studentRemovedProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final routeUpdatedProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final routeAssignedProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final routeUnassignedProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Trigger to refresh routes when assignments change
final routeRefreshTriggerProvider = StateProvider<int>((ref) => 0);
