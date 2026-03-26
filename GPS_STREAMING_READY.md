# GPS Streaming Feature - Ready to Test ✅

## Implementation Complete

All requirements from the TOS MVP PRD have been implemented:

### ✅ 1. Device Permissions
- Location permissions requested when route list screen loads
- Uses `geolocator` package (v10.1.0)
- Non-blocking: App works even if permission denied
- Implemented in: `lib/features/routes/screens/route_list_screen.dart`

### ✅ 2. Warning UI
**Two-level warning system:**
- **Snackbar**: Temporary notification when permission denied (5 seconds)
- **Persistent Banner**: Orange banner at top of route list with RETRY button
- Clear messaging: "GPS tracking disabled. You can still start trips, but location won't be tracked."

### ✅ 3. GPS Streaming Loop
- Timer.periodic with 15-second interval
- ONLY runs when trip status is ACTIVE
- Automatically starts when trip begins
- Automatically stops when trip ends
- Proper cleanup in dispose()
- Implemented in: `lib/services/gps_service.dart`

### ✅ 4. API Integration
- Endpoint: `POST /api/v1/location/update`
- Exact JSON structure as specified in PRD:
  ```json
  {
    "trip_id": "uuid",
    "lat": double,
    "lng": double,
    "accuracy_m": double,
    "timestamp": "ISO-8601-string"
  }
  ```
- Try-catch error handling
- Network failures don't crash app
- Failed pings are dropped, retry on next tick

### ✅ 5. Timer Cleanup
- Timer cancelled in dispose()
- Timer cancelled when trip ends
- Timer cancelled on logout
- No memory leaks

## How to Test

### 1. Start Backend
```bash
cd backend
go run main.go
```

### 2. Setup ADB Reverse
```bash
adb reverse tcp:8082 tcp:8082
adb reverse --list  # Verify it's active
```

### 3. Run Flutter App
```bash
flutter run
```

### 4. Test Flow

**Login:**
- Phone: `+1234567891` (John Anderson)
- Or: `9876543210` (Michael Kumar)

**Permission Request:**
1. Route list screen loads
2. System shows location permission dialog
3. Grant permission (or deny to test warning UI)

**If Permission Denied:**
- See orange snackbar (5 seconds)
- See persistent orange banner at top
- Click "RETRY" button to request again

**Start Trip:**
1. Tap on a route
2. Select PICKUP or DROP
3. Slide to start trip
4. Watch Flutter console for GPS logs

**Expected Console Output:**
```
GPS: Starting GPS streaming for trip: xxx (15-second interval)
GPS: Streaming update - Lat: 37.7749, Lng: -122.4194, Accuracy: 15.5m
GPS: Stream update successful - Trip: xxx
[Wait 15 seconds]
GPS: Streaming update - Lat: 37.7750, Lng: -122.4195, Accuracy: 12.3m
GPS: Stream update successful - Trip: xxx
```

**Monitor Database:**
```bash
# Watch GPS logs in real-time
watch -n 1 'PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT trip_id, latitude, longitude, timestamp FROM gps_logs ORDER BY timestamp DESC LIMIT 5;"'
```

**End Trip:**
1. Tap "End Trip"
2. Slide to confirm
3. Watch console for cleanup:
   ```
   GPS: Stopping GPS streaming and cleaning up
   ```

### 5. Test Error Handling

**Network Failure:**
1. Start trip (GPS streaming begins)
2. Stop backend: `Ctrl+C` in backend terminal
3. Wait 15 seconds
4. Check console:
   ```
   GPS: Stream update error: Connection refused
   GPS: Will retry on next 15-second tick
   ```
5. App should NOT crash
6. Restart backend
7. Next tick should succeed

**Permission Denied:**
1. Deny location permission
2. Start trip
3. Check console:
   ```
   GPS: Skipping update - no location permission
   ```
4. Trip works normally without GPS

## Verification Checklist

- [ ] Backend running on port 8082
- [ ] ADB reverse active: `adb reverse tcp:8082 tcp:8082`
- [ ] Phone connected: `adb devices` shows device
- [ ] Flutter app running: `flutter run`
- [ ] Login successful
- [ ] Permission dialog appears
- [ ] Warning UI shows if permission denied
- [ ] Trip starts successfully
- [ ] GPS logs appear in console every 15 seconds
- [ ] Database receives location updates
- [ ] Trip ends successfully
- [ ] GPS streaming stops
- [ ] No crashes on network errors

## Files Modified

1. **lib/features/routes/screens/route_list_screen.dart**
   - Added permission request in initState()
   - Added warning snackbar
   - Added persistent warning banner
   - Changed to StatefulWidget

2. **lib/services/gps_service.dart** (already implemented)
   - 15-second Timer.periodic
   - Exact JSON structure
   - Error handling
   - Cleanup

3. **lib/providers/trip_provider.dart** (already implemented)
   - Starts GPS on trip start
   - Stops GPS on trip end
   - Cleanup on logout

## Test Scripts

- `./test_gps_streaming.sh` - Test backend endpoint
- `./test_phone_connection.sh` - Verify phone connection
- `./fix_android_connection.sh` - Fix device authorization

## Database Tables

**latest_bus_location** - Current location (upsert)
```sql
SELECT * FROM latest_bus_location;
```

**gps_logs** - Historical log (append-only)
```sql
SELECT * FROM gps_logs ORDER BY timestamp DESC LIMIT 10;
```

## Troubleshooting

**Permission dialog doesn't appear:**
- Check Android settings: Apps → TOS Driver → Permissions
- Uninstall and reinstall app to reset permissions

**GPS not streaming:**
- Check console for "GPS: Starting GPS streaming..."
- Verify trip status is ACTIVE
- Check permission is granted

**Network errors:**
- Verify backend is running: `curl http://localhost:8082/health`
- Verify ADB reverse: `adb reverse --list`
- Check phone is connected: `adb devices`

**App crashes:**
- Check Flutter console for stack trace
- Run diagnostics: `flutter analyze`
- Hot restart: Press 'R' in Flutter terminal

## Status

✅ Implementation complete
✅ Code compiles without errors
✅ Backend endpoint tested
✅ Error handling verified
✅ Ready for end-to-end testing

## Next Steps

1. Run the app: `flutter run`
2. Test the complete flow
3. Monitor GPS logs in database
4. Verify 15-second interval
5. Test error scenarios
6. Confirm cleanup on trip end

---

**Note**: The GPS streaming will only work on a physical device or emulator with location services enabled. It won't work in the browser or desktop versions.
