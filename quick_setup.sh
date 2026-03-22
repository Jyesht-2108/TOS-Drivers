#!/bin/bash

# Quick Setup Script - Only installs what's missing
# For CachyOS (Arch-based)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}TOS Driver App - Quick Setup${NC}\n"

# Check what's missing
MISSING=()

echo "Checking installed components..."

# Check Go
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}✗ Go not found${NC}"
    MISSING+=("go")
else
    echo -e "${GREEN}✓ Go installed: $(go version | awk '{print $3}')${NC}"
fi

# Check PostgreSQL
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}✗ PostgreSQL not found${NC}"
    MISSING+=("postgresql")
else
    echo -e "${GREEN}✓ PostgreSQL installed: $(psql --version | awk '{print $3}')${NC}"
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}✗ Flutter not found${NC}"
    MISSING+=("flutter")
else
    echo -e "${GREEN}✓ Flutter installed${NC}"
fi

# Check Redis
if ! command -v redis-server &> /dev/null; then
    echo -e "${YELLOW}✗ Redis not found${NC}"
    MISSING+=("redis")
else
    echo -e "${GREEN}✓ Redis installed${NC}"
fi

# Check Java
if ! command -v java &> /dev/null; then
    echo -e "${YELLOW}✗ Java not found${NC}"
    MISSING+=("jdk17-openjdk")
else
    echo -e "${GREEN}✓ Java installed${NC}"
fi

# Check Android tools
if ! command -v adb &> /dev/null; then
    echo -e "${YELLOW}✗ Android tools not found${NC}"
    MISSING+=("android-tools")
else
    echo -e "${GREEN}✓ Android tools installed${NC}"
fi

echo ""

if [ ${#MISSING[@]} -eq 0 ]; then
    echo -e "${GREEN}All dependencies are installed!${NC}"
    echo ""
    echo "Run the full setup to configure everything:"
    echo -e "  ${YELLOW}./setup_environment.sh${NC}"
    exit 0
fi

echo -e "${YELLOW}Missing packages: ${MISSING[*]}${NC}"
echo ""
echo "Install missing packages? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Installing missing packages..."
    
    # Install from official repos
    PACMAN_PACKAGES=()
    AUR_PACKAGES=()
    
    for pkg in "${MISSING[@]}"; do
        if [ "$pkg" = "flutter" ]; then
            AUR_PACKAGES+=("$pkg")
        else
            PACMAN_PACKAGES+=("$pkg")
        fi
    done
    
    # Install from pacman
    if [ ${#PACMAN_PACKAGES[@]} -gt 0 ]; then
        sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
    fi
    
    # Install Flutter from AUR
    if [[ " ${AUR_PACKAGES[*]} " =~ " flutter " ]]; then
        # Check if yay is installed
        if ! command -v yay &> /dev/null; then
            echo "Installing yay (AUR helper)..."
            cd /tmp
            git clone https://aur.archlinux.org/yay.git
            cd yay
            makepkg -si --noconfirm
            cd -
        fi
        
        yay -S --needed --noconfirm flutter
    fi
    
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "Now run the full setup:"
    echo -e "  ${YELLOW}./setup_environment.sh${NC}"
else
    echo "Installation cancelled."
fi
