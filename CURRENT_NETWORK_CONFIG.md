# Current Network Configuration

**Last Updated**: March 22, 2026 - 23:00

## Current IP Address
- **Machine IP**: `192.168.1.101`
- **Backend Port**: `8082`
- **Backend URL**: `http://192.168.1.101:8082`

## Network Change History
1. **Initial Setup** (Pop-OS): `192.168.1.101:8082`
2. **After OS Switch** (CachyOS): `192.168.0.104:8082`
3. **After WiFi Change**: `192.168.1.101:8082` (current)

## Files Updated
- ✅ `lib/core/constants/app_constants.dart` - baseUrl
- ✅ `lib/providers/sse_provider.dart` - baseUrlProvider
- ✅ `lib/services/trip_service.dart` - default baseUrl

## Backend Status
- ✅ Backend running on port 8082
- ✅ Firewall allows port 8082
- ✅ Health check: `http://192.168.1.101:8082/health` returns `{"status":"ok"}`

## App Status
- ✅ Flutter app rebuilt with new IP
- ✅ APK installed on device (RZ8NA142WTL)
- ✅ Ready to login

## Test Credentials
- **Phone**: 1234567890 (or +1234567890)
- **OTP**: 123456

## Quick IP Change Procedure

When your IP changes (WiFi change, network switch, etc.):

1. **Check new IP**:
   ```bash
   ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1
   ```

2. **Update Flutter files**:
   - `lib/core/constants/app_constants.dart`
   - `lib/providers/sse_provider.dart`
   - `lib/services/trip_service.dart`

3. **Rebuild and install**:
   ```bash
   flutter build apk --debug
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

4. **Test backend**:
   ```bash
   curl http://YOUR_NEW_IP:8082/health
   ```

5. **Restart app on phone** (force close and reopen)

## Troubleshooting

If login still fails:
1. Verify phone is on same WiFi network
2. Check backend is running: `curl http://192.168.1.101:8082/health`
3. Check firewall: `sudo ufw status | grep 8082`
4. Clear app data on phone: Settings > Apps > TOS Driver > Storage > Clear Data
5. Reinstall app: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
