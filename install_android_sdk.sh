#!/bin/sh

# Android SDK Installation Script
echo "Installing Android SDK components..."

export ANDROID_HOME=~/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# Accept all licenses automatically
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses 2>/dev/null || true

# Install required SDK components
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

echo ""
echo "✓ Android SDK components installed!"
echo ""
echo "Now configuring Flutter..."

# Configure Flutter to use Android SDK
~/flutter/bin/flutter config --android-sdk $ANDROID_HOME

echo ""
echo "Checking Flutter doctor..."
~/flutter/bin/flutter doctor -v

echo ""
echo "✓ Setup complete!"
echo ""
echo "To use Flutter in your current shell, run:"
echo "  export PATH=\"\$PATH:\$HOME/flutter/bin\""
echo "  export ANDROID_HOME=\$HOME/Android/Sdk"
echo "  export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools\""
