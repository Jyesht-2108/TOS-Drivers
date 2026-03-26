# GPS Streaming Implementation ✅

## Overview
Live GPS streaming feature for the TOS Driver App that captures and streams the driver's device location to the backend during active trips.

## Implementation Summary

### 1. Device Permissions ✅

**Location**: `lib/features/routes/screens/route_list_screen.dart`

- Requests foreground location permissions when the route list screen loads
- Uses `geolocator` package (already installed)
- Permission request happens automatically via `initState()` callback
- Non-blocking: App continues to work even if permission is denied

**Permission Flow**:
```dart
1. Screen loads → _checkLocationPermissions() called
2. Calls gpsService.requestLocationPermissions()
3. Shows system permission dialog
4. Updates _hasLocationPermission state
5. Shows warning UI if denied
```

**Android Permissions** (already configured in `AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 2. Warning UI ✅

**Two-level warning system**:

1. **Snackbar** (temporary, 5 seconds):
   - Shows immediately when permission is denied
   - Orange background with warning icon
   - Message: "GPS tracking disabled. You can still start trips, but location won't be tracked."
   - Dismissible with "OK" button

2. **Persistent Banner** (stays visible):
   - Orange banner at top of route list
   - Shows location_off icon
   - Message: "GPS tracking is disabled. Trips can start but location won't be tracked."
   - "RETRY" button to request permissions again
   - Only visible when permission is denied

**User Experience**:
- Trip can still be started even without GPS permission
- Clear visual feedback about GPS status
- Easy way to retry permission request

### 3. GPS Streaming Loop ✅

**Location**: `lib/services/gps_service.dart`

**Key Features**:
- Timer.periodic with 15-second interval
- ONLY runs when trip status is ACTIVE
- Automatically starts when trip begins
- Automatically stops when trip ends
- Proper cleanup in dispose()

**Implementation**:
```dart
// Start streaming
_locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
  _streamGpsUpdate();
});

// Stop streaming
_locationTimer?.cancel();
_locationTimer = null;
```

**Safety Checks**:
- Checks if tracking is active before sending
- Checks if trip ID exists
- Checks if location permission is granted
- 10-second timeout for getting position
- 10-second timeout for HTTP request

### 4. API Integration ✅

**Endpoint**: `POST /api/v1/location/update`

**Request Body** (exact match to PRD):
```json
{
  "trip_id": "uuid",
  "lat": 37.7749,
  "lng": -122.4194,
  "accuracy_m": 15.5,
  "timestamp": "2026-03-26T08:00:00Z"
}
```

**Error Handling**:
- Try-catch wrapper around entire GPS update
- Network errors don't crash the app
- Failed pings are dropped silently
- Logs error and continues on next 15-second tick
- No retry logic (waits for next scheduled tick)

**Backend Storage**:
- Updates `latest_bus_location` table (upsert)
- Logs to `gps_logs` table (append-only history)
- Validates trip is ACTIVE before accepting

### 5. Trip Integration ✅

**Location**: `lib/providers/trip_provider.dart`

**Start Trip Flow**:
```dart
1. User starts trip
2. Backend creates trip with status=ACTIVE
3. TripProvider receives trip
4. Checks if trip.status == ACTIVE
5. Calls gpsService.startGpsStreaming(tripId)
6. GPS timer begins (15-second interval)
```

**End Trip Flow**:
```dart
1. User ends trip
2. TripProvider calls gpsService.stopGpsStreaming()
3. Timer is cancelled and cleaned up
4. Backend marks trip as COMPLETED
5. GPS streaming stops
```

**Cleanup Guarantees**:
- Timer cancelled in stopGpsStreaming()
- Timer cancelled in dispose()
- Timer cancelled on logout
- No memory leaks

## File Changes

### Modified Files
1. `lib/features/routes/screens/route_list_screen.dart`
   - Changed from ConsumerWidget to ConsumerStatefulWidget
   - Added permission request in initState()
   - Added warning snackbar
   - Added persistent warning banner
   - Added RETRY button

2. `lib/services/gps_service.dart` (already implemented)
   - 15-second Timer.periodic
   - Exact JSON structure matching PRD
   - Error handling with try-catch
   - Proper cleanup in dispose()

3. `lib/providers/trip_provider.dart` (already implemented)
   - Starts GPS streaming when trip becomes ACTIVE
   - Stops GPS streaming when trip ends
   - Cleanup on logout

### Existing Files (No Changes Needed)
- `android/app/src/main/AndroidManifest.xml` - Permissions already configured
- `pubspec.yaml` - Packages already installed (geolocator, permission_handler)
- `backend/handlers/location.go` - Endpoint already implemented
- `backend/routes/routes.go` - Route already registered

## Testing

### 1. Test Backend Endpoint
```bash
./test_gps_streaming.sh
```

This script tests:
- GPS update endpoint
- Database storage (latest_bus_location)
- GPS logs (gps_logs table)
- Error handling (invalid trip ID)
- Validation (missing fields)

### 2. Test Flutter App

**Step 1: Start Backend**
```bash
cd backend
go run main.go
```

**Step 2: Setup ADB Reverse**
```bash
adb reverse tcp:8082 tcp:8082
```

**Step 3: Run Flutter App**
```bash
flutter run
```

**Step 4: Test Permission Flow**
1. Login with phone: `+1234567891`
2. Route list screen loads
3. System shows location permission dialog
4. Grant or deny permission
5. If denied: See warning snackbar + banner
6. If granted: No warning shown

**Step 5: Test GPS Streaming**
1. Tap on a route
2. Select PICKUP or DROP
3. Slide to start trip
4. Watch Flutter console for GPS logs:
   ```
   GPS: Starting GPS streaming for trip: xxx (15-second interval)
   GPS: Streaming update - Lat: 37.7749, Lng: -122.4194, Accuracy: 15.5m
   GPS: Stream update successful - Trip: xxx
   ```
5. Check database for updates:
   ```bash
   watch -n 1 'PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT trip_id, latitude, longitude, timestamp FROM gps_logs ORDER BY timestamp DESC LIMIT 5;"'
   ```
6. End trip
7. Verify GPS streaming stops:
   ```
   GPS: Stopping GPS streaming and cleaning up
   ```

### 3. Test Error Handling

**Simulate Network Failure**:
1. Start trip (GPS streaming begins)
2. Stop backend server
3. Wait 15 seconds
4. Check Flutter console:
   ```
   GPS: Stream update error: Connection refused
   GPS: Will retry on next 15-second tick
   ```
5. App should NOT crash
6. Restart backend
7. Next 15-second tick should succeed

**Test Permission Denial**:
1. Deny location permission
2. See warning UI
3. Start trip anyway
4. Check console:
   ```
   GPS: Skipping update - no location permission
   ```
5. Trip continues normally without GPS

## Console Output Examples

### Successful GPS Streaming
```
GPS: Requesting location permissions...
GPS: Location permission granted
GPS: Starting GPS streaming for trip: 60000000-0000-0000-0000-000000000001 (15-second interval)
GPS: Streaming update - Lat: 37.7749, Lng: -122.4194, Accuracy: 15.5m
GPS: Stream update successful - Trip: 60000000-0000-0000-0000-000000000001
[15 seconds later]
GPS: Streaming update - Lat: 37.7750, Lng: -122.4195, Accuracy: 12.3m
GPS: Stream update successful - Trip: 60000000-0000-0000-0000-000000000001
```

### Permission Denied
```
GPS: Requesting location permissions...
GPS: Location permissions denied by user
[Snackbar shows: "GPS tracking disabled..."]
[Banner shows at top of screen]
```

### Network Error (Graceful Handling)
```
GPS: Streaming update - Lat: 37.7749, Lng: -122.4194, Accuracy: 15.5m
GPS: Stream update error: SocketException: Connection refused
GPS: Will retry on next 15-second tick
[App continues normally, no crash]
```

### Trip End (Cleanup)
```
TripProvider: Stopping GPS streaming and cleaning up
GPS: Stopping GPS streaming and cleaning up
GPS: Disposing GPS service
```

## Architecture

### Data Flow
```
1. User starts trip
   ↓
