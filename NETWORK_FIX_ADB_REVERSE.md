# Network Connection Fix - ADB Reverse Port Forwarding

## Problem Identified
Your phone and computer were on different networks:
- Computer: `192.168.1.101` (192.168.1.x network)
- Phone: `192.168.7.21` (192.168.7.x network)

This prevented the phone from reaching the backend server.

## Solution Applied: ADB Reverse Port Forwarding

Instead of requiring both devices to be on the same WiFi network, we're using ADB's reverse port forwarding feature. This tunnels the backend connection through the USB cable.

### What Was Changed

1. **Set up ADB reverse:**
   ```bash
   adb reverse tcp:8082 tcp:8082
   ```
   This makes port 8082 on the phone forward to port 8082 on the computer.

2. **Updated app configuration to use `10.0.2.2`:**
   - `lib/core/constants/app_constants.dart` - Changed baseUrl to `http://10.0.2.2:8082`
   - `lib/providers/sse_provider.dart` - Changed baseUrlProvider to `http://10.0.2.2:8082`
   - `lib/services/trip_service.dart` - Changed default baseUrl to `http://10.0.2.2:8082`

3. **Rebuilt and installed the app**

### Why 10.0.2.2?

`10.0.2.2` is a special IP address that Android uses to refer to the host machine when using ADB. Combined with `adb reverse`, it routes traffic through the USB connection.

## How to Use

### Every time you connect your phone:

1. **Connect phone via USB**
2. **Enable ADB reverse:**
   ```bash
   adb reverse tcp:8082 tcp:8082
   ```
3. **Verify it's working:**
   ```bash
   adb reverse --list
   ```
   Should show: `tcp:8082 tcp:8082`

4. **Start the backend** (if not already running):
   ```bash
   cd backend
   ./tos-backend
   ```

5. **Launch the app and login**

### Automatic Setup Script

Created `setup_adb_reverse.sh` for easy setup:
```bash
./setup_adb_reverse.sh
```

## Advantages of This Approach

✅ Works regardless of WiFi network
✅ No need to update IP addresses when network changes
✅ More reliable connection through USB
✅ No firewall configuration needed
✅ Works even without WiFi

## Disadvantages

❌ Requires USB cable connection
❌ Need to run `adb reverse` after each phone reconnection
❌ Won't work for wireless testing

## Alternative Solutions

If you need wireless testing:

### Option 1: Same WiFi Network
1. Connect both phone and computer to the same WiFi
2. Update app config to use computer's IP (e.g., `192.168.1.101`)
3. Ensure firewall allows port 8082

### Option 2: USB Tethering
1. Enable USB tethering on phone
2. Computer will get IP in phone's network
3. Update app config to use that IP

### Option 3: WiFi Hotspot
1. Create hotspot on computer
2. Connect phone to that hotspot
3. Use computer's hotspot IP in app config

## Troubleshooting

### If login still fails:

1. **Check ADB reverse is active:**
   ```bash
   adb reverse --list
   ```

2. **Test from phone:**
   ```bash
   adb shell "curl http://10.0.2.2:8082/health"
   ```
   Should return: `{"status":"ok"}`

3. **Check backend is running:**
   ```bash
   curl http://localhost:8082/health
   ```

4. **Reconnect phone and retry:**
   ```bash
   adb kill-server
   adb start-server
   adb reverse tcp:8082 tcp:8082
   ```

### If you disconnect and reconnect the phone:

You must run `adb reverse tcp:8082 tcp:8082` again. The reverse forwarding is lost when the USB connection is broken.

## Current Status

✅ ADB reverse configured
✅ App updated to use 10.0.2.2
✅ App rebuilt and installed
✅ Backend running on port 8082
✅ Ready to test login

## Test Credentials

- Phone: `1234567890` or `+1234567890`
- OTP: Any value (backend validates phone only)
