# Attendance Flow - Visual Diagram

## Complete System Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DRIVER ATTENDANCE FLOW                          │
│                              (Epic F)                                   │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│ Driver Login │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Start Trip   │ ──────► POST /api/v1/trips/start
└──────┬───────┘         { route_id, trip_type }
       │                 Response: { id, status: "ACTIVE", ... }
       │
       ▼
┌──────────────────────┐
│ Navigate to          │
│ Mark Attendance      │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────────┐
│ FETCH STUDENT LIST                                                   │
│                                                                      │
│ GET /api/v1/attendance?trip_id={trip_id}                           │
│                                                                      │
│ Response: [                                                          │
│   {                                                                  │
│     "id": "attendance-uuid",           ← Attendance Record ID       │
│     "student_id": "student-uuid",                                   │
│     "student_name": "John Doe",                                     │
│     "status": null,                    ← null = unmarked            │
│     "locked": false,                   ← false = can be marked      │
│     "marked_by": null,                                              │
│     "marked_at": null                                               │
│   },                                                                 │
│   { ... more students ... }                                          │
│ ]                                                                    │
└──────┬───────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────────┐
│ DISPLAY STUDENT LIST                                                 │
│                                                                      │
│ ┌────────────────────────────────────────────────────────────┐     │
│ │ 👤 John Doe                                                │     │
│ │                                                            │     │
│ │ ┌──────────────┐  ┌──────────────┐                       │     │
│ │ │   Present    │  │    Absent    │                       │     │
│ │ │   (green)    │  │    (red)     │                       │     │
│ │ └──────────────┘  └──────────────┘                       │     │
│ └────────────────────────────────────────────────────────────┘     │
│                                                                      │
│ ┌────────────────────────────────────────────────────────────┐     │
│ │ 👤 Jane Smith                                              │     │
│ │                                                            │     │
│ │ ┌──────────────┐  ┌──────────────┐                       │     │
│ │ │   Present    │  │    Absent    │                       │     │
│ │ └──────────────┘  └──────────────┘                       │     │
│ └────────────────────────────────────────────────────────────┘     │
└──────┬───────────────────────────────────────────────────────────────┘
       │
       │ Driver taps "Present"
       ▼
┌──────────────────────────────────────────────────────────────────────┐
│ SELECTION STATE (Local State Only)                                  │
│                                                                      │
│ ┌────────────────────────────────────────────────────────────┐     │
│ │ 👤 John Doe                                                │     │
│ │ ℹ️ Selected Present - Tap confirm                          │     │
│ │                                                            │     │
│ │ ┌──────────────┐  ┌────────────────────────────┐         │     │
│ │ │    Change    │  │   Confirm & Lock           │         │     │
│ │ │    (gray)    │  │   (green, bold)            │         │     │
│ │ └──────────────┘  └────────────────────────────┘         │     │
│ └────────────────────────────────────────────────────────────┘     │
│                                                                      │
│ Note: No API call yet - just UI state change                        │
└──────┬───────────────────────────────────────────────────────────────┘
       │
       │ Driver taps "Confirm & Lock"
       ▼
┌──────────────────────────────────────────────────────────────────────┐
│ OPTIMISTIC UPDATE (Immediate UI Update)                             │
│                                                                      │
│ ┌────────────────────────────────────────────────────────────┐     │
│ │ 👤 John Doe                                           🔒   │     │
│ │ ✓ Confirmed Present                                        │     │
│ │                                                            │     │
│ │ ┌────────────────────────────────┐                        │     │
│ │ │         Saving...              │                        │     │
│ │ │         (spinner)              │                        │     │
│ │ └────────────────────────────────┘                        │     │
│ └────────────────────────────────────────────────────────────┘     │
│                                                                      │
│ State updated immediately before API call                           │
└──────┬───────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────────┐
│ API CALL                                                             │
│                                                                      │
│ POST /api/v1/attendance/mark                                        │
│ {                                                                    │
│   "attendance_id": "attendance-uuid",  ← Use attendance ID          │
│   "status": "PRESENT"                  ← PRESENT or ABSENT          │
│ }                                                                    │
│                                                                      │
│ Backend Logic:                                                       │
│ 1. Find attendance record by ID                                     │
│ 2. Check if locked = false                                          │
│ 3. Update: status = PRESENT, locked = true, marked_by = driver_id  │
│ 4. Return success                                                    │
└──────┬───────────────────────────────────────────────────────────────┘
       │
       ├─────────────────┬─────────────────┐
       │                 │                 │
       ▼                 ▼                 ▼
   SUCCESS           ERROR             LOCKED
       │                 │                 │
       ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Keep         │  │ Revert       │  │ Show Error   │
