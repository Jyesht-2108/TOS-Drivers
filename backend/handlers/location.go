package handlers

import (
	"net/http"
	"time"
	"tos-backend/config"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type LocationUpdate struct {
	TripID    string  `json:"trip_id" binding:"required"`
	Latitude  float64 `json:"latitude" binding:"required"`
	Longitude float64 `json:"longitude" binding:"required"`
	Accuracy  float64 `json:"accuracy"`
}

func UpdateLocation(c *gin.Context) {
	var req LocationUpdate
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get trip details
	var routeID, driverID string
	tripQuery := `SELECT route_id, driver_id FROM trips WHERE id = $1 AND status = 'ACTIVE'`
	err := config.DB.QueryRow(tripQuery, req.TripID).Scan(&routeID, &driverID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Active trip not found"})
		return
	}

	now := time.Now()

	// Update latest_bus_location
	upsertQuery := `INSERT INTO latest_bus_location (trip_id, route_id, driver_id, lat, lng, accuracy_m, updated_at)
	                VALUES ($1, $2, $3, $4, $5, $6, $7)
	                ON CONFLICT (trip_id) 
	                DO UPDATE SET lat = $4, lng = $5, accuracy_m = $6, updated_at = $7`

	_, err = config.DB.Exec(upsertQuery, req.TripID, routeID, driverID, 
		req.Latitude, req.Longitude, req.Accuracy, now)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Log to gps_logs
	logID := uuid.New().String()
	logQuery := `INSERT INTO gps_logs (id, trip_id, timestamp, lat, lng, accuracy_m, received_at)
	             VALUES ($1, $2, $3, $4, $5, $6, $7)`

	config.DB.Exec(logQuery, logID, req.TripID, now, req.Latitude, req.Longitude, req.Accuracy, now)

	c.JSON(http.StatusOK, gin.H{"message": "Location updated successfully"})
}
