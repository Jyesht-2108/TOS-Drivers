# Backend Restart Instructions

## Issue Fixed
Routes were not showing students on the mobile app because the backend API was not including student data in the routes response.

## Changes Made
1. Updated `backend/models/route.go` to include a `Students` field in the Route struct
2. Updated `backend/handlers/routes.go` to fetch and include students for each route in the GetRoutes response

## Backend Status
The backend is currently running on port 8082 with the updated code.

## How to Restart Backend

If you need to restart the backend:

```bash
# Stop any existing backend process
pkill -f "go run main.go"

# Start the backend
cd backend
go run main.go
```

The backend will start on port 8082 and connect to PostgreSQL.

## Testing Routes API

Test the routes endpoint:
```bash
curl -X GET "http://192.168.0.104:8082/api/v1/routes" \
  -H "X-User-ID: 20000000-0000-0000-0000-000000000001" \
  -H "Content-Type: application/json"
```

You should see routes with their students array populated.

## Mobile App
Pull to refresh on the routes screen to fetch the updated data with student counts.