│ Optimistic   │  │ Optimistic   │  │ "Already     │
│ Update       │  │ Update       │  │ Locked"      │
│              │  │              │  │              │
│ Row stays    │  │ Reload from  │  │ Reload from  │
│ locked       │  │ backend      │  │ backend      │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └─────────────────┴─────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│ FINAL STATE (Locked)                                                │
│                                                                      │
│ ┌────────────────────────────────────────────────────────────┐     │
│ │ 👤 John Doe                                           🔒   │     │
│ │ ✓ Confirmed Present                                        │     │
│ │                                                            │     │
│ │ (no buttons - permanently locked)                          │     │
│ └────────────────────────────────────────────────────────────┘     │
│                                                                      │
│ Database State:                                                      │
│ - status = "PRESENT"                                                │
│ - locked = true                                                     │
│ - marked_by = driver_uuid                                           │
│ - marked_at = timestamp                                             │
│                                                                      │
│ UI State:                                                            │
│ - Green background                                                  │
│ - Lock icon visible                                                 │
│ - No buttons                                                        │
│ - Cannot be changed                                                 │
└──────────────────────────────────────────────────────────────────────┘
```

---

## State Transitions

```
┌─────────────┐
│  UNMARKED   │  status = null, locked = false
└──────┬──────┘
       │
       │ Tap "Present" or "Absent"
       ▼
┌─────────────┐
│  SELECTED   │  Local state only (not saved)
└──────┬──────┘
       │
       ├─────────────────┐
       │                 │
       │ Tap "Confirm"   │ Tap "Change"
       ▼                 ▼
┌─────────────┐    ┌─────────────┐
│   SAVING    │    │  UNMARKED   │  (back to start)
└──────┬──────┘    └─────────────┘
       │
       │ API Success
       ▼
┌─────────────┐
│   LOCKED    │  status = PRESENT/ABSENT, locked = true
└─────────────┘  (PERMANENT - cannot change)
```

---

## Lock Enforcement Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                     LOCK ENFORCEMENT                            │
└─────────────────────────────────────────────────────────────────┘

Layer 1: UI (Flutter)
┌─────────────────────────────────────────────────────────────────┐
│ if (record.locked) {                                            │
│   // Don't show buttons                                         │
│   // Show lock icon                                             │
│   // Disable interaction                                        │
│ }                                                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
Layer 2: Backend (Go)
┌─────────────────────────────────────────────────────────────────┐
│ UPDATE attendance                                               │
│ SET status = $1, marked_by = $2, marked_at = $3               │
│ WHERE id = $4 AND locked = false  ← Only update if not locked │
│                                                                 │
│ If rows affected = 0:                                           │
│   Return 400 "Attendance record not found or locked"           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
Layer 3: Database (PostgreSQL)
┌─────────────────────────────────────────────────────────────────┐
│ attendance table:                                               │
│ - locked BOOLEAN NOT NULL DEFAULT FALSE                         │
│                                                                 │
│ Once locked = true, cannot be changed by driver                │
│ (Admin can change via separate endpoint)                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

```
┌──────────────┐
│   Flutter    │
│   Mobile App │
└──────┬───────┘
       │
       │ GET /api/v1/attendance?trip_id=xxx
       ▼
