# GPS Streaming Troubleshooting Guide

## Current Situation

**Active Trip Found:**
- Trip ID: `5aa8b996-3c91-4d27-8f98-5f480c247206`
- Route ID: `4bcdf6d3-9353-4409-a880-9df4ce83bde5` (EPSTEIN ISLAND)
- Driver ID: `20000000-0000-0000-0000-000000000001`
- Status: ACTIVE
- Start Time: 2026-03-18 12:12:21

**Problem:**
- ❌ No GPS updates in `gps_logs` table
- ❌ No data in `latest_bus_location` table
- ❌ GPS streaming not working

## Diagnostic Steps

### 1. Check Flutter App Console

Look for these log messages in the Flutter console:

**Expected logs when trip starts:**
```
TripProvider: Trip started successfully - ID: 5aa8b996-3c91-4d27-8f98-5f480c247206, Status: ACTIVE
TripProvider: Starting GPS streaming for ACTIVE trip
GPS: Starting GPS streaming for trip: 5aa8b996-3c91-4d27-8f98-5f480c247206 (15-second interval)
GPS: Streaming update - Lat: XX.XXXXX, Lng: XX.XXXXX, Accuracy: XXm
GPS: Stream update successful - Trip: 5aa8b996-3c91-4d27-8f98-5f480c247206
```

**If you DON'T see these logs, the GPS service is not starting.**

### 2. Check Location Permissions

**On the phone:**
1. Go to Settings → Apps → TOS Driver App → Permissions
2. Verify "Location" is set to "Allow all the time" or "Allow only while using the app"

**In the app:**
- Look for an orange warning banner that says "GPS Disabled"
- If you see it, click "Enable" to grant permissions

### 3. Verify Backend is Receiving Requests

**Check backend logs for:**
```
[GIN] 2026/03/18 - XX:XX:XX | 200 | ... | POST "/api/v1/location/update"
```

**If you DON'T see these logs, the app is not sending GPS updates.**

### 4. Test Backend Endpoint Manually

Run this command to verify the backend can receive GPS updates:

```bash
curl -X POST http://192.168.1.101:8082/api/v1/location/update \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mock-token" \
  -d '{
    "trip_id": "5aa8b996-3c91-4d27-8f98-5f480c247206",
    "lat": 12.9716,
    "lng": 77.5946,
    "accuracy_m": 10.0,
    "timestamp": "2026-03-18T12:00:00Z"
  }'
```

**Expected response:**
```json
{"message":"Location updated successfully"}
```

**Then check database:**
```bash
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT * FROM latest_bus_location WHERE trip_id = '5aa8b996-3c91-4d27-8f98-5f480c247206';"
```

### 5. Common Issues and Solutions

#### Issue 1: GPS Service Not Starting

**Symptoms:**
- No "GPS: Starting GPS streaming" log
- No GPS updates in console

**Solution:**
1. Hot restart the Flutter app (press 'R')
2. Check if trip provider is calling GPS service
3. Verify GPS service is properly integrated

#### Issue 2: Location Permission Denied

**Symptoms:**
- Orange "GPS Disabled" warning banner
- Log: "GPS: Skipping update - no location permission"

**Solution:**
1. Grant location permissions in phone settings
2. Click "Enable" in the warning banner
3. Restart the app

#### Issue 3: Network Connectivity

**Symptoms:**
- Log: "GPS: Stream update failed - Status: XXX"
- Log: "GPS: Stream update error: ..."

**Solution:**
1. Verify phone is on same WiFi as laptop (192.168.1.x)
2. Check backend is running: `curl http://192.168.1.101:8082/health`
3. Verify firewall not blocking port 8082

#### Issue 4: GPS Hardware Not Working

**Symptoms:**
- Log: "GPS: Stream update error: TimeoutException"
- Can't get GPS coordinates

**Solution:**
1. Enable location services on phone
2. Go outside or near a window for better GPS signal
3. Test with Google Maps to verify GPS works

### 6. Force GPS Update (Manual Test)

If the automatic GPS streaming isn't working, you can manually trigger an update:

**In Flutter DevTools or add this code temporarily:**
```dart
// Manually trigger GPS update
final gpsService = ref.read(gpsServiceProvider);
await gpsService.startGpsStreaming('5aa8b996-3c91-4d27-8f98-5f480c247206');
```

### 7. Check Android Manifest

Verify location permissions are declared:

**File:** `android/app/src/main/AndroidManifest.xml`

Should contain:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### 8. Verify GPS Service Configuration

**Check:** `lib/services/gps_service.dart`

Should have:
- ✅ 15-second Timer.periodic
- ✅ POST to `/api/v1/location/update`
- ✅ JSON body with `trip_id`, `lat`, `lng`, `accuracy_m`, `timestamp`
- ✅ Proper error handling

### 9. Verify Trip Provider Integration

**Check:** `lib/providers/trip_provider.dart`

In `startTrip()` method, should have:
```dart
if (trip.status == TripStatus.ACTIVE) {
  final gpsService = _ref.read(gpsServiceProvider);
  await gpsService.startGpsStreaming(trip.id);
}
```

## Quick Fix Checklist

- [ ] Hot restart Flutter app
- [ ] Check Flutter console for GPS logs
- [ ] Verify location permissions granted
- [ ] Check phone is on same WiFi as laptop
- [ ] Verify backend is running and accessible
- [ ] Test backend endpoint with curl
- [ ] Check for orange "GPS Disabled" warning
- [ ] Verify trip status is ACTIVE in database
- [ ] Check backend logs for incoming requests
- [ ] Test GPS with Google Maps

## Expected Working Flow

```
1. User starts trip
   ↓
2. TripProvider.startTrip() called
   ↓
3. Backend creates trip with status ACTIVE
   ↓
4. TripProvider checks trip.status == ACTIVE
   ↓
5. TripProvider calls gpsService.startGpsStreaming(tripId)
   ↓
6. GPS service starts 15-second timer
   ↓
7. Every 15 seconds:
   - Get device GPS coordinates
   - POST to /api/v1/location/update
   - Backend saves to gps_logs and latest_bus_location
   ↓
8. Web portal fetches from /api/v1/tracking/live
   ↓
9. Map shows live location marker
```

## Debug Commands

```bash
# Check active trips
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT id, route_id, status, start_time FROM trips WHERE status = 'ACTIVE';"

# Check GPS logs for active trip
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT trip_id, latitude, longitude, received_at FROM gps_logs WHERE trip_id = '5aa8b996-3c91-4d27-8f98-5f480c247206' ORDER BY received_at DESC LIMIT 10;"

# Check latest bus location
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT * FROM latest_bus_location WHERE trip_id = '5aa8b996-3c91-4d27-8f98-5f480c247206';"

# Test backend health
curl http://192.168.1.101:8082/health

# Test GPS endpoint
curl -X POST http://192.168.1.101:8082/api/v1/location/update \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mock-token" \
  -d '{"trip_id":"5aa8b996-3c91-4d27-8f98-5f480c247206","lat":12.9716,"lng":77.5946,"accuracy_m":10.0,"timestamp":"2026-03-18T12:00:00Z"}'
```

## Next Steps

1. **Check Flutter console** - Look for GPS logs
2. **If no logs** - GPS service not starting, hot restart app
3. **If permission error** - Grant location permissions
4. **If network error** - Check WiFi and backend connectivity
5. **If still not working** - Share Flutter console logs for further diagnosis

---

**Current Status:** GPS streaming implemented but not sending updates
**Action Required:** Check Flutter console logs and verify location permissions
