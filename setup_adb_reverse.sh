#!/bin/bash

echo "=========================================="
echo "ADB Reverse Port Forwarding Setup"
echo "=========================================="
echo ""

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device connected via USB"
    echo ""
    echo "Please:"
    echo "1. Connect your phone via USB"
    echo "2. Enable USB debugging on phone"
    echo "3. Accept the USB debugging prompt"
    echo ""
    exit 1
fi

echo "✅ Device connected"
echo ""

# Set up reverse port forwarding
echo "Setting up port forwarding..."
adb reverse tcp:8082 tcp:8082

if [ $? -eq 0 ]; then
    echo "✅ Port forwarding configured: tcp:8082 → tcp:8082"
else
    echo "❌ Failed to set up port forwarding"
    exit 1
fi
echo ""

# Verify
echo "Active port forwards:"
adb reverse --list
echo ""

# Check backend
echo "Checking backend status..."
if curl -s http://localhost:8082/health > /dev/null 2>&1; then
    echo "✅ Backend is running on port 8082"
    curl -s http://localhost:8082/health
else
    echo "⚠️  Backend is NOT running"
    echo ""
    echo "Start backend with:"
    echo "  cd backend && ./tos-backend"
fi
echo ""

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Your phone can now access the backend at:"
echo "  http://10.0.2.2:8082"
echo ""
echo "Note: You need to run this script again if you:"
echo "  - Disconnect and reconnect the USB cable"
echo "  - Restart your phone"
echo "  - Restart ADB"
echo ""
