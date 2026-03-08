# TOS Backend API

Go backend for the Transport Operations System (TOS) MVP.

## Setup

1. Install Go 1.21+
2. Copy `.env.example` to `.env` and configure
3. Install dependencies:
```bash
go mod download
```

4. Run the server:
```bash
go run main.go
```

Server will start on `http://localhost:8080`

## API Endpoints

### Auth
- `POST /api/v1/auth/login` - Login with phone number

### Routes
- `GET /api/v1/routes` - Get all active routes
- `GET /api/v1/routes/:id` - Get route by ID
- `GET /api/v1/routes/:route_id/students` - Get students for a route

### Trips
- `POST /api/v1/trips/start` - Start a new trip
- `POST /api/v1/trips/end` - End active trip
- `GET /api/v1/trips/active` - Get active trip

### Attendance
- `GET /api/v1/trips/:trip_id/attendance` - Get attendance for trip
- `POST /api/v1/attendance/mark` - Mark student attendance

### Location
- `POST /api/v1/location/update` - Update bus location

## Database

Connects to PostgreSQL database configured in `.env`

## Development

```bash
# Run with auto-reload (install air first: go install github.com/cosmtrek/air@latest)
air
```