┌──────────────────────────────────────────────────────────────┐
│ Backend (Go)                                                 │
│                                                              │
│ SELECT a.id, a.trip_id, a.student_id, s.name,              │
│        a.status, a.marked_by, a.marked_at, a.locked         │
│ FROM attendance a                                            │
│ INNER JOIN students s ON a.student_id = s.id               │
│ WHERE a.trip_id = $1                                         │
│ ORDER BY s.name                                              │
└──────┬───────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────┐
│ PostgreSQL Database                                          │
│                                                              │
│ attendance table:                                            │
│ ┌────────────┬──────────┬────────────┬────────┬────────┐   │
│ │ id         │ trip_id  │ student_id │ status │ locked │   │
│ ├────────────┼──────────┼────────────┼────────┼────────┤   │
│ │ uuid-1     │ trip-1   │ student-1  │ NULL   │ false  │   │
│ │ uuid-2     │ trip-1   │ student-2  │ NULL   │ false  │   │
│ │ uuid-3     │ trip-1   │ student-3  │ PRESENT│ true   │   │
│ └────────────┴──────────┴────────────┴────────┴────────┘   │
└──────┬───────────────────────────────────────────────────────┘
       │
       │ JSON Response
       ▼
┌──────────────┐
│   Flutter    │
│   Displays   │
│   Student    │
│   List       │
└──────────────┘
```

---

## Touch Target Compliance

```
┌─────────────────────────────────────────────────────────────────┐
│                    TOUCH TARGET SIZES                           │
└─────────────────────────────────────────────────────────────────┘

Minimum: 44px (iOS) / 48px (Android)
Our Implementation: 44px minimum

┌──────────────────────────────────────────────────────────────┐
│ Present Button                                               │
│ ┌──────────────────────────────────────────────────────┐    │
│ │                                                      │    │
│ │              ✓ Present                               │ 44px
│ │                                                      │    │
│ └──────────────────────────────────────────────────────┘    │
│                                                              │
│ minimumSize: Size(0, 44)                                     │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Confirm & Lock Button                                        │
│ ┌──────────────────────────────────────────────────────┐    │
│ │                                                      │    │
│ │         ✓ Confirm & Lock                             │ 44px
│ │                                                      │    │
│ └──────────────────────────────────────────────────────┘    │
│                                                              │
│ minimumSize: Size(0, 44)                                     │
└──────────────────────────────────────────────────────────────┘

All buttons use:
- OutlinedButton.styleFrom(minimumSize: Size(0, 44))
- ElevatedButton.styleFrom(minimumSize: Size(0, 44))
```

---

## Error Handling Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    ERROR SCENARIOS                           │
└──────────────────────────────────────────────────────────────┘

Scenario 1: Network Error
┌─────────────┐
│ API Call    │
│ Fails       │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Revert optimistic update                                 │
│ 2. Show error: "Network error: Unable to mark attendance"   │
│ 3. Reload attendance from backend                           │
│ 4. User can retry                                           │
└─────────────────────────────────────────────────────────────┘

Scenario 2: Already Locked
┌─────────────┐
│ API Returns │
│ 400 Error   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Show error: "Attendance record not found or locked"     │
│ 2. Reload attendance from backend                           │
│ 3. UI shows locked state                                    │
│ 4. Buttons disappear                                        │
└─────────────────────────────────────────────────────────────┘

Scenario 3: No Active Trip
┌─────────────┐
│ Navigate to │
│ Attendance  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Check if activeTrip exists                               │
│ 2. If null: Show "No active trip"                           │
│ 3. Prompt user to start a trip                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Progress Tracking

```
┌──────────────────────────────────────────────────────────────┐
│                    PROGRESS INDICATOR                        │
└──────────────────────────────────────────────────────────────┘

Header shows: "X/Y confirmed"

Example:
┌────────────────────────────────────────────────────────────┐
│ Route A - Morning                                          │
│ PICKUP                                                     │
│ 👥 3/10 confirmed                                          │
└────────────────────────────────────────────────────────────┘

Calculation:
- Total: attendanceState.records.length
- Marked: records.where(status != UNMARKED).length

Updates in real-time as attendance is marked.
```

---

## Summary

This visual diagram shows:

✅ Complete data flow from UI to database  
✅ State transitions for attendance marking  
✅ Three-layer lock enforcement  
✅ Optimistic update pattern  
✅ Error handling scenarios  
✅ Touch target compliance  
✅ Progress tracking  

The implementation follows best practices for mobile app development with proper separation of concerns, error handling, and user feedback.

---

**Created:** March 20, 2026  
**Status:** ✅ Complete Implementation
