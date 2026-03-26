#!/bin/bash

echo "Testing Phone Connection to Backend..."
echo ""

# Check if device is connected
echo "1. Checking device connection..."
DEVICE=$(adb devices | grep -w "device" | grep -v "List of devices")
if [ -z "$DEVICE" ]; then
    echo "❌ No device connected!"
    echo "   Please connect your phone via USB and enable USB debugging"
    exit 1
fi
echo "✓ Device connected: $(echo $DEVICE | awk '{print $1}')"
echo ""

# Check backend
echo "2. Checking backend server..."
if curl -s http://localhost:8082/health > /dev/null; then
    echo "✓ Backend is running on port 8082"
else
    echo "❌ Backend is not responding!"
    echo "   Start it with: cd backend && go run main.go"
    exit 1
fi
echo ""

# Setup ADB reverse
echo "3. Setting up ADB reverse port forwarding..."
adb reverse tcp:8082 tcp:8082
echo "✓ Port forwarding active: phone localhost:8082 → computer localhost:8082"
echo ""

# List all reverse ports
echo "4. Active port forwards:"
adb reverse --list
echo ""

echo "✅ Everything is ready!"
echo ""
echo "Now you can run:"
echo "  flutter run"
echo ""
echo "The app will connect to http://127.0.0.1:8082 on the phone,"
echo "which forwards to your computer's backend server."
