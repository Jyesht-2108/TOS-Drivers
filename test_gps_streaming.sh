#!/bin/bash

echo "Testing GPS Streaming Implementation"
echo "====================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test data
TRIP_ID="60000000-0000-0000-0000-000000000001"
LAT=37.7749
LNG=-122.4194
ACCURACY=15.5
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "1. Testing GPS Update Endpoint"
echo "------------------------------"
echo "Endpoint: POST /api/v1/location/update"
echo "Trip ID: $TRIP_ID"
echo "Coordinates: $LAT, $LNG"
echo "Accuracy: ${ACCURACY}m"
echo ""

# Test GPS update
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8082/api/v1/location/update \
  -H "Content-Type: application/json" \
  -d "{
    \"trip_id\": \"$TRIP_ID\",
    \"lat\": $LAT,
    \"lng\": $LNG,
    \"accuracy_m\": $ACCURACY,
    \"timestamp\": \"$TIMESTAMP\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ GPS update successful${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}✗ GPS update failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi

echo ""
echo "2. Checking Latest Bus Location"
echo "--------------------------------"

# Query latest location from database
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c \
  "SELECT trip_id, latitude, longitude, accuracy_m, timestamp 
   FROM latest_bus_location 
   WHERE trip_id = '$TRIP_ID';" 2>/dev/null

echo ""
echo "3. Checking GPS Logs"
echo "--------------------"

# Query GPS logs
PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c \
  "SELECT id, trip_id, latitude, longitude, accuracy_m, timestamp 
   FROM gps_logs 
   WHERE trip_id = '$TRIP_ID' 
   ORDER BY timestamp DESC 
   LIMIT 5;" 2>/dev/null

echo ""
echo "4. Testing Error Handling"
echo "-------------------------"

# Test with invalid trip ID
echo "Testing with invalid trip ID..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8082/api/v1/location/update \
  -H "Content-Type: application/json" \
  -d "{
    \"trip_id\": \"00000000-0000-0000-0000-000000000000\",
    \"lat\": $LAT,
    \"lng\": $LNG,
    \"accuracy_m\": $ACCURACY,
    \"timestamp\": \"$TIMESTAMP\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✓ Error handling works correctly (404 for invalid trip)${NC}"
else
    echo -e "${YELLOW}⚠ Expected 404, got HTTP $HTTP_CODE${NC}"
fi

echo ""
echo "5. Testing Missing Fields"
echo "-------------------------"

# Test with missing required fields
echo "Testing with missing lat/lng..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8082/api/v1/location/update \
  -H "Content-Type: application/json" \
  -d "{
    \"trip_id\": \"$TRIP_ID\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "400" ]; then
    echo -e "${GREEN}✓ Validation works correctly (400 for missing fields)${NC}"
else
    echo -e "${YELLOW}⚠ Expected 400, got HTTP $HTTP_CODE${NC}"
fi

echo ""
echo "====================================="
echo "GPS Streaming Test Complete"
echo "====================================="
echo ""
echo "Next Steps:"
echo "1. Start a trip in the Flutter app"
echo "2. Watch the Flutter console for GPS streaming logs"
echo "3. Check database for location updates every 15 seconds"
echo ""
echo "Monitor GPS logs:"
echo "  watch -n 1 'PGPASSWORD=123456 psql -h localhost -U postgres -d tos_db -c \"SELECT trip_id, latitude, longitude, timestamp FROM gps_logs ORDER BY timestamp DESC LIMIT 5;\"'"
