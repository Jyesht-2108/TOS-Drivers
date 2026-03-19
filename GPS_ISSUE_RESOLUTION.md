# GPS Streaming Issue - Resolution Plan

## Problem Confirmed ✅

**Backend Status:** ✅ Working correctly
- Endpoint `/api/v1/location/update` is functional
- Test GPS update successfully saved to database
- `gps_logs` and `latest_bus_location` tables are working

**Mobile App Status:** ❌ Not sending GPS updates
- Active trip exists: `5aa8b996-3c91-4d27-8f98-5f480c247206`
- Trip status: ACTIVE
- But NO GPS updates being sent from the mobile app

## Root Cause

The GPS streaming service is implemented but **not being triggered** when the trip starts. This could be due to:

1. App needs to be hot restarted after code changes
2. Location permissions not granted
3. GPS service not properly integrated with trip lifecycle
4. Network connectivity issue between phone and backend

## Immediate Action Required

### Step 1: Check Flutter Console Logs

**On your computer, look at the Flutter terminal where the app is running.**

Look for these specific log messages:

**When trip starts, you SHOULD see:**
```
TripProvider: Trip started successfully - ID: 5aa8b996-..., Status: ACTIVE
TripProvider: Starting GPS streaming for ACTIVE trip
GPS: Starting GPS streaming for trip: 5aa8b996-... (15-second interval)
GPS: Streaming update - Lat: XX.XXXXX, Lng: XX.XXXXX, Accuracy: XXm
GPS: Stream update successful - Trip: 5aa8b996-...
```

**If you see this instead:**
```
GPS: Skipping update - no location permission
```
→ Location permissions not granted

**If you see this:**
```
GPS: Stream update failed - Status: XXX
```
→ Network connectivity issue

**If you see NOTHING about GPS:**
→ GPS service not starting at all

### Step 2: Hot Restart the App

**IMPORTANT:** The code changes we made require a hot restart.

**In the Flutter terminal, press 'R' (capital R) to hot restart.**

Or restart the app completely on your phone.

### Step 3: Grant Location Permissions

**On your phone:**
1. Open the TOS Driver App
2. If you see an orange warning banner "GPS Disabled", click "Enable"
3. Grant location permissions when prompted
4. Select "Allow all the time" or "Allow while using the app"

**Or manually:**
1. Go to Settings → Apps → TOS Driver App → Permissions
2. Set Location to "Allow all the time"

### Step 4: Start a New Trip

After hot restarting and granting permissions:

1. Login with phone: `+1234567891`
2. Navigate to "My Routes"
3. Click "Start Trip" on your route
4. Select PICKUP or DROP

### Step 5: Monitor GPS Updates

**Watch the Flutter console for GPS logs every 15 seconds:**
```
GPS: Streaming update - Lat: XX.XXXXX, Lng: XX.XXXXX, Accuracy: XXm
GPS: Stream update successful - Trip: <trip-id>
```

**Watch the backend logs:**
```
[GIN] 2026/03/18 - XX:XX:XX | 200 | ... | POST "/api/v1/location/update"
```

**Check the database:**
```bash
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT COUNT(*) FROM gps_logs WHERE trip_id = '<your-new-trip-id>';"
```

Should show increasing count every 15 seconds.

## Verification Checklist

- [ ] Hot restarted Flutter app (pressed 'R')
- [ ] Location permissions granted on phone
- [ ] Started a new trip
- [ ] Checked Flutter console for GPS logs
- [ ] Verified GPS updates appearing every 15 seconds
- [ ] Checked backend logs for incoming requests
- [ ] Verified GPS data in database
- [ ] Web portal shows live tracking

## If Still Not Working

### Check 1: Flutter Console Output

**Share the Flutter console output** when you start a trip. Look for:
- Any error messages
- GPS-related logs
- Network errors
- Permission errors

### Check 2: Location Services

**On the phone:**
1. Open Google Maps
2. Verify your location is showing correctly
3. If Google Maps can't get location, GPS hardware issue

### Check 3: Network Connectivity

**Test from phone's browser:**
1. Open browser on phone
2. Navigate to: `http://192.168.1.101:8082/health`
3. Should show: `{"status":"ok"}`
4. If not, phone can't reach backend

### Check 4: App Logs

**Enable verbose logging:**
Look for these specific log patterns in Flutter console:
- `TripProvider:` - Trip lifecycle logs
- `GPS:` - GPS service logs
- `TripService:` - API call logs

## Expected Working Behavior

```
User Action                 → App Behavior                    → Backend/Database
─────────────────────────────────────────────────────────────────────────────
1. Start Trip              → POST /api/v1/trips/start       → Trip created (ACTIVE)
                           → GPS service starts              
                           
2. Every 15 seconds        → Get GPS coordinates             
                           → POST /api/v1/location/update   → Save to gps_logs
                                                             → Update latest_bus_location
                           
3. Web Portal              → GET /api/v1/tracking/live      → Fetch latest_bus_location
                           → Display on map                  → Show live marker
                           
4. End Trip                → GPS service stops               
                           → POST /api/v1/trips/end         → Trip status = ENDED
```

## Success Indicators

✅ **GPS Streaming Working:**
- Flutter console shows GPS updates every 15 seconds
- Backend logs show POST requests every 15 seconds
- Database `gps_logs` table has new rows every 15 seconds
- `latest_bus_location` table shows current position
- Web portal displays live marker on map

## Quick Test Commands

```bash
# Check if trip is still active
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT id, status, start_time FROM trips WHERE status = 'ACTIVE';"

# Check GPS logs count (should increase)
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT trip_id, COUNT(*) as updates FROM gps_logs GROUP BY trip_id ORDER BY updates DESC;"

# Check latest location
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT trip_id, latitude, longitude, updated_at FROM latest_bus_location ORDER BY updated_at DESC LIMIT 5;"

# Test backend health
curl http://192.168.1.101:8082/health

# Watch backend logs in real-time
# (In backend terminal, you'll see requests coming in)
```

## Summary

**What's Working:**
- ✅ Backend GPS endpoint
- ✅ Database storage
- ✅ Trip creation
- ✅ GPS service implementation

**What's Not Working:**
- ❌ Mobile app not sending GPS updates
- ❌ GPS service not starting when trip begins

**Most Likely Cause:**
- App needs hot restart after code changes
- Location permissions not granted

**Next Step:**
1. **Hot restart the app** (press 'R' in Flutter terminal)
2. **Grant location permissions**
3. **Start a new trip**
4. **Check Flutter console for GPS logs**

---

**Status:** Ready for testing after hot restart
**Action Required:** Hot restart app and verify GPS logs appear
