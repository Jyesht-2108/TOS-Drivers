# Attendance Flow - Quick Testing Guide

## Prerequisites

1. **Backend Running:**
   ```bash
   cd backend
   go run main.go
   ```
   Should see: `Server starting on port 8080`

2. **Flutter App Running:**
   ```bash
   flutter run
   ```

3. **Network:** Phone and computer on same WiFi

---

## Quick Test (5 Minutes)

### Step 1: Login
- Phone: `+1234567891`
- OTP: `123456` (any 6 digits)

### Step 2: Start Trip
- Tap "My Routes"
- Tap "Start Trip" on Route A
- Select "PICKUP"
- Tap "Start Trip"

### Step 3: Mark Attendance
- Tap "Mark Attendance" from active trip screen
- Wait for student list to load

### Step 4: Test Marking Flow

**For First Student:**
1. Tap "Present" (green button)
   - ✓ Row should highlight green
   - ✓ Should show "Change" and "Confirm & Lock" buttons

2. Tap "Confirm & Lock"
   - ✓ Button shows "Saving..." with spinner
   - ✓ Row locks with green background
   - ✓ Shows "Confirmed Present" with lock icon
   - ✓ Buttons disappear
   - ✓ Progress counter updates (1/X confirmed)

**For Second Student:**
1. Tap "Absent" (red button)
2. Tap "Confirm & Lock"
   - ✓ Row locks with red background
   - ✓ Shows "Confirmed Absent"
   - ✓ Progress counter updates (2/X confirmed)

**For Third Student (Test Change):**
1. Tap "Present"
2. Tap "Change"
   - ✓ Returns to initial state
3. Tap "Absent"
4. Tap "Confirm & Lock"
   - ✓ Locks as absent

### Step 5: Verify Lock Enforcement
- Try to tap buttons on locked rows
  - ✓ Buttons should not exist
  - ✓ Lock icon visible

### Step 6: End Trip
- Go back to active trip screen
- Tap "End Trip"
- Confirm

---

## Expected Behavior

### Visual States

**Unmarked Student:**
```
┌─────────────────────────────────────┐
│ 👤 John Doe                         │
│                                     │
│ [Present]  [Absent]                 │
│  (green)    (red)                   │
└─────────────────────────────────────┘
```

**Selected (Not Confirmed):**
```
┌─────────────────────────────────────┐
│ 👤 John Doe                         │
│ ℹ️ Selected Present - Tap confirm   │
│                                     │
│ [Change]  [Confirm & Lock]          │
│  (gray)      (green)                │
└─────────────────────────────────────┘
```

**Locked (Present):**
```
┌─────────────────────────────────────┐
│ 👤 John Doe                    🔒   │
│ ✓ Confirmed Present                 │
│                                     │
│ (no buttons - permanently locked)   │
└─────────────────────────────────────┘
```

**Locked (Absent):**
```
┌─────────────────────────────────────┐
│ 👤 Jane Smith                  🔒   │
│ ✓ Confirmed Absent                  │
│                                     │
│ (no buttons - permanently locked)   │
└─────────────────────────────────────┘
```

---

## API Testing (Alternative)

If you want to test the API directly without the app:

```bash
./test_attendance_api.sh
```

This will:
1. Login as driver
2. Start a trip
3. Fetch attendance records
4. Mark first student as PRESENT
5. Verify lock enforcement
6. Mark second student as ABSENT
7. Show attendance summary
8. End trip

---

## Troubleshooting

### Students Not Loading

**Symptom:** Attendance screen shows "Initializing attendance..." forever

**Check:**
```bash
# Flutter console
flutter logs | grep "Attendance"

# Should see:
# AttendanceService: Fetching attendance for trip...
# AttendanceService: Loaded X attendance records
```

**Fix:**
- Verify active trip exists
- Check backend is running
- Check network connectivity

### Marking Fails

**Symptom:** Error message appears after tapping "Confirm & Lock"

**Check:**
```bash
# Flutter console
flutter logs | grep "Error"

# Backend logs
# Should see POST /api/v1/attendance/mark
```

**Common Errors:**
- "Attendance record not found or locked" → Already marked
- "Network error" → Backend not reachable
- "Failed to mark attendance: 400" → Invalid request

### Lock Not Working

**Symptom:** Can still tap buttons after marking

**Check:**
- Backend response includes `"locked": true`
- UI shows lock icon
- Database has `locked = true`

**Verify in Database:**
```sql
SELECT id, student_id, status, locked 
FROM attendance 
WHERE trip_id = 'your-trip-id';
```

---

## Success Criteria

✅ Student list loads within 2 seconds  
✅ Buttons are 44px minimum height (easy to tap)  
✅ Two-step confirmation prevents accidents  
✅ Optimistic update shows instant feedback  
✅ Locked rows cannot be changed  
✅ Progress counter updates in real-time  
✅ Error messages are clear and helpful  
✅ Works offline (queues for later - future feature)  

---

## Test Credentials

**Driver 1:**
- Phone: `+1234567891`
- Name: John Anderson
- Route: Route A - Morning

**Driver 2:**
- Phone: `+1234567892`
- Name: Sarah Thompson
- Route: Route B - Evening

**OTP:** `123456` (any 6 digits work in MVP)

---

## Database Queries

### Check Attendance Status
```sql
SELECT 
  s.name as student_name,
  a.status,
  a.locked,
  a.marked_at
FROM attendance a
JOIN students s ON a.student_id = s.id
WHERE a.trip_id = 'your-trip-id'
ORDER BY s.name;
```

### Count by Status
```sql
SELECT 
  COALESCE(status, 'UNMARKED') as status,
  COUNT(*) as count
FROM attendance
WHERE trip_id = 'your-trip-id'
GROUP BY status;
```

### Find Locked Records
```sql
SELECT 
  s.name,
  a.status,
  a.marked_at
FROM attendance a
JOIN students s ON a.student_id = s.id
WHERE a.trip_id = 'your-trip-id' 
  AND a.locked = true;
```

---

## Performance Expectations

- **Load Time:** < 2 seconds for 50 students
- **Mark Time:** < 500ms for single student
- **UI Response:** Instant (optimistic update)
- **Lock Enforcement:** Immediate (UI + Backend)

---

## Next Steps After Testing

1. ✅ Verify all students can be marked
2. ✅ Verify lock enforcement works
3. ✅ Test with multiple drivers simultaneously
4. ✅ Test error scenarios (network loss, etc.)
5. ⏳ Add offline support (queue marks)
6. ⏳ Add parent notifications
7. ⏳ Add attendance reports

---

**Quick Start:** Just run the app, start a trip, and mark attendance. It should "just work"! 🚀
