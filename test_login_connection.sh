#!/bin/bash

echo "==================================="
echo "Login Connection Diagnostic Test"
echo "==================================="
echo ""

# Check current IP
echo "1. Checking machine IP address..."
CURRENT_IP=$(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -z "$CURRENT_IP" ]; then
    CURRENT_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
fi
echo "   Current IP: $CURRENT_IP"
echo ""

# Check configured IP in app
echo "2. Checking configured IP in app..."
CONFIGURED_IP=$(grep "baseUrl = 'http://" lib/core/constants/app_constants.dart | grep -oP '\d+\.\d+\.\d+\.\d+')
echo "   Configured IP: $CONFIGURED_IP"
echo ""

# Compare IPs
if [ "$CURRENT_IP" != "$CONFIGURED_IP" ]; then
    echo "   ⚠️  WARNING: IP mismatch detected!"
    echo "   Update app_constants.dart with: $CURRENT_IP"
    echo ""
fi

# Check if backend is running
echo "3. Checking if backend is running on port 8082..."
if ss -tuln | grep -q ":8082"; then
    echo "   ✅ Port 8082 is listening"
else
    echo "   ❌ Port 8082 is NOT listening"
    echo "   Start backend with: cd backend && ./tos-backend"
    exit 1
fi
echo ""

# Test backend health endpoint
echo "4. Testing backend health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" http://$CONFIGURED_IP:8082/health 2>&1)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$HEALTH_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Backend is accessible: $RESPONSE_BODY"
else
    echo "   ❌ Backend not accessible (HTTP $HTTP_CODE)"
    echo "   Response: $RESPONSE_BODY"
    exit 1
fi
echo ""

# Test login endpoint
echo "5. Testing login endpoint..."
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"phone":"1234567890"}' \
    http://$CONFIGURED_IP:8082/api/v1/auth/login 2>&1)
LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | head -n-1)

if [ "$LOGIN_CODE" = "200" ]; then
    echo "   ✅ Login endpoint working"
    echo "   Response: $LOGIN_BODY" | head -c 100
    echo "..."
else
    echo "   ⚠️  Login returned HTTP $LOGIN_CODE"
    echo "   Response: $LOGIN_BODY"
fi
echo ""

# Check firewall
echo "6. Checking firewall status..."
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "8082.*ALLOW"; then
        echo "   ✅ Firewall allows port 8082"
    else
        echo "   ⚠️  Port 8082 may be blocked by firewall"
        echo "   Run: sudo ufw allow 8082/tcp"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if sudo firewall-cmd --list-ports | grep -q "8082"; then
        echo "   ✅ Firewall allows port 8082"
    else
        echo "   ⚠️  Port 8082 may be blocked by firewall"
        echo "   Run: sudo firewall-cmd --add-port=8082/tcp --permanent"
    fi
else
    echo "   ℹ️  No firewall detected or unable to check"
fi
echo ""

echo "==================================="
echo "Diagnostic Summary"
echo "==================================="
if [ "$CURRENT_IP" = "$CONFIGURED_IP" ] && [ "$HTTP_CODE" = "200" ] && [ "$LOGIN_CODE" = "200" ]; then
    echo "✅ All checks passed! Backend is ready."
    echo ""
    echo "Next steps:"
    echo "1. Rebuild Flutter app: flutter build apk"
    echo "2. Install on device: flutter install"
    echo "3. Test login with phone: 1234567890"
else
    echo "⚠️  Some issues detected. Review the output above."
fi
echo ""