2. TripProvider.startTrip()
   ↓
3. Backend creates ACTIVE trip
   ↓
4. GpsService.startGpsStreaming(tripId)
   ↓
5. Timer.periodic (15 seconds)
   ↓
6. Geolocator.getCurrentPosition()
   ↓
7. POST /api/v1/location/update
   ↓
8. Backend stores in latest_bus_location + gps_logs
   ↓
9. Repeat every 15 seconds until trip ends
```

### Cleanup Flow
```
1. User ends trip OR app disposed OR logout
   ↓
2. GpsService.stopGpsStreaming()
   ↓
3. Timer?.cancel()
   ↓
4. Timer = null
   ↓
5. _isTracking = false
   ↓
6. _currentTripId = null
```

## Database Schema

### latest_bus_location
```sql
CREATE TABLE latest_bus_location (
  trip_id UUID PRIMARY KEY,
  route_id UUID,
  driver_id UUID,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  heading DOUBLE PRECISION,
  accuracy_m DOUBLE PRECISION,
  timestamp TIMESTAMP,
  updated_at TIMESTAMP
);
```

### gps_logs
```sql
CREATE TABLE gps_logs (
  id UUID PRIMARY KEY,
  trip_id UUID,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  heading DOUBLE PRECISION,
  accuracy_m DOUBLE PRECISION,
  timestamp TIMESTAMP,
  received_at TIMESTAMP
);
```

## Performance Considerations

- **Battery**: 15-second interval is reasonable for battery life
- **Network**: Each ping is ~200 bytes (minimal data usage)
- **Memory**: Timer is properly cleaned up (no leaks)
- **CPU**: Geolocator uses native platform APIs (efficient)

## Security

- Location permission required (user consent)
- Only streams during ACTIVE trips
- Backend validates trip exists and is ACTIVE
- No location data stored when trip is not active

## Compliance

- Follows Android location permission best practices
- Clear user communication about GPS usage
- Graceful degradation when permission denied
- No background location tracking (foreground only)

## Future Enhancements

Potential improvements (not in current scope):
- Background location tracking (requires different permissions)
- Configurable streaming interval
- Offline queue (store pings when offline, send when online)
- Battery optimization (reduce frequency when stationary)
- Location accuracy filtering (ignore low-accuracy readings)

## Status

✅ All requirements implemented and tested
✅ Permission handling complete
✅ Warning UI implemented
✅ 15-second streaming loop working
✅ API integration complete
✅ Error handling robust
✅ Cleanup guaranteed
✅ Ready for production use
