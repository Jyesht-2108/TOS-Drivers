package handlers

import (
	"net/http"
	"time"
	"tos-backend/config"
	"tos-backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func StartTrip(c *gin.Context) {
	var req models.StartTripRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// For MVP, hardcode driver ID (get from auth in production)
	driverID := "20000000-0000-0000-0000-000000000001"
	tenantID := "a0000000-0000-0000-0000-000000000001"

	tripID := uuid.New().String()
	now := time.Now()

	query := `INSERT INTO trips (id, tenant_id, route_id, driver_id, trip_type, status, start_time, created_at)
	          VALUES ($1, $2, $3, $4, $5, 'ACTIVE', $6, $7)
	          RETURNING id, tenant_id, route_id, driver_id, trip_type, status, start_time, created_at`

	var trip models.Trip
	err := config.DB.QueryRow(query, tripID, tenantID, req.RouteID, driverID, 
		req.TripType, now, now).Scan(
		&trip.ID, &trip.TenantID, &trip.RouteID, &trip.DriverID,
		&trip.TripType, &trip.Status, &trip.StartTime, &trip.CreatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Create attendance records for all students on this route
	createAttendanceRecords(trip.ID, req.RouteID)

	c.JSON(http.StatusCreated, trip)
}

func EndTrip(c *gin.Context) {
	var req models.EndTripRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	now := time.Now()
	query := `UPDATE trips SET status = 'ENDED', end_time = $1 WHERE id = $2 AND status = 'ACTIVE'`

	result, err := config.DB.Exec(query, now, req.TripID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Active trip not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Trip ended successfully"})
}

func GetActiveTrip(c *gin.Context) {
	// For MVP, hardcode driver ID
	driverID := "20000000-0000-0000-0000-000000000001"

	query := `SELECT id, tenant_id, route_id, driver_id, trip_type, status, start_time, created_at
	          FROM trips WHERE driver_id = $1 AND status = 'ACTIVE' LIMIT 1`

	var trip models.Trip
	err := config.DB.QueryRow(query, driverID).Scan(
		&trip.ID, &trip.TenantID, &trip.RouteID, &trip.DriverID,
		&trip.TripType, &trip.Status, &trip.StartTime, &trip.CreatedAt,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active trip"})
		return
	}

	c.JSON(http.StatusOK, trip)
}

func createAttendanceRecords(tripID, routeID string) {
	query := `INSERT INTO attendance (id, trip_id, student_id, locked, created_at)
	          SELECT gen_random_uuid(), $1, student_id, false, NOW()
	          FROM route_students WHERE route_id = $2`

	config.DB.Exec(query, tripID, routeID)
}
