# Android Device Setup Guide

## Current Status

✅ Phone connected via USB: `RZ8NA142WTL`  
❌ Status: **unauthorized**  
❌ Flutter cannot see the device yet

---

## Fix: Authorize USB Debugging

### Step 1: Check Your Phone

Look at your phone screen right now. You should see a popup asking:

```
Allow USB debugging?
The computer's RSA key fingerprint is:
XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX

[ ] Always allow from this computer
[Cancel] [OK]
```

### Step 2: Authorize the Connection

1. **Check the box** "Always allow from this computer"
2. **Tap "OK"**

### Step 3: Verify Connection

After authorizing, run:

```bash
adb devices
```

You should now see:
```
List of devices attached
RZ8NA142WTL     device
```

(Notice it says "device" instead of "unauthorized")

---

## If You Don't See the Popup

### Option 1: Revoke and Retry

On your phone:
1. Go to **Settings**
2. **Developer options**
3. **Revoke USB debugging authorizations**
4. Unplug and replug the USB cable
5. The popup should appear again

### Option 2: Check USB Debugging is Enabled

On your phone:
1. Go to **Settings**
2. **About phone**
3. Tap **Build number** 7 times (enables Developer options)
4. Go back to **Settings**
5. **Developer options**
6. Enable **USB debugging**
7. Unplug and replug the USB cable

### Option 3: Try Different USB Mode

When you plug in the USB cable, you might see a notification:
- Tap the notification
- Select **File Transfer** or **PTP** mode
- Then check for the authorization popup

---

## After Authorization

### Verify Device is Detected

```bash
# Check with adb
adb devices

# Check with Flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter devices
```

You should see your phone listed:
```
Found 2 connected devices:
  SM A217F (mobile) • RZ8NA142WTL • android-arm64 • Android 12 (API 31)
  Linux (desktop)   • linux       • linux-x64     • CachyOS 6.19.7-1-cachyos
```

### Run Flutter App on Phone

```bash
export PATH="$PATH:$HOME/flutter/bin"
flutter run
```

Flutter will automatically select your phone if it's the only mobile device connected.

Or specify explicitly:
```bash
flutter run -d RZ8NA142WTL
```

---

## Troubleshooting

### Device Still Shows "unauthorized"

1. **Revoke authorizations:**
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

2. **Check the popup on your phone again**

### Device Not Detected at All

1. **Check USB cable:**
   - Try a different USB cable
   - Some cables are charge-only (no data)

2. **Check USB port:**
   - Try a different USB port on your computer

3. **Check phone settings:**
   - USB debugging must be enabled
   - Some phones have additional security settings

### Permission Denied Errors

Add your user to the plugdev group:
```bash
sudo usermod -aG plugdev $USER
```

Then logout and login again.

### udev Rules (if needed)

Create udev rules for Android devices:
```bash
sudo tee /etc/udev/rules.d/51-android.rules > /dev/null <<'EOF'
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger
```

Then unplug and replug your phone.

---

## Quick Test

Once authorized, test the connection:

```bash
# Test adb
adb shell echo "Hello from phone"

# Test Flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter devices

# Run app
flutter run
```

---

## Expected Output

### adb devices (after authorization)
```
List of devices attached
RZ8NA142WTL     device
```

### flutter devices (after authorization)
```
Found 2 connected devices:
  SM A217F (mobile) • RZ8NA142WTL • android-arm64 • Android 12 (API 31)
  Linux (desktop)   • linux       • linux-x64     • CachyOS 6.19.7-1-cachyos
```

### flutter run (after authorization)
```
Launching lib/main.dart on SM A217F in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk.
Installing build/app/outputs/flutter-apk/app-debug.apk...
Waiting for SM A217F to report its views...
Syncing files to device SM A217F...
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

An Observatory debugger and profiler on SM A217F is available at: http://127.0.0.1:XXXXX/
The Flutter DevTools debugger and profiler on SM A217F is available at: http://127.0.0.1:XXXXX/
```

---

## Summary

**Current Issue:** Phone is connected but unauthorized

**Solution:** 
1. Look at your phone screen
2. Tap "OK" on the USB debugging authorization popup
3. Check "Always allow from this computer"

**After Authorization:**
```bash
export PATH="$PATH:$HOME/flutter/bin"
flutter run
```

The app will install and run on your phone!

---

**Device:** SM A217F (RZ8NA142WTL)  
**Status:** Connected but needs authorization  
**Next Step:** Check your phone screen for the popup
