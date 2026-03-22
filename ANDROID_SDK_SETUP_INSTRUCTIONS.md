# Android SDK Setup Instructions

The Android SDK has been downloaded and extracted. Now you need to complete the installation manually.

## Current Status

✓ Android command-line tools downloaded and extracted to `~/Android/Sdk/cmdline-tools/latest/`
✓ Flutter configured to use Android SDK location
✓ Device authorized by adb (RZ8NA142WTL)

## What's Missing

Flutter needs the full Android SDK components to build Android apps. The command-line tools are installed, but we need to install:
- platform-tools (includes adb, fastboot)
- Android platform (API 33)
- Build tools (version 33.0.0)

## Manual Installation Steps

Open a new terminal (not in Kiro) and run these commands:

```bash
# 1. Set environment variables
export ANDROID_HOME=~/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# 2. Accept Android licenses
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# 3. Install required SDK components
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# 4. Verify Flutter can see the device
~/flutter/bin/flutter devices

# 5. Run the app on your phone
~/flutter/bin/flutter run
```

## Add to Shell Configuration

To make these paths permanent, add to your `~/.config/fish/config.fish`:

```fish
set -gx ANDROID_HOME ~/Android/Sdk
set -gx PATH $PATH $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/platform-tools
set -gx PATH $PATH ~/flutter/bin
```

Or if you use bash, add to `~/.bashrc`:

```bash
export ANDROID_HOME=~/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
export PATH=$PATH:~/flutter/bin
```

## Verification

After running the setup commands, verify everything works:

```bash
# Check Flutter doctor
~/flutter/bin/flutter doctor -v

# Check if device is detected
~/flutter/bin/flutter devices

# Should show:
# • RZ8NA142WTL (mobile) • <device-id> • android-arm64 • Android <version>
```

## Troubleshooting

If `flutter devices` still doesn't show your phone:

1. Make sure you're in the `adbusers` group (already done)
2. Logout and login again for group membership to take effect
3. Reconnect your phone
4. Check `adb devices` shows your phone as "device" (not "unauthorized")

## Next Steps

Once the SDK is installed and `flutter devices` shows your phone, you can run:

```bash
cd ~/TOS-Drivers
~/flutter/bin/flutter run
```

This will build and install the app on your connected phone.
