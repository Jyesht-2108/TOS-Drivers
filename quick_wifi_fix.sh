#!/bin/bash

echo "=========================================="
echo "Quick WiFi Network Fix"
echo "=========================================="
echo ""

# Get computer IP
COMPUTER_IP=$(ip addr show wlan0 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1)
if [ -z "$COMPUTER_IP" ]; then
    COMPUTER_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1)
fi

# Get phone IP
PHONE_IP=$(adb shell "ip addr show wlan0 | grep 'inet '" 2>/dev/null | awk '{print $2}' | cut -d/ -f1 | tr -d '\r')

echo "Computer IP: $COMPUTER_IP"
echo "Phone IP:    $PHONE_IP"
echo ""

# Check if on same network
COMPUTER_SUBNET=$(echo $COMPUTER_IP | cut -d. -f1-3)
PHONE_SUBNET=$(echo $PHONE_IP | cut -d. -f1-3)

if [ "$COMPUTER_SUBNET" != "$PHONE_SUBNET" ]; then
    echo "❌ Phone and computer are still on DIFFERENT networks!"
    echo ""
    echo "Computer: $COMPUTER_SUBNET.x"
    echo "Phone:    $PHONE_SUBNET.x"
    echo ""
    echo "Please connect your phone to the same WiFi as your computer."
    echo "Then run this script again."
    exit 1
fi

echo "✅ Both devices on same network ($COMPUTER_SUBNET.x)"
echo ""

# Test connectivity
echo "Testing connectivity..."
if adb shell "ping -c 2 $COMPUTER_IP" 2>&1 | grep -q "2 received\|2 packets received"; then
    echo "✅ Phone can reach computer!"
else
    echo "⚠️  Phone cannot reach computer. Checking firewall..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow 8082/tcp
        sudo ufw reload
        echo "✅ Firewall updated"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --add-port=8082/tcp --permanent
        sudo firewall-cmd --reload
        echo "✅ Firewall updated"
    fi
fi
echo ""

# Update app configuration
echo "Updating app configuration to use $COMPUTER_IP..."

# Update app_constants.dart
sed -i "s|static const String baseUrl = 'http://[^']*';|static const String baseUrl = 'http://$COMPUTER_IP:8082';|" lib/core/constants/app_constants.dart

# Update sse_provider.dart
sed -i "s|return 'http://[^']*';|return 'http://$COMPUTER_IP:8082';|" lib/providers/sse_provider.dart

# Update trip_service.dart
sed -i "s|TripService({this.baseUrl = 'http://[^']*'});|TripService({this.baseUrl = 'http://$COMPUTER_IP:8082'});|" lib/services/trip_service.dart

echo "✅ Configuration updated"
echo ""

# Remove ADB reverse (not needed for WiFi)
adb reverse --remove-all 2>/dev/null

# Rebuild and install
echo "Rebuilding app..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
    echo ""
    echo "Installing on device..."
    flutter install -d RZ8NA142WTL
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "✅ Setup Complete!"
        echo "=========================================="
        echo ""
        echo "App is now configured to use: http://$COMPUTER_IP:8082"
        echo ""
        echo "Try logging in now!"
    else
        echo "❌ Installation failed"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi
