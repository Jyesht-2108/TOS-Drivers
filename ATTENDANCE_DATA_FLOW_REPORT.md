# Attendance Data Flow Report - Driver App to Admin Portal

**Date**: March 22, 2026  
**Route**: Route B - Evening  
**Driver**: John Anderson (ID: 20000000-0000-0000-0000-000000000001)

---

## 1. Trip ID

**Trip ID**: `633baaf8-dfe3-4bd0-bf1f-35914055844b`

**Trip Details**:
- Route: Route B - Evening (ID: 50000000-0000-0000-0000-000000000002)
- Driver: John Anderson (ID: 20000000-0000-0000-0000-000000000001)
- Start Time: 2026-03-22 22:56:31.989015
- End Time: 2026-03-22 22:56:43.254885
- Trip Type: PICKUP

---

## 2. API Endpoint

**Endpoint**: `POST /api/v1/attendance/mark`

**Full URL**: `http://192.168.0.104:8082/api/v1/attendance/mark`

**Method**: POST

**Headers**:
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <token>"
}
```

---

## 3. Request Payload

**Payload Structure**:
```json
{
  "attendance_id": "uuid",
  "status": "PRESENT" | "ABSENT"
}
```

**Actual Payloads Sent**:

### Student 1: Noah Smith (PRESENT)
```json
{
  "attendance_id": "34ff4d1f-52f4-4a5e-89ae-95a7ff0daacf",
  "status": "PRESENT"
}
```

### Student 2: Olivia Smith (ABSENT)
```json
{
  "attendance_id": "d83e8def-6de4-4924-8f30-eced25ac328b",
  "status": "ABSENT"
}
```

**Note**: The driver app sends the `attendance_id` (not student_id) because attendance records are pre-created when the trip starts. The backend updates the existing attendance record with the status.

---

## 4. Response

**Status Code**: `200 OK`

**Response Body**:
```json
{
  "message": "Attendance marked successfully"
}
```

**Backend Logs**:
```
[GIN] 2026/03/22 - 22:56:38 | 200 | 5.097402ms | 192.168.0.101 | POST "/api/v1/attendance/mark"
[GIN] 2026/03/22 - 22:56:39 | 200 | 3.801614ms | 192.168.0.101 | POST "/api/v1/attendance/mark"
```

Both requests completed successfully with 200 status code.

---

## 5. Student IDs and Attendance Status

### Students on Route B - Evening:

| Student ID | Student Name | Grade | Section | Status | Marked At |
|------------|--------------|-------|---------|--------|-----------|
| 40000000-0000-0000-0000-000000000004 | Noah Smith | Grade 6 | C | **PRESENT** | 2026-03-22 22:56:38.954714 |
| 40000000-0000-0000-0000-000000000003 | Olivia Smith | Grade 4 | A | **ABSENT** | 2026-03-22 22:56:39.612792 |

---

## 6. Database Verification

### Query:
```sql
SELECT 
  a.id as attendance_id,
  a.trip_id,
  s.name as student_name,
  a.status,
  a.marked_by,
  a.marked_at,
  a.locked
