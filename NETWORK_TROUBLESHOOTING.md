# Network Troubleshooting Guide - TOS Driver App

## Current Configuration
- **Backend IP:** 192.168.1.101
- **Backend Port:** 8082
- **Backend Status:** ✅ Running and accessible
- **Device:** Physical Android device (SM A217F)

## Issue: "Connection timeout - Check if backend is accessible"

### Quick Fixes

#### 1. Verify Phone and Computer are on Same WiFi Network

**On Your Computer:**
```bash
ip addr show | grep "inet " | grep -v "127.0.0.1"
```
Current IP: `192.168.1.101`

**On Your Phone:**
- Go to Settings → WiFi
- Check the connected network name
- Make sure it matches your computer's WiFi network
- Check the phone's IP address (should be 192.168.1.xxx)

#### 2. Test Backend Connectivity from Phone

**Option A: Use a browser on your phone**
- Open Chrome/Firefox on your phone
- Navigate to: `http://192.168.1.101:8082/health`
- You should see: `{"status":"ok"}`
- If this works, the network is fine

**Option B: Use a network testing app**
- Install "Network Analyzer" or similar app
- Ping `192.168.1.101`
- Test port `8082`

#### 3. Check if Backend is Running

```bash
# Check if backend process is running
ps aux | grep tos-backend | grep -v grep

# Check if port 8082 is listening
ss -tuln | grep 8082

# Test backend locally
curl http://192.168.1.101:8082/health
```

Expected output: `{"status":"ok"}`

#### 4. Restart Backend

```bash
cd backend
./tos-backend
```

Or if using go run:
```bash
cd backend
go run main.go
```

### Common Issues and Solutions

#### Issue 1: Phone on Different Network
**Symptoms:** Connection timeout
**Solution:** 
- Connect phone to same WiFi as computer
- Or use USB tethering
- Or update IP address in app config

#### Issue 2: Computer IP Changed
**Symptoms:** Connection timeout after computer restart
**Solution:**
```bash
# Check current IP
ip addr show | grep "inet " | grep -v "127.0.0.1"

# Update app configuration
# Edit: lib/core/constants/app_constants.dart
# Change: static const String baseUrl = 'http://YOUR_NEW_IP:8082';
```

#### Issue 3: Backend Not Running
**Symptoms:** Connection refused or timeout
**Solution:**
```bash
cd backend
./tos-backend
# or
go run main.go
```

#### Issue 4: Port Already in Use
**Symptoms:** Backend fails to start
**Solution:**
```bash
# Find process using port 8082
lsof -i :8082
# or
ss -tulpn | grep 8082

# Kill the process
kill -9 <PID>

# Restart backend
cd backend
./tos-backend
```

#### Issue 5: Firewall Blocking Connection
**Symptoms:** Connection timeout from phone, but works on computer
**Solution:**
```bash
# Check firewall status
sudo ufw status

# If active, allow port 8082
sudo ufw allow 8082/tcp

# Or temporarily disable firewall for testing
sudo ufw disable
```

### Alternative Connection Methods

#### Method 1: Use USB Debugging with Port Forwarding

```bash
# Enable USB debugging on phone
# Connect phone via USB
# Forward port from phone to computer
adb reverse tcp:8082 tcp:8082
```

Then update app config to use `localhost`:
```dart
// lib/core/constants/app_constants.dart
static const String baseUrl = 'http://localhost:8082';
```

#### Method 2: Use ngrok (for remote testing)

```bash
# Install ngrok
# Run ngrok
ngrok http 8082

# Use the ngrok URL in app config
# Example: https://abc123.ngrok.io
```

### Testing Checklist

- [ ] Backend is running (`curl http://192.168.1.101:8082/health`)
- [ ] Phone and computer on same WiFi network
- [ ] Phone can access backend (`http://192.168.1.101:8082/health` in phone browser)
- [ ] App configuration has correct IP address
- [ ] No firewall blocking port 8082
- [ ] Backend logs show no errors

### Debug Mode

To see detailed network logs in the app:

1. Check Flutter console output when login fails
2. Look for lines starting with "Auth:"
3. Check the exact URL being called
4. Check the error message

Example logs:
```
Auth: Attempting login to http://192.168.1.101:8082/api/v1/auth/login with phone: +1234567891
Auth: Response status: 200
Auth: Login successful for John Anderson
```

### Quick Test Script

Save this as `test_connection.sh`:

```bash
#!/bin/bash
echo "=== TOS Backend Connection Test ==="
echo ""
echo "1. Checking backend process..."
ps aux | grep tos-backend | grep -v grep && echo "✅ Backend running" || echo "❌ Backend not running"
echo ""
echo "2. Checking port 8082..."
ss -tuln | grep 8082 && echo "✅ Port 8082 listening" || echo "❌ Port 8082 not listening"
echo ""
echo "3. Testing health endpoint..."
curl -s http://192.168.1.101:8082/health && echo "" && echo "✅ Backend responding" || echo "❌ Backend not responding"
echo ""
echo "4. Testing login endpoint..."
curl -s -X POST http://192.168.1.101:8082/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"+1234567891"}' | head -c 100 && echo "" && echo "✅ Login endpoint working" || echo "❌ Login endpoint not working"
echo ""
echo "5. Your computer's IP addresses:"
ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}'
echo ""
echo "=== Test Complete ==="
```

Run it:
```bash
chmod +x test_connection.sh
./test_connection.sh
```

### Still Not Working?

If none of the above works, try:

1. **Use ADB reverse (recommended for development):**
   ```bash
   adb reverse tcp:8082 tcp:8082
   ```
   Then change app config to use `http://localhost:8082`

2. **Check phone's network settings:**
   - Disable mobile data
   - Ensure WiFi is connected
   - Check if WiFi has internet access

3. **Try a different port:**
   - Change backend to port 8080
   - Update app configuration
   - Restart both backend and app

4. **Check backend logs:**
   ```bash
   cd backend
   ./tos-backend 2>&1 | tee backend.log
   ```
   Look for any errors or connection attempts

### Contact Information

If you're still having issues, provide:
- Output of `test_connection.sh`
- Phone's IP address (from WiFi settings)
- Computer's IP address
- Backend logs
- App error message (exact text)
