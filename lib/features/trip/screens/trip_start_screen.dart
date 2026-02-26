// Trip start screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/trip.dart';
import '../../../models/route.dart' as models;
import '../../../providers/trip_provider.dart';
import '../../../services/route_service.dart';

final selectedRouteProvider = FutureProvider.family<models.Route?, String?>((ref, routeId) async {
  if (routeId == null) return null;
  final routeService = RouteService();
  return await routeService.getRouteById(routeId);
});

class TripStartScreen extends ConsumerStatefulWidget {
  final String? routeId;
  
  const TripStartScreen({super.key, this.routeId});

  @override
  ConsumerState<TripStartScreen> createState() => _TripStartScreenState();
}

class _TripStartScreenState extends ConsumerState<TripStartScreen> {
  TripType? _selectedTripType;
  bool _isLoading = false;

  Future<void> _handleStartTrip() async {
    if (_selectedTripType == null || widget.routeId == null) return;

    setState(() {
      _isLoading = true;
    });

    await ref.read(tripProvider.notifier).startTrip(
          widget.routeId!,
          _selectedTripType!,
        );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      final tripState = ref.read(tripProvider);
      if (tripState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tripState.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (tripState.activeTrip != null) {
        context.go('/active-trip');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeAsync = ref.watch(selectedRouteProvider(widget.routeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Trip'),
      ),
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return const Center(child: Text('Route not found'));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Route Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Route',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            route.name,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${route.students.length} students',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Trip Type Selection
                  Text(
                    'Select Trip Type',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  SegmentedButton<TripType>(
                    segments: const [
                      ButtonSegment<TripType>(
                        value: TripType.PICKUP,
                        label: Text('PICKUP'),
                        icon: Icon(Icons.home),
                      ),
                      ButtonSegment<TripType>(
                        value: TripType.DROP,
                        label: Text('DROP'),
                        icon: Icon(Icons.school),
                      ),
                    ],
                    selected: _selectedTripType != null ? {_selectedTripType!} : {},
                    onSelectionChanged: (Set<TripType> newSelection) {
                      setState(() {
                        _selectedTripType = newSelection.first;
                      });
                    },
                  ),

                  const Spacer(),

                  // Start Trip Button
                  ElevatedButton(
                    onPressed: _selectedTripType != null && !_isLoading
                        ? _handleStartTrip
                        : null,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Start Trip'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
