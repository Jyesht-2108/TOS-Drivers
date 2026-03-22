package handlers

import (
	"database/sql"
	"net/http"
	"time"
	"tos-backend/config"

	"github.com/gin-gonic/gin"
)

type AttendanceRecord struct {
	ID         string     `json:"id"`
	TripID     string     `json:"trip_id"`
	StudentID  string     `json:"student_id"`
	StudentName string    `json:"student_name"`
	Status     *string    `json:"status"`
	MarkedBy   *string    `json:"marked_by"`
	MarkedAt   *time.Time `json:"marked_at"`
	Locked     bool       `json:"locked"`
}

type MarkAttendanceRequest struct {
	AttendanceID string `json:"attendance_id" binding:"required"`
	Status       string `json:"status" binding:"required"`
}

func GetAttendance(c *gin.Context) {
	// Support both path parameter (/trips/:trip_id/attendance) and query parameter (?trip_id=xxx)
	tripID := c.Param("trip_id")
	if tripID == "" {
		tripID = c.Query("trip_id")
	}

	if tripID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "trip_id is required"})
		return
	}

	query := `SELECT a.id, a.trip_id, a.student_id, s.name, a.status, a.marked_by, a.marked_at, a.locked
	          FROM attendance a
	          INNER JOIN students s ON a.student_id = s.id
	          WHERE a.trip_id = $1
	          ORDER BY s.name`

	rows, err := config.DB.Query(query, tripID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	var records []AttendanceRecord
	for rows.Next() {
		var record AttendanceRecord
		var status, markedBy sql.NullString
		var markedAt sql.NullTime

		if err := rows.Scan(&record.ID, &record.TripID, &record.StudentID, &record.StudentName,
			&status, &markedBy, &markedAt, &record.Locked); err != nil {
			continue
		}

		if status.Valid {
			record.Status = &status.String
		}
		if markedBy.Valid {
			record.MarkedBy = &markedBy.String
		}
		if markedAt.Valid {
			record.MarkedAt = &markedAt.Time
		}

		records = append(records, record)
	}

	c.JSON(http.StatusOK, records)
}

func MarkAttendance(c *gin.Context) {
	var req MarkAttendanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// For MVP, hardcode driver ID
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
