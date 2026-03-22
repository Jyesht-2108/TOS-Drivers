# TOS Driver App - Setup Guide for CachyOS

## Current Status

✅ **Already Installed:**
- Go 1.26.1
- PostgreSQL 18.3 (running)

❌ **Need to Install:**
- Flutter
- Redis (optional, but configured in backend)
- Android development tools
- Java (for Android development)

---

## Quick Setup (Recommended)

Run the automated setup script:

```bash
./setup_environment.sh
```

This will:
1. Install all missing dependencies
2. Configure PostgreSQL database
3. Initialize database schema and seed data
4. Install Flutter dependencies
5. Configure Flutter for development

---

## Manual Setup (Step by Step)

If you prefer to install manually or the script fails:

### 1. Install Flutter

```bash
# Install yay (AUR helper) if not installed
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ~

# Install Flutter from AUR
yay -S flutter

# Configure Flutter
flutter config --no-analytics
flutter config --enable-linux-desktop
yes | flutter doctor --android-licenses
```

### 2. Install Redis (Optional)

```bash
sudo pacman -S redis
sudo systemctl start redis
sudo systemctl enable redis
```

### 3. Install Android Development Tools

```bash
# Install Android tools
sudo pacman -S android-tools android-udev

# Install Java
sudo pacman -S jdk17-openjdk

# Add user to plugdev group
sudo usermod -aG plugdev $USER
```

### 4. Install Flutter Dependencies

```bash
sudo pacman -S gtk3 libglu ninja clang cmake pkg-config
```

### 5. Setup PostgreSQL Database

```bash
# Set password for postgres user
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '123456';"

# Create database
sudo -u postgres createdb tos_db

# Initialize schema
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -f schema-unified.sql

# Load seed data
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -f seeds-unified.sql
```

### 6. Configure Backend

```bash
cd backend

# Create .env file
cat > .env << EOF
PORT=8080
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=123456
DB_NAME=tos_db
REDIS_HOST=localhost
REDIS_PORT=6379
EOF

# Install Go dependencies
go mod download

cd ..
```

### 7. Install Flutter Dependencies

```bash
flutter pub get
```

---

## Verification

### Check Installations

```bash
# Check Go
go version

# Check PostgreSQL
psql --version
systemctl status postgresql

# Check Flutter
flutter --version
flutter doctor

# Check Redis (if installed)
redis-server --version
systemctl status redis

# Check Java
java -version

# Check Android tools
adb version
```

### Test Database Connection

```bash
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT COUNT(*) FROM users WHERE role = 'DRIVER';"
```

Should return: `5` (5 test drivers)

### Test Backend

```bash
cd backend
go run main.go
```

Should see: `Server starting on port 8080`

In another terminal:
```bash
curl http://localhost:8080/health
```

Should return: `{"status":"ok"}`

### Test Flutter

```bash
flutter doctor
```

Should show all checks passing (or at least Flutter and Dart installed)

```bash
flutter run
```

Should compile and run the app

---

## Troubleshooting

### Flutter Not Found After Installation

```bash
# Add Flutter to PATH
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### PostgreSQL Connection Failed

```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Start PostgreSQL
sudo systemctl start postgresql

# Check if database exists
sudo -u postgres psql -l | grep tos_db
```

### Go Dependencies Failed

```bash
cd backend
go mod tidy
go mod download
```

### Flutter Doctor Issues

```bash
# Accept Android licenses
flutter doctor --android-licenses

# Install missing dependencies
sudo pacman -S gtk3 libglu ninja clang cmake pkg-config
```

### Permission Denied for Android Devices

```bash
# Add user to plugdev group
sudo usermod -aG plugdev $USER

# Logout and login again for changes to take effect
```

---

## Quick Start Commands

After setup is complete:

### Start Backend
```bash
cd backend
go run main.go
```

### Run Flutter App
```bash
flutter run
```

### Test Attendance API
```bash
./test_attendance_api.sh
```

### Reset Database
```bash
./reset_db_unified.sh
```

---

## System Requirements

### Minimum
- CachyOS (or any Arch-based distro)
- 8GB RAM
- 10GB free disk space
- Internet connection

### Recommended
- 16GB RAM
- 20GB free disk space
- SSD storage
- Physical Android device or emulator

---

## What Gets Installed

### System Packages (via pacman)
- `base-devel` - Build tools
- `git` - Version control
- `postgresql` - Database
- `redis` - Cache (optional)
- `android-tools` - ADB and fastboot
- `android-udev` - Android device rules
- `jdk17-openjdk` - Java for Android
- `gtk3`, `libglu`, `ninja`, `clang`, `cmake`, `pkg-config` - Flutter dependencies

### AUR Packages (via yay)
- `flutter` - Flutter SDK

### Go Packages (via go mod)
- `gin-gonic/gin` - Web framework
- `lib/pq` - PostgreSQL driver
- `google/uuid` - UUID generation
- `joho/godotenv` - Environment variables

### Flutter Packages (via pub)
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `http` - HTTP client
- `geolocator` - GPS tracking
- `google_maps_flutter` - Maps
- And more (see pubspec.yaml)

---

## Database Schema

The database includes:
- 13 tables
- 5 test drivers
- 46 test students
- 12 test routes
- Multi-tenant architecture

Test credentials:
- Phone: `+1234567891`
- OTP: `123456` (any 6 digits)

---

## Next Steps After Setup

1. **Verify everything works:**
   ```bash
   ./quick_setup.sh  # Check what's installed
   ```

2. **Start backend:**
   ```bash
   cd backend && go run main.go
   ```

3. **Run Flutter app:**
   ```bash
   flutter run
   ```

4. **Test attendance flow:**
   - Login with test credentials
   - Start a trip
   - Mark attendance
   - Verify lock enforcement

5. **Implement form validation:**
   - Add phone number validation (10 digits)
   - Add email validation
   - Add name validation
   - See FORM_VALIDATION_IMPLEMENTATION.md (to be created)

---

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Run `flutter doctor` to diagnose Flutter issues
3. Check backend logs for API errors
4. Verify database connection with test query
5. Check system logs: `journalctl -xe`

---

**Created:** March 21, 2026  
**OS:** CachyOS Linux  
**Status:** Ready for setup
