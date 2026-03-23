#!/bin/bash

echo "=========================================="
echo "Network Connection Fix"
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
    echo "❌ PROBLEM: Phone and computer are on DIFFERENT networks!"
    echo ""
    echo "Computer network: $COMPUTER_SUBNET.x"
    echo "Phone network:    $PHONE_SUBNET.x"
    echo ""
    echo "SOLUTIONS:"
    echo ""
    echo "Option 1: Connect phone to same WiFi as computer"
    echo "  1. On your phone, go to Settings → WiFi"
    echo "  2. Disconnect from current network"
    echo "  3. Connect to the same WiFi network as your computer"
    echo "  4. Run this script again to verify"
    echo ""
    echo "Option 2: Use USB tethering (Recommended for development)"
    echo "  1. On your phone: Settings → Connections → Mobile Hotspot and Tethering"
    echo "  2. Enable 'USB tethering'"
    echo "  3. Wait 10 seconds for network to initialize"
    echo "  4. Run: ./setup_usb_tethering.sh"
    echo ""
    echo "Option 3: Use ADB reverse port forwarding"
    echo "  Run: adb reverse tcp:8082 tcp:8082"
    echo "  Then update app to use: http://localhost:8082"
    echo ""
    exit 1
else
    echo "✅ Phone and computer are on the same network!"
    echo ""
    
    # Test connectivity
    echo "Testing connectivity..."
    if adb shell "ping -c 2 $COMPUTER_IP" 2>&1 | grep -q "2 received"; then
        echo "✅ Phone can reach computer!"
        echo ""
        echo "Backend should be accessible. Try logging in again."
    else
        echo "❌ Phone CANNOT reach computer (firewall issue?)"
        echo ""
        echo "Checking firewall..."
        if command -v ufw &> /dev/null; then
            echo "UFW firewall detected. Allowing port 8082..."
            sudo ufw allow 8082/tcp
            sudo ufw reload
        elif command -v firewall-cmd &> /dev/null; then
            echo "Firewalld detected. Allowing port 8082..."
            sudo firewall-cmd --add-port=8082/tcp --permanent
            sudo firewall-cmd --reload
        fi
    fi
fi
