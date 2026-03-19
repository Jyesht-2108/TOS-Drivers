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
	Lat       float64 `json:"lat" binding:"required"`
	Lng       float64 `json:"lng" binding:"required"`
	AccuracyM float64 `json:"accuracy_m"`
	Timestamp string  `json:"timestamp"`
	// Legacy fields for backward compatibility
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Speed     float64 `json:"speed"`
	Heading   float64 `json:"heading"`
	Accuracy  float64 `json:"accuracy"`
}

func UpdateLocation(c *gin.Context) {
	var req LocationUpdate
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Support both new (lat/lng) and legacy (latitude/longitude) field names
	lat := req.Lat
	lng := req.Lng
	accuracyM := req.AccuracyM
	
	// Fall back to legacy fields if new fields are not provided
	if lat == 0 && req.Latitude != 0 {
		lat = req.Latitude
	}
	if lng == 0 && req.Longitude != 0 {
		lng = req.Longitude
	}
	if accuracyM == 0 && req.Accuracy != 0 {
		accuracyM = req.Accuracy
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
	upsertQuery := `INSERT INTO latest_bus_location (trip_id, route_id, driver_id, latitude, longitude, speed, heading, accuracy_m, timestamp, updated_at)
	                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	                ON CONFLICT (trip_id) 
	                DO UPDATE SET latitude = $4, longitude = $5, speed = $6, heading = $7, accuracy_m = $8, timestamp = $9, updated_at = $10`

	_, err = config.DB.Exec(upsertQuery, req.TripID, routeID, driverID, 
		lat, lng, req.Speed, req.Heading, accuracyM, now, now)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Log to gps_logs
	logID := uuid.New().String()
	logQuery := `INSERT INTO gps_logs (id, trip_id, latitude, longitude, speed, heading, accuracy_m, timestamp, received_at)
	             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`

	config.DB.Exec(logQuery, logID, req.TripID, lat, lng, req.Speed, req.Heading, accuracyM, now, now)

	c.JSON(http.StatusOK, gin.H{"message": "Location updated successfully"})
}
