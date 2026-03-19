# Test Credentials for TOS Driver App

## Backend Status
✅ Backend is running and accessible at: `http://192.168.1.101:8082`
✅ Health check: `http://192.168.1.101:8082/health` returns `{"status":"ok"}`

## Valid Driver Login Credentials

### Driver 1: John Anderson
- **Phone:** `+1234567891` or `1234567891`
- **Name:** John Anderson
- **Vehicle:** BUS-001
- **Assigned Route:** Route A - Morning
- **User ID:** 20000000-0000-0000-0000-000000000001

### Driver 2: Sarah Thompson
- **Phone:** `+1234567892` or `1234567892`
- **Name:** Sarah Thompson
- **Vehicle:** BUS-002
- **Assigned Route:** Route B - Evening
- **User ID:** 20000000-0000-0000-0000-000000000002

## How to Login

1. Open the TOS Driver App
2. Enter phone number: `+1234567891` (or without the +: `1234567891`)
3. The app will authenticate with the backend
4. You should see the route list screen

## Testing GPS Streaming

After logging in:
1. Navigate to "My Routes"
2. You should see your assigned route (Route A for Driver 1, Route B for Driver 2)
3. Click "Start Trip" on your route
4. GPS streaming will begin automatically (every 15 seconds)
5. Check the console logs to see GPS updates being sent
6. Click "End Trip" to stop GPS streaming

## Backend Endpoints

- **Health Check:** `GET /health`
- **Login:** `POST /api/v1/auth/login`
- **Get Routes:** `GET /api/v1/routes/assigned`
- **Start Trip:** `POST /api/v1/trips/start`
- **End Trip:** `POST /api/v1/trips/end`
- **GPS Update:** `POST /api/v1/location/update`
- **SSE Events:** `GET /api/v1/events/stream`

## Troubleshooting

### "Backend not available" Error

If you see this error, check:

1. **Backend is running:**
   ```bash
   curl http://192.168.1.101:8082/health
   ```
   Should return: `{"status":"ok"}`

2. **Phone number format:**
   - Use: `+1234567891` or `1234567891`
   - Don't use: `1234567890` (this user doesn't exist)

3. **Network connectivity:**
   - Make sure your device/emulator can reach `192.168.1.101`
   - For Android Emulator, you may need to use `10.0.2.2` instead
   - For iOS Simulator, you may need to use `localhost`

4. **Update the base URL if needed:**
   Edit `lib/core/constants/app_constants.dart`:
   ```dart
   // For Android Emulator:
   static const String baseUrl = 'http://10.0.2.2:8082';
   
   // For iOS Simulator:
   static const String baseUrl = 'http://localhost:8082';
   
   // For Physical Device:
   static const String baseUrl = 'http://192.168.1.101:8082';
   ```

### GPS Permission Issues

If GPS is not working:
1. Grant location permissions when prompted
2. Check that location services are enabled on your device
3. Look for the orange "GPS Disabled" warning banner
4. Click "Enable" to retry permission request

## Database Access

To check the database directly:
```bash
psql -h localhost -U postgres -d tos_db
```

Useful queries:
```sql
-- Check all users
SELECT id, name, phone, role FROM users WHERE role = 'DRIVER';

-- Check route assignments
SELECT r.name, u.name as driver_name, u.phone 
FROM route_driver_assignment rda
JOIN routes r ON rda.route_id = r.id
JOIN users u ON rda.driver_id = u.id;

-- Check GPS logs
SELECT * FROM gps_logs ORDER BY received_at DESC LIMIT 10;

-- Check latest bus locations
SELECT * FROM latest_bus_location;
```

## Notes

- The backend uses mock authentication (no real password validation)
- JWT tokens are simple mock tokens for testing
- GPS updates are stored in both `gps_logs` (history) and `latest_bus_location` (current)
- SSE events are broadcast for real-time updates
