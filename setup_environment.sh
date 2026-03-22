#!/bin/bash

# TOS Driver App - Environment Setup Script for CachyOS
# This script installs all dependencies needed for backend and Flutter development

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TOS Driver App - Environment Setup${NC}"
echo -e "${BLUE}CachyOS Linux${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root"
    exit 1
fi

# Update system
echo -e "\n${BLUE}Step 1: Updating system...${NC}"
sudo pacman -Syu --noconfirm
print_status "System updated"

# Install base development tools
echo -e "\n${BLUE}Step 2: Installing base development tools...${NC}"
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    curl \
    wget \
    unzip \
    xz \
    clang \
    cmake \
    ninja \
    pkgconf
print_status "Base development tools installed"

# Check Go installation
echo -e "\n${BLUE}Step 3: Checking Go installation...${NC}"
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}')
    print_status "Go is already installed: $GO_VERSION"
else
    print_info "Installing Go..."
    sudo pacman -S --needed --noconfirm go
    print_status "Go installed"
fi

# Check PostgreSQL installation
echo -e "\n${BLUE}Step 4: Checking PostgreSQL installation...${NC}"
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version | awk '{print $3}')
    print_status "PostgreSQL is already installed: $PG_VERSION"
    
    # Check if PostgreSQL is running
    if systemctl is-active --quiet postgresql; then
        print_status "PostgreSQL service is running"
    else
        print_info "Starting PostgreSQL service..."
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        print_status "PostgreSQL service started and enabled"
    fi
else
    print_info "Installing PostgreSQL..."
    sudo pacman -S --needed --noconfirm postgresql
    
    # Initialize PostgreSQL
    sudo -u postgres initdb -D /var/lib/postgres/data
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    print_status "PostgreSQL installed and configured"
fi

# Install Redis (optional but configured in backend)
echo -e "\n${BLUE}Step 5: Installing Redis...${NC}"
if command -v redis-server &> /dev/null; then
    print_status "Redis is already installed"
else
    sudo pacman -S --needed --noconfirm redis
    print_status "Redis installed"
fi

# Start Redis service
if systemctl is-active --quiet redis; then
    print_status "Redis service is running"
else
    sudo systemctl start redis
    sudo systemctl enable redis
    print_status "Redis service started and enabled"
fi

# Install Flutter
echo -e "\n${BLUE}Step 6: Installing Flutter...${NC}"
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_status "Flutter is already installed: $FLUTTER_VERSION"
else
    print_info "Installing Flutter from AUR..."
    
    # Install yay if not present (AUR helper)
    if ! command -v yay &> /dev/null; then
        print_info "Installing yay (AUR helper)..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ~
        print_status "yay installed"
    fi
    
    # Install Flutter from AUR
    yay -S --needed --noconfirm flutter
    print_status "Flutter installed"
fi

# Install Android development tools
echo -e "\n${BLUE}Step 7: Installing Android development tools...${NC}"
sudo pacman -S --needed --noconfirm \
    android-tools \
    android-udev
print_status "Android tools installed"

# Add user to plugdev group for Android devices
if ! groups | grep -q plugdev; then
    sudo usermod -aG plugdev $USER
    print_info "Added user to plugdev group (logout/login required)"
fi

# Install Java (required for Android development)
echo -e "\n${BLUE}Step 8: Installing Java...${NC}"
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    print_status "Java is already installed: $JAVA_VERSION"
else
    sudo pacman -S --needed --noconfirm jdk17-openjdk
    print_status "Java 17 installed"
fi

# Install additional Flutter dependencies
echo -e "\n${BLUE}Step 9: Installing Flutter dependencies...${NC}"
sudo pacman -S --needed --noconfirm \
    gtk3 \
    libglu \
    ninja \
    clang \
    cmake \
    pkg-config
print_status "Flutter dependencies installed"

# Configure Flutter
echo -e "\n${BLUE}Step 10: Configuring Flutter...${NC}"
if command -v flutter &> /dev/null; then
    # Accept licenses
    yes | flutter doctor --android-licenses 2>/dev/null || true
    
    # Run flutter doctor
    flutter config --no-analytics
    flutter config --enable-linux-desktop
    print_status "Flutter configured"
fi

# Setup PostgreSQL user and database
echo -e "\n${BLUE}Step 11: Setting up PostgreSQL database...${NC}"
print_info "Creating PostgreSQL user and database..."

# Check if user exists
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='postgres'" | grep -q 1; then
    print_status "PostgreSQL user 'postgres' exists"
else
    sudo -u postgres createuser -s postgres
    print_status "PostgreSQL user 'postgres' created"
fi

# Set password for postgres user
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '123456';" 2>/dev/null || true
print_status "PostgreSQL password set"

# Check if database exists
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw tos_db; then
    print_info "Database 'tos_db' already exists"
else
    sudo -u postgres createdb tos_db
    print_status "Database 'tos_db' created"
fi

# Install Go dependencies for backend
echo -e "\n${BLUE}Step 12: Installing Go dependencies...${NC}"
cd backend
if [ -f "go.mod" ]; then
    go mod download
    print_status "Go dependencies downloaded"
else
    print_error "go.mod not found in backend directory"
fi
cd ..

# Create backend .env file if it doesn't exist
echo -e "\n${BLUE}Step 13: Configuring backend environment...${NC}"
if [ ! -f "backend/.env" ]; then
    if [ -f "backend/.env.example" ]; then
        cp backend/.env.example backend/.env
        print_status "Created backend/.env from .env.example"
    else
        cat > backend/.env << EOF
PORT=8080
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=123456
DB_NAME=tos_db
REDIS_HOST=localhost
REDIS_PORT=6379
EOF
        print_status "Created backend/.env with default values"
    fi
else
    print_status "backend/.env already exists"
fi

# Initialize database schema
echo -e "\n${BLUE}Step 14: Initializing database schema...${NC}"
if [ -f "schema-unified.sql" ]; then
    PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -f schema-unified.sql 2>/dev/null || print_info "Schema may already exist"
    print_status "Database schema initialized"
fi

if [ -f "seeds-unified.sql" ]; then
    PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -f seeds-unified.sql 2>/dev/null || print_info "Seed data may already exist"
    print_status "Seed data loaded"
fi

# Install Flutter dependencies
echo -e "\n${BLUE}Step 15: Installing Flutter dependencies...${NC}"
flutter pub get
print_status "Flutter dependencies installed"

# Run Flutter doctor
echo -e "\n${BLUE}Step 16: Running Flutter doctor...${NC}"
flutter doctor

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo -e "  ✓ Go: $(go version | awk '{print $3}')"
echo -e "  ✓ PostgreSQL: $(psql --version | awk '{print $3}')"
echo -e "  ✓ Redis: $(redis-server --version | awk '{print $3}')"
if command -v flutter &> /dev/null; then
    echo -e "  ✓ Flutter: $(flutter --version | head -n 1 | awk '{print $2}')"
fi
echo -e "  ✓ Database: tos_db (ready)"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Start backend: ${YELLOW}cd backend && go run main.go${NC}"
echo -e "  2. Run Flutter app: ${YELLOW}flutter run${NC}"
echo -e "  3. Test attendance API: ${YELLOW}./test_attendance_api.sh${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} If you were added to the plugdev group, you may need to logout/login"
echo -e "      for Android device permissions to take effect."
echo ""