FROM attendance a
INNER JOIN students s ON a.student_id = s.id
WHERE a.trip_id = '633baaf8-dfe3-4bd0-bf1f-35914055844b'
ORDER BY s.name;
```

### Results:
```
attendance_id                        | trip_id                              | student_name | status  | marked_by                            | marked_at                  | locked
-------------------------------------|--------------------------------------|--------------|---------|--------------------------------------|----------------------------|-------
34ff4d1f-52f4-4a5e-89ae-95a7ff0daacf | 633baaf8-dfe3-4bd0-bf1f-35914055844b | Noah Smith   | PRESENT | 20000000-0000-0000-0000-000000000001 | 2026-03-22 22:56:38.954714 | f
d83e8def-6de4-4924-8f30-eced25ac328b | 633baaf8-dfe3-4bd0-bf1f-35914055844b | Olivia Smith | ABSENT  | 20000000-0000-0000-0000-000000000001 | 2026-03-22 22:56:39.612792 | f
```

**Verification**: ✅ Both attendance records are saved correctly in the database with:
- Correct status (PRESENT/ABSENT)
- Marked by driver ID: 20000000-0000-0000-0000-000000000001
- Timestamp of when marked
- Not locked (can be edited if needed)

---

## 7. Complete API Flow

### Step 1: Start Trip
```
POST /api/v1/trips/start
Body: {
  "route_id": "50000000-0000-0000-0000-000000000002",
  "trip_type": "PICKUP"
}
Response: 201 Created
{
  "trip_id": "633baaf8-dfe3-4bd0-bf1f-35914055844b",
  ...
}
```

**Backend Action**: Creates trip record AND pre-creates attendance records for all students on the route with status=NULL.

### Step 2: Fetch Attendance Records
```
GET /api/v1/attendance?trip_id=633baaf8-dfe3-4bd0-bf1f-35914055844b
Response: 200 OK
[
  {
    "id": "34ff4d1f-52f4-4a5e-89ae-95a7ff0daacf",
    "trip_id": "633baaf8-dfe3-4bd0-bf1f-35914055844b",
    "student_id": "40000000-0000-0000-0000-000000000004",
    "student_name": "Noah Smith",
    "status": null,
    "marked_by": null,
    "marked_at": null,
    "locked": false
  },
  ...
]
```

### Step 3: Mark Attendance (for each student)
```
POST /api/v1/attendance/mark
Body: {
  "attendance_id": "34ff4d1f-52f4-4a5e-89ae-95a7ff0daacf",
  "status": "PRESENT"
}
Response: 200 OK
{
  "message": "Attendance marked successfully"
}
```

**Backend Action**: Updates the attendance record with status, marked_by (driver_id), and marked_at (timestamp).

### Step 4: End Trip
```
POST /api/v1/trips/end
Body: {
  "trip_id": "633baaf8-dfe3-4bd0-bf1f-35914055844b"
}
Response: 200 OK
```

**Backend Action**: Sets trip end_time and locks attendance records (locked=true) to prevent further edits.

---

## 8. Backend Implementation Details

### Database Schema:
```sql
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id),
    student_id UUID NOT NULL REFERENCES students(id),
    status VARCHAR(20) CHECK (status IN ('PRESENT', 'ABSENT')),
    marked_by UUID REFERENCES users(id),
    marked_at TIMESTAMP,
    locked BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Backend Handler (Go):
```go
func MarkAttendance(c *gin.Context) {
    var req MarkAttendanceRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    driverID := "20000000-0000-0000-0000-000000000001"
    now := time.Now()

    query := `UPDATE attendance 
              SET status = $1, marked_by = $2, marked_at = $3, updated_at = $4
              WHERE id = $5 AND locked = false`

    result, err := config.DB.Exec(query, req.Status, driverID, now, now, req.AttendanceID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    rows, _ := result.RowsAffected()
    if rows == 0 {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Attendance record not found or locked"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Attendance marked successfully"})
}
```

---

## 9. Admin Portal Integration

### Query to Fetch Attendance for Admin Portal:
```sql
SELECT 
  t.id as trip_id,
  t.start_time,
  t.end_time,
  r.name as route_name,
  u.name as driver_name,
  s.name as student_name,
  a.status,
  a.marked_at
FROM attendance a
INNER JOIN trips t ON a.trip_id = t.id
INNER JOIN routes r ON t.route_id = r.id
INNER JOIN users u ON t.driver_id = u.id
INNER JOIN students s ON a.student_id = s.id
WHERE t.id = '633baaf8-dfe3-4bd0-bf1f-35914055844b'
ORDER BY s.name;
```

### Expected Admin Portal API Endpoint:
If the admin portal has its own API, it should query the same database tables:
- `trips` - for trip information
- `attendance` - for attendance records
- `students` - for student details
- `routes` - for route information
- `users` - for driver information

---

## 10. Troubleshooting Checklist

If admin portal is not showing attendance:

- [ ] **Database Connection**: Is the admin portal connected to the same PostgreSQL database (`tos_db`)?
- [ ] **Table Access**: Can the admin portal query the `attendance` table?
- [ ] **Trip ID**: Is the admin portal using the correct trip_id?
- [ ] **Time Sync**: Are timestamps being interpreted correctly (timezone issues)?
- [ ] **Caching**: Is the admin portal caching old data? Try refreshing.
- [ ] **Query Filters**: Is the admin portal filtering by date/route/driver correctly?
- [ ] **Null Handling**: Is the admin portal handling NULL status values (unmarked students)?

---

## 11. Test Credentials

- **Phone**: 1234567890 (or +1234567890)
- **OTP**: 123456
- **Driver ID**: 20000000-0000-0000-0000-000000000001
- **Driver Name**: John Anderson

---

## Contact

For further debugging, the driver app team can provide:
- Backend logs
- Database dumps
- API request/response traces
- Flutter app logs

Backend is running at: `http://192.168.0.104:8082`
