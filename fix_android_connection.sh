#!/bin/bash

# Fix Android Device Connection for CachyOS/Arch
# This script sets up proper permissions for Android USB debugging

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing Android Device Connection...${NC}\n"

# 1. Create udev rules for Android devices
echo "Step 1: Creating udev rules..."
sudo tee /etc/udev/rules.d/51-android.rules > /dev/null <<'EOF'
# Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="adbusers"
# Google
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="adbusers"
# HTC
SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0666", GROUP="adbusers"
# Motorola
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="adbusers"
# LG
SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0666", GROUP="adbusers"
# Huawei
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0666", GROUP="adbusers"
# Xiaomi
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="adbusers"
# OnePlus
SUBSYSTEM=="usb", ATTR{idVendor}=="2a70", MODE="0666", GROUP="adbusers"
EOF

echo -e "${GREEN}✓ udev rules created${NC}"

# 2. Create adbusers group if it doesn't exist
echo -e "\nStep 2: Setting up adbusers group..."
if ! getent group adbusers > /dev/null; then
    sudo groupadd adbusers
    echo -e "${GREEN}✓ adbusers group created${NC}"
else
    echo -e "${GREEN}✓ adbusers group already exists${NC}"
fi

# 3. Add user to adbusers group
echo -e "\nStep 3: Adding user to adbusers group..."
if groups | grep -q adbusers; then
    echo -e "${GREEN}✓ Already in adbusers group${NC}"
else
    sudo usermod -aG adbusers $USER
    echo -e "${GREEN}✓ Added to adbusers group${NC}"
    echo -e "${YELLOW}⚠ You'll need to logout and login for this to take effect${NC}"
fi

# 4. Reload udev rules
echo -e "\nStep 4: Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger
echo -e "${GREEN}✓ udev rules reloaded${NC}"

# 5. Restart adb server
echo -e "\nStep 5: Restarting adb server..."
adb kill-server
sleep 1
adb start-server
echo -e "${GREEN}✓ adb server restarted${NC}"

# 6. Check device status
echo -e "\nStep 6: Checking device status..."
echo ""
adb devices
echo ""

# Check if device is authorized
if adb devices | grep -q "device$"; then
    echo -e "${GREEN}✓ Device is authorized and ready!${NC}"
    echo ""
    echo "You can now run:"
    echo -e "  ${YELLOW}export PATH=\"\$PATH:\$HOME/flutter/bin\"${NC}"
    echo -e "  ${YELLOW}flutter run${NC}"
elif adb devices | grep -q "unauthorized"; then
    echo -e "${RED}✗ Device is still unauthorized${NC}"
    echo ""
    echo -e "${YELLOW}ACTION REQUIRED:${NC}"
    echo "  1. ${YELLOW}Look at your phone screen NOW${NC}"
    echo "  2. You should see a popup asking 'Allow USB debugging?'"
    echo "  3. Check the box 'Always allow from this computer'"
    echo "  4. Tap 'OK'"
    echo ""
    echo "After authorizing, run:"
    echo -e "  ${YELLOW}adb devices${NC}"
    echo ""
    echo "You should then see 'device' instead of 'unauthorized'"
else
    echo -e "${RED}✗ No device detected${NC}"
    echo ""
    echo "Please:"
    echo "  1. Unplug and replug your USB cable"
    echo "  2. Make sure USB debugging is enabled on your phone"
    echo "  3. Try a different USB cable or port"
    echo "  4. Run this script again"
fi

echo ""
echo -e "${YELLOW}Important Notes:${NC}"
if ! groups | grep -q adbusers; then
    echo "  • You were just added to the adbusers group"
    echo "  • You MUST logout and login again for this to take effect"
    echo "  • After logging back in, run this script again"
fi
echo "  • Make sure USB debugging is enabled on your phone"
echo "  • Check your phone screen for the authorization popup"
echo ""
