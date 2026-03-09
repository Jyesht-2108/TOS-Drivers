# TOS Driver App

Transport Operations System - Driver Mobile Application

## Project Structure

```
TOS-Driver/
├── backend/              # Go backend API
│   ├── handlers/        # API endpoint handlers
│   ├── models/          # Data models
│   ├── routes/          # Route definitions
│   ├── config/          # Database & Redis config
│   └── main.go          # Server entry point
├── lib/                 # Flutter app
│   ├── features/        # Feature modules
│   ├── models/          # Data models
│   ├── services/        # Business logic
│   ├── providers/       # State management
│   └── core/            # Core utilities
├── docs/                # Documentation
├── schema-unified.sql   # Database schema
├── seeds-unified.sql    # Test data
└── reset_db_unified.sh  # Database reset script
```

## Quick Start

### 1. Setup Database

```bash
./reset_db_unified.sh
```

### 2. Start Backend

```bash
cd backend
go run main.go
```

Backend runs on **port 8081**

### 3. Run Flutter App

```bash
flutter run
```

## Configuration

### Backend (.env)
- Port: 8081
- Database: tos_db
- Redis: localhost:6379

### Test Credentials
- Driver 1: +1234567891
- Driver 2: +1234567892

## API Endpoints

Base URL: `http://localhost:8081/api/v1`

- `POST /auth/login` - Login
- `GET /routes` - Get routes
- `GET /routes/:id/students` - Get students
- `POST /trips/start` - Start trip
- `POST /trips/end` - End trip
- `POST /location/update` - Update location
- `GET /trips/:id/attendance` - Get attendance
- `POST /attendance/mark` - Mark attendance

## Documentation

- `FINAL_STATUS.md` - Current system status
- `COORDINATION_AGREEMENT.md` - Database setup guide
- `docs/PRD.pdf` - Product requirements
- `docs/TOS_MVP_Coding_SOP_for_Interns.pdf` - Coding standards

## Tech Stack

- **Mobile:** Flutter + Riverpod
- **Backend:** Go + Gin
- **Database:** PostgreSQL
- **Cache:** Redis

## Notes

This app shares the database with the TOS Web Portal (Spring Boot on port 8080).

