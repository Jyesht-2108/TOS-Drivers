# Manual Flutter Installation for CachyOS

## Issue

The AUR Flutter package has a dependency conflict. We'll install Flutter manually instead.

## Quick Manual Installation

### 1. Download Flutter SDK

```bash
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
```

### 2. Extract Flutter

```bash
tar xf flutter_linux_3.24.5-stable.tar.xz
```

### 3. Add Flutter to PATH

```bash
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### 4. Verify Installation

```bash
flutter --version
```

### 5. Run Flutter Doctor

```bash
flutter doctor
```

### 6. Accept Android Licenses

```bash
yes | flutter doctor --android-licenses
```

### 7. Install Missing Dependencies

```bash
sudo pacman -S --needed android-tools jdk17-openjdk
```

## Alternative: Use Snap (Easier)

If you have snap installed:

```bash
sudo snap install flutter --classic
```

## After Installation

Once Flutter is installed, run:

```bash
cd ~/TOS-Drivers
./setup_environment.sh
```

This will configure everything else (database, backend, etc.)

## Verify Everything Works

```bash
# Check Flutter
flutter doctor

# Check Go
go version

# Check PostgreSQL
psql --version

# Check database
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c "SELECT 1;"
```

## Next Steps

1. Install Flutter using one of the methods above
2. Run `./setup_environment.sh` to configure everything
3. Start backend: `cd backend && go run main.go`
4. Run app: `flutter run`

