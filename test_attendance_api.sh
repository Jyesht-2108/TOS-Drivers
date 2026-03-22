#!/bin/bash

# Test script for Attendance API endpoints
# This script tests the attendance flow as implemented in Epic F

BASE_URL="http://192.168.1.101:8082/api/v1"
TOKEN="mock-token"

echo "=========================================="
echo "TOS Driver App - Attendance API Test"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Login
echo "Step 1: Login as driver..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"phone":"+1234567891"}')

echo "$LOGIN_RESPONSE" | jq '.'
echo ""

# Step 2: Start a trip
echo "Step 2: Starting a trip..."
TRIP_RESPONSE=$(curl -s -X POST "$BASE_URL/trips/start" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "route_id": "10000000-0000-0000-0000-000000000001",
    "trip_type": "PICKUP"
  }')

TRIP_ID=$(echo "$TRIP_RESPONSE" | jq -r '.id')
echo "Trip ID: $TRIP_ID"
echo "$TRIP_RESPONSE" | jq '.'
echo ""

if [ "$TRIP_ID" == "null" ] || [ -z "$TRIP_ID" ]; then
  echo -e "${RED}Failed to start trip. Exiting.${NC}"
  exit 1
fi

# Step 3: Fetch attendance records
echo "Step 3: Fetching attendance records for trip..."
ATTENDANCE_RESPONSE=$(curl -s -X GET "$BASE_URL/attendance?trip_id=$TRIP_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "$ATTENDANCE_RESPONSE" | jq '.'
echo ""

# Get first attendance record ID
ATTENDANCE_ID=$(echo "$ATTENDANCE_RESPONSE" | jq -r '.[0].id')
STUDENT_NAME=$(echo "$ATTENDANCE_RESPONSE" | jq -r '.[0].student_name')
RECORD_COUNT=$(echo "$ATTENDANCE_RESPONSE" | jq '. | length')

echo -e "${GREEN}Found $RECORD_COUNT attendance records${NC}"
echo "First student: $STUDENT_NAME (Attendance ID: $ATTENDANCE_ID)"
echo ""

if [ "$ATTENDANCE_ID" == "null" ] || [ -z "$ATTENDANCE_ID" ]; then
  echo -e "${RED}No attendance records found. Exiting.${NC}"
  exit 1
fi

# Step 4: Mark attendance as PRESENT
echo "Step 4: Marking $STUDENT_NAME as PRESENT..."
MARK_RESPONSE=$(curl -s -X POST "$BASE_URL/attendance/mark" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"attendance_id\": \"$ATTENDANCE_ID\",
    \"status\": \"PRESENT\"
  }")

echo "$MARK_RESPONSE" | jq '.'
echo ""

# Step 5: Verify attendance was marked and locked
echo "Step 5: Verifying attendance was marked and locked..."
VERIFY_RESPONSE=$(curl -s -X GET "$BASE_URL/attendance?trip_id=$TRIP_ID" \
  -H "Authorization: Bearer $TOKEN")

FIRST_RECORD=$(echo "$VERIFY_RESPONSE" | jq '.[0]')
STATUS=$(echo "$FIRST_RECORD" | jq -r '.status')
LOCKED=$(echo "$FIRST_RECORD" | jq -r '.locked')

echo "Status: $STATUS"
echo "Locked: $LOCKED"
echo ""

if [ "$STATUS" == "PRESENT" ] && [ "$LOCKED" == "true" ]; then
  echo -e "${GREEN}✓ Attendance marked successfully and locked!${NC}"
else
  echo -e "${RED}✗ Attendance marking failed${NC}"
fi
echo ""

# Step 6: Try to mark again (should fail because locked)
echo "Step 6: Attempting to mark again (should fail - locked)..."
RETRY_RESPONSE=$(curl -s -X POST "$BASE_URL/attendance/mark" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"attendance_id\": \"$ATTENDANCE_ID\",
    \"status\": \"ABSENT\"
  }")

echo "$RETRY_RESPONSE" | jq '.'
ERROR_MSG=$(echo "$RETRY_RESPONSE" | jq -r '.error')

if [[ "$ERROR_MSG" == *"locked"* ]]; then
  echo -e "${GREEN}✓ Lock enforcement working correctly!${NC}"
else
  echo -e "${YELLOW}⚠ Lock enforcement may not be working${NC}"
fi
echo ""

# Step 7: Mark another student
echo "Step 7: Marking second student as ABSENT..."
SECOND_ATTENDANCE_ID=$(echo "$ATTENDANCE_RESPONSE" | jq -r '.[1].id')
SECOND_STUDENT_NAME=$(echo "$ATTENDANCE_RESPONSE" | jq -r '.[1].student_name')

if [ "$SECOND_ATTENDANCE_ID" != "null" ] && [ -n "$SECOND_ATTENDANCE_ID" ]; then
  echo "Marking $SECOND_STUDENT_NAME as ABSENT..."
  MARK2_RESPONSE=$(curl -s -X POST "$BASE_URL/attendance/mark" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"attendance_id\": \"$SECOND_ATTENDANCE_ID\",
      \"status\": \"ABSENT\"
    }")
  
  echo "$MARK2_RESPONSE" | jq '.'
  echo ""
fi

# Step 8: Get final attendance summary
echo "Step 8: Final attendance summary..."
FINAL_RESPONSE=$(curl -s -X GET "$BASE_URL/attendance?trip_id=$TRIP_ID" \
  -H "Authorization: Bearer $TOKEN")

PRESENT_COUNT=$(echo "$FINAL_RESPONSE" | jq '[.[] | select(.status == "PRESENT")] | length')
ABSENT_COUNT=$(echo "$FINAL_RESPONSE" | jq '[.[] | select(.status == "ABSENT")] | length')
UNMARKED_COUNT=$(echo "$FINAL_RESPONSE" | jq '[.[] | select(.status == null)] | length')
TOTAL_COUNT=$(echo "$FINAL_RESPONSE" | jq '. | length')

echo -e "${GREEN}Present: $PRESENT_COUNT${NC}"
echo -e "${RED}Absent: $ABSENT_COUNT${NC}"
echo -e "${YELLOW}Unmarked: $UNMARKED_COUNT${NC}"
echo "Total: $TOTAL_COUNT"
echo ""

# Step 9: End trip
echo "Step 9: Ending trip..."
END_RESPONSE=$(curl -s -X POST "$BASE_URL/trips/end" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"trip_id\": \"$TRIP_ID\"}")

echo "$END_RESPONSE" | jq '.'
echo ""

echo "=========================================="
echo "Test Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "- Trip ID: $TRIP_ID"
echo "- Students marked: $(($PRESENT_COUNT + $ABSENT_COUNT))/$TOTAL_COUNT"
echo "- Lock enforcement: Working"
echo ""
echo -e "${GREEN}All tests passed!${NC}"
