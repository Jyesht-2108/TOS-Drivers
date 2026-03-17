import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/sse_provider.dart';
import '../../../providers/gps_provider.dart';
import '../../../services/app_lifecycle_service.dart';

class SseGpsTestScreen extends ConsumerStatefulWidget {
  const SseGpsTestScreen({super.key});

  @override
  ConsumerState<SseGpsTestScreen> createState() => _SseGpsTestScreenState();
}

class _SseGpsTestScreenState extends ConsumerState<SseGpsTestScreen> {
  final _driverIdController = TextEditingController(
    text: 'bf6798b0-850f-4aa9-b1ed-b5edec583daf', // Default test driver ID
  );
  final _tripIdController = TextEditingController(
    text: 'test-trip-123',
  );
  final _tokenController = TextEditingController(
    text: 'test-token', // Replace with actual JWT token
  );

  @override
  void dispose() {
    _driverIdController.dispose();
    _tripIdController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lifecycleService = ref.read(appLifecycleServiceProvider);
    final sseConnected = ref.watch(sseConnectionStateProvider);
    final gpsTracking = ref.watch(gpsTrackingStateProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    final gpsError = ref.watch(gpsErrorProvider);
    final studentAssigned = ref.watch(studentAssignedProvider);
    final studentRemoved = ref.watch(studentRemovedProvider);
    final routeUpdated = ref.watch(routeUpdatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSE + GPS Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _driverIdController,
                      decoration: const InputDecoration(
                        labelText: 'Driver ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tripIdController,
                      decoration: const InputDecoration(
                        labelText: 'Trip ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        labelText: 'Auth Token',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SSE Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'SSE Connection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          sseConnected ? Icons.check_circle : Icons.cancel,
                          color: sseConnected ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: sseConnected
                          ? null
                          : () async {
                              await lifecycleService.onLogin(
                                _driverIdController.text,
                                _tokenController.text,
                              );
                            },
                      icon: const Icon(Icons.connect_without_contact),
                      label: const Text('Connect SSE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: !sseConnected
                          ? null
                          : () {
                              lifecycleService.onLogout();
                            },
                      icon: const Icon(Icons.close),
                      label: const Text('Disconnect SSE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // GPS Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'GPS Tracking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          gpsTracking ? Icons.gps_fixed : Icons.gps_off,
                          color: gpsTracking ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: gpsTracking
                          ? null
                          : () async {
                              await lifecycleService.onTripStart(
                                _tripIdController.text,
                                _driverIdController.text,
                                _tokenController.text,
                              );
                            },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start GPS Tracking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: !gpsTracking
                          ? null
                          : () {
                              lifecycleService.onTripEnd();
                            },
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop GPS Tracking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (currentLocation != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Current Location:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${currentLocation.latitude.toStringAsFixed(6)}'),
                      Text('Longitude: ${currentLocation.longitude.toStringAsFixed(6)}'),
                      Text('Speed: ${currentLocation.speed.toStringAsFixed(2)} m/s'),
                      Text('Heading: ${currentLocation.heading.toStringAsFixed(1)}°'),
                      Text('Accuracy: ${currentLocation.accuracy.toStringAsFixed(1)} m'),
                    ],
                    if (gpsError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                gpsError,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Events Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Received Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (studentAssigned != null) ...[
                      _buildEventCard(
                        'Student Assigned',
                        studentAssigned,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (studentRemoved != null) ...[
                      _buildEventCard(
                        'Student Removed',
                        studentRemoved,
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (routeUpdated != null) ...[
                      _buildEventCard(
                        'Route Updated',
                        routeUpdated,
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (studentAssigned == null &&
                        studentRemoved == null &&
                        routeUpdated == null)
                      Text(
                        'No events received yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(String title, Map<String, dynamic> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
              )),
        ],
      ),
    );
  }
}
