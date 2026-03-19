# Mobile App GPS Debugging - Step by Step

## Current Situation
- ✅ Trip is ACTIVE in database
- ✅ Location permissions granted on phone
- ✅ Backend endpoint works (tested with curl)
- ❌ Mobile app NOT sending GPS updates

## Critical Question: Did you HOT RESTART the app?

**The GPS code changes require a hot restart to take effect.**

### How to Hot Restart:
1. In the terminal where Flutter is running
2. Press **'R'** (capital R)
3. Wait for "Restarted application in XXXms"

**OR**

1. Stop the app completely on your phone
2. In terminal: `flutter run`
3. Wait for app to launch

## Step-by-Step Debugging

### Step 1: Verify App Can Reach Backend

**On your phone, open a web browser and navigate to:**
```
http://192.168.1.101:8082/health
```

**Expected result:** `{"status":"ok"}`

**If you get an error:**
- Phone is not on the same WiFi network
- Backend is not accessible from phone
- Firewall blocking connection

### Step 2: Check Flutter Console Output

**CRITICAL: You must look at the Flutter console when you start a trip.**

**In the terminal where Flutter is running, you should see:**

When you click "Start Trip":
```
TripService: Starting trip - URL: http://192.168.1.101:8082/api/v1/trips/start, RouteID: ..., Type: ...
TripService: Response status: 201
TripService: Response body: {"id":"...","status":"ACTIVE",...}
TripProvider: Trip started successfully - ID: ..., Status: ACTIVE
TripProvider: Starting GPS streaming for ACTIVE trip
GPS: Starting GPS streaming for trip: ... (15-second interval)
GPS: Streaming update - Lat: XX.XXXXX, Lng: XX.XXXXX, Accuracy: XXm
GPS: Stream update successful - Trip: ...
```

**What do you actually see?**

### Step 3: Common Issues

#### Issue A: No GPS logs at all

**If you see NOTHING about GPS in the console:**

The GPS service is not being called. This means:
1. App was not hot restarted after code changes
2. Trip provider is not calling GPS service

**Fix:**
```bash
# In Flutter terminal, press 'R' to hot restart
# Then start a new trip
```

#### Issue B: "GPS: Skipping update - no location permission"

**If you see this log:**

Location permissions are not properly granted.

**Fix:**
1. On phone: Settings → Apps → TOS Driver App → Permissions → Location
2. Set to "Allow all the time"
3. Restart the app

#### Issue C: "GPS: Stream update failed - Status: XXX"

**If you see this log:**

The app is trying to send GPS updates but the backend is rejecting them.

**Check:**
- Backend logs for error messages
- Network connectivity
- Endpoint URL is correct

#### Issue D: "GPS: Stream update error: ..."

**If you see this log:**

Network error or GPS hardware issue.

**Check:**
- Phone can reach backend (test with browser)
- GPS is working (test with Google Maps)
- WiFi connection is stable

### Step 4: Manual Test

**Add this temporary code to test GPS manually:**

Create a test button in the app that calls:
```dart
final gpsService = ref.read(gpsServiceProvider);
await gpsService.requestLocationPermissions();
await gpsService.startGpsStreaming('5aa8b996-3c91-4d27-8f98-5f480c247206');
```

This will help isolate if the issue is with trip integration or GPS service itself.

### Step 5: Check Android Manifest

**File:** `android/app/src/main/AndroidManifest.xml`

Verify these permissions exist:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Step 6: Check pubspec.yaml

Verify geolocator package is installed:
```yaml
dependencies:
  geolocator: ^10.1.0  # or latest version
```

If missing, run:
```bash
flutter pub get
```

## What to Share for Further Debugging

Please provide:

1. **Flutter Console Output** when you start a trip (copy/paste the entire output)
2. **Any error messages** you see in red
3. **Result of browser test** (http://192.168.1.101:8082/health from phone)
4. **Confirmation** that you hot restarted the app (pressed 'R')
5. **Location permission status** (Settings → Apps → TOS Driver App → Permissions)

## Quick Verification Commands

```bash
# Check if new GPS logs are appearing
watch -n 5 'PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT COUNT(*) FROM gps_logs WHERE trip_id = '\''5aa8b996-3c91-4d27-8f98-5f480c247206'\'';"'

# This will refresh every 5 seconds and show the count
# If GPS is working, the count should increase
```

## Expected Timeline

If GPS streaming is working:
- **T+0s:** Trip starts, GPS service starts
- **T+0s:** First GPS update sent immediately
- **T+15s:** Second GPS update
- **T+30s:** Third GPS update
- **T+45s:** Fourth GPS update
- ... continues every 15 seconds

## Most Likely Issue

Based on the symptoms, the most likely issue is:

**The app was not hot restarted after the GPS code changes.**

The GPS streaming code is there, but the running app doesn't have it yet.

**Solution:**
1. Press 'R' in Flutter terminal to hot restart
2. Or completely restart the app
3. Start a new trip
4. Watch the console for GPS logs

---

**Next Step:** Hot restart the app and share the Flutter console output when you start a trip.
