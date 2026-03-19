# GPS Streaming Feature - Testing Guide

## Current Status: ✅ READY FOR TESTING

All GPS streaming functionality has been implemented and bugs have been fixed.

## Recent Fixes Applied

### 1. Trip Start/End Issues ✅
- Fixed backend `StartTrip` handler parameter mismatch
- Fixed backend `EndTrip` handler to return full trip object
- Fixed Flutter Trip model to handle both camelCase and snake_case field names
- Added comprehensive logging throughout the trip lifecycle

### 2. State Synchronization ✅
- Fixed issue where app showed stale "active trip" state
- Added automatic state clearing when trip is already ended
- Improved error handling to distinguish between network errors and "trip not found" errors

### 3. GPS Streaming Integration ✅
- GPS streaming starts automatically when trip status is ACTIVE
- GPS streaming stops automatically when trip ends
- 15-second interval as per PRD requirements
- Proper cleanup on trip end

## How to Test the Complete Flow

### Prerequisites
- ✅ Backend running: `cd backend && go run main.go`
- ✅ Flutter app running on physical device
- ✅ Phone and laptop on same WiFi network (192.168.1.x)
- ✅ Location permissions granted on phone

### Step-by-Step Testing

#### 1. Login
```
Phone: +1234567891 (Driver 1: John Anderson)
OTP: Any 6 digits (e.g., 123456)
```

#### 2. View Routes
- You should see "Route A - Morning" assigned to you
- If GPS permission not granted, you'll see an orange warning banner
- Grant permission if prompted

#### 3. Start a Trip
- Click "Start Trip" on Route A
- Select trip type: PICKUP or DROP
- Click confirm

**Expected Backend Logs:**
```
StartTrip: RouteID=50000000-0000-0000-0000-000000000001, DriverID=20000000-0000-0000-0000-000000000001, TripType=PICKUP
[GIN] 2026/03/18 - XX:XX:XX | 201 | ... | POST "/api/v1/trips/start"
```

**Expected App Behavior:**
- Trip starts successfully
- GPS streaming begins automatically
- You'll see GPS updates in console every 15 seconds

#### 4. Monitor GPS Streaming

**In Flutter Console:**
```
GPS: Starting GPS streaming for trip: <trip-id> (15-second interval)
GPS: Streaming update - Lat: XX.XXXXX, Lng: XX.XXXXX, Accuracy: XXm
GPS: Stream update successful - Trip: <trip-id>
```

**In Backend Logs:**
```
[GIN] 2026/03/18 - XX:XX:XX | 200 | ... | POST "/api/v1/location/update"
```

**Check Database:**
```bash
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT * FROM latest_bus_location;"
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT * FROM gps_logs ORDER BY received_at DESC LIMIT 5;"
```

#### 5. End the Trip
- Click "End Trip"
- Confirm

**Expected Backend Logs:**
```
EndTrip: Attempting to end trip ID: <trip-id>
EndTrip: Successfully ended trip ID: <trip-id>
[GIN] 2026/03/18 - XX:XX:XX | 200 | ... | POST "/api/v1/trips/end"
```

**Expected App Behavior:**
- Trip ends successfully
- GPS streaming stops immediately
- No more GPS updates sent
- Trip status changes to ENDED

#### 6. Verify GPS Stopped
- Wait 20+ seconds
- Check that no more GPS updates appear in logs
- Verify cleanup happened

## Common Issues & Solutions

### Issue: "Network error: Unable to start trip"

**Solution:**
1. Check backend is running: `curl http://192.168.1.101:8082/health`
2. Check phone is on same WiFi
3. Hot restart Flutter app (press 'R')
4. Check backend logs for actual error

### Issue: "Trip not found or already ended"

**Solution:**
1. The trip was already ended (state sync issue)
2. Hot restart the Flutter app to clear stale state
3. Start a fresh trip

**Or manually clear:**
```bash
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "UPDATE trips SET status = 'ENDED', end_time = NOW() WHERE status = 'ACTIVE';"
```

### Issue: GPS updates not appearing

**Check:**
1. Location permission granted? (Look for orange warning banner)
2. Trip status is ACTIVE? (Check backend logs)
3. GPS service started? (Check Flutter console for "Starting GPS streaming")
4. Network connectivity? (Phone can reach laptop)

**Debug:**
```bash
# Check if GPS updates are reaching backend
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT COUNT(*) FROM gps_logs WHERE trip_id = '<your-trip-id>';"
```

### Issue: Can't start a new trip

**Cause:** There's already an ACTIVE trip

**Solution:**
```bash
# Check for active trips
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT id, status FROM trips WHERE status = 'ACTIVE';"

# End all active trips
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "UPDATE trips SET status = 'ENDED', end_time = NOW() WHERE status = 'ACTIVE';"
```

## Testing Checklist

- [ ] Login works with correct credentials
- [ ] Location permission requested on login/route view
- [ ] Warning banner shows if permission denied
- [ ] Can start a trip successfully
- [ ] GPS streaming starts automatically (check logs)
- [ ] GPS updates sent every 15 seconds
- [ ] GPS coordinates are real (from phone's GPS)
- [ ] GPS updates stored in database
- [ ] Can end trip successfully
- [ ] GPS streaming stops when trip ends
- [ ] No GPS updates after trip ends
- [ ] Can start a new trip after ending previous one
- [ ] App handles network errors gracefully
- [ ] App handles "trip already ended" gracefully

## Database Queries for Verification

```bash
# Check active trips
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT id, route_id, trip_type, status, start_time FROM trips WHERE status = 'ACTIVE';"

# Check recent trips
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT id, route_id, trip_type, status, start_time, end_time FROM trips ORDER BY start_time DESC LIMIT 5;"

# Check GPS logs for a specific trip
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT latitude, longitude, accuracy_m, received_at FROM gps_logs WHERE trip_id = '<trip-id>' ORDER BY received_at DESC LIMIT 10;"

# Check latest bus location
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT trip_id, latitude, longitude, accuracy_m, updated_at FROM latest_bus_location;"

# Count GPS updates per trip
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT trip_id, COUNT(*) as update_count FROM gps_logs GROUP BY trip_id ORDER BY update_count DESC;"
```

## Success Criteria

✅ GPS streaming feature is working correctly if:
1. Trip starts successfully with status ACTIVE
2. GPS updates appear in logs every 15 seconds
3. GPS coordinates are real (from phone's GPS sensor)
4. Updates are stored in `gps_logs` and `latest_bus_location` tables
5. Trip ends successfully with status ENDED
6. GPS streaming stops immediately after trip ends
7. No errors or crashes during the entire flow

## Next Steps After Testing

Once testing is complete and everything works:
1. Test with actual movement (walk/drive around)
2. Test with poor network conditions
3. Test with GPS disabled (should show warning but not crash)
4. Test multiple start/end cycles
5. Consider battery optimization strategies
6. Plan for production deployment (cloud backend)

---

**Last Updated:** 2026-03-18
**Status:** Ready for comprehensive testing
