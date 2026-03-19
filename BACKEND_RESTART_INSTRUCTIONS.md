# Backend Restart Instructions

## Issue Fixed
The `StartTrip` handler had a bug where it was inserting `trip_date` but the parameter count was mismatched. This has been fixed.

## How to Restart the Backend

### Option 1: Stop and Restart (Recommended)

1. **Stop the current backend process:**
   - Go to the terminal where `go run main.go` is running (pts/3)
   - Press `Ctrl+C` to stop it

2. **Start the backend again:**
   ```bash
   cd backend
   go run main.go
   ```

### Option 2: Kill and Restart

If you can't find the terminal:

```bash
# Kill the process
pkill -f "go run main.go"

# Start the backend
cd backend
go run main.go
```

## Verify Backend is Running

After restarting, test the health endpoint:

```bash
curl http://192.168.1.101:8082/health
```

Should return: `{"status":"ok"}`

## Test Trip Start

After the backend restarts, try starting a trip from the app. The 500 error should be resolved.

## What Was Fixed

**Before:**
```go
tripDate := now.Format("2006-01-02")
query := `INSERT INTO trips (...) VALUES ($1, $2, $3, $4, $5, $6, 'ACTIVE', $7, $8) ...`
err := config.DB.QueryRow(query, tripID, tenantID, req.RouteID, driverID, 
    req.TripType, tripDate, now, now).Scan(...)
```
This had 8 parameters but the query expected them in a specific order.

**After:**
```go
query := `INSERT INTO trips (...) VALUES ($1, $2, $3, $4, $5, CURRENT_DATE, 'ACTIVE', $6, $7) ...`
err := config.DB.QueryRow(query, tripID, tenantID, req.RouteID, driverID, 
    req.TripType, now, now).Scan(...)
```
Now using `CURRENT_DATE` directly in SQL, reducing parameter count to 7 and avoiding the mismatch.

## Expected Behavior After Fix

1. Login with phone: `+1234567891`
2. Navigate to "My Routes"
3. Click "Start Trip" on Route A
4. Trip should start successfully
5. GPS streaming should begin automatically (every 15 seconds)
6. Check backend logs - you should see GPS updates coming in

## Monitoring GPS Updates

Watch the backend logs to see GPS updates:
```bash
# In the backend terminal, you'll see logs like:
# GPS streaming update - Trip: <trip-id>, Lat: <lat>, Lng: <lng>, Accuracy: <accuracy>m
```

Check the database:
```bash
psql -h localhost -U postgres -d tos_db -c "SELECT * FROM latest_bus_location;"
psql -h localhost -U postgres -d tos_db -c "SELECT * FROM gps_logs ORDER BY received_at DESC LIMIT 5;"
```
