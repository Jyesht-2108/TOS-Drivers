package handlers

import (
	"encoding/json"
	"net/http"
	"time"
	"tos-backend/config"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AssignDriverToRoute assigns a driver to a route
// POST /api/v1/admin/routes/:route_id/assign-driver
func AssignDriverToRoute(c *gin.Context) {
	routeID := c.Param("route_id")

	var req struct {
		DriverID string `json:"driver_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Start transaction
	tx, err := config.DB.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}
	defer tx.Rollback()

	// Check if route exists
	var routeName string
	var tenantID string
	err = tx.QueryRow("SELECT name, tenant_id FROM routes WHERE id = $1", routeID).Scan(&routeName, &tenantID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Route not found"})
		return
	}

	// Check if driver exists
	var driverName string
	err = tx.QueryRow("SELECT name FROM users WHERE id = $1 AND role = 'DRIVER'", req.DriverID).Scan(&driverName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Driver not found"})
		return
	}

	// Deactivate any existing active assignment for this route
	_, err = tx.Exec(`
		UPDATE route_driver_assignment 
		SET active_to = NOW() 
		WHERE route_id = $1 AND active_to IS NULL
	`, routeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to deactivate previous assignment"})
		return
	}

	// Create new assignment
	assignmentID := uuid.New().String()
	_, err = tx.Exec(`
		INSERT INTO route_driver_assignment (id, route_id, driver_id, active_from, active_to, created_at)
		VALUES ($1, $2, $3, NOW(), NULL, NOW())
	`, assignmentID, routeID, req.DriverID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create assignment"})
		return
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	// Send SSE notification to driver
	eventData := map[string]interface{}{
		"routeId":     routeID,
		"routeName":   routeName,
		"driverId":    req.DriverID,
		"driverName":  driverName,
		"assignedAt":  time.Now().Format(time.RFC3339),
	}

	jsonData, _ := json.Marshal(eventData)
	sent := Broker.SendEvent(req.DriverID, SSEEvent{
		EventType: "ROUTE_ASSIGNED",
		Data:      string(jsonData),
	})

	c.JSON(http.StatusOK, gin.H{
		"message":         "Driver assigned to route successfully",
		"assignment_id":   assignmentID,
		"route_id":        routeID,
		"route_name":      routeName,
		"driver_id":       req.DriverID,
		"driver_name":     driverName,
		"notification_sent": sent,
	})
}

// UnassignDriverFromRoute removes a driver from a route
// POST /api/v1/admin/routes/:route_id/unassign-driver
func UnassignDriverFromRoute(c *gin.Context) {
	routeID := c.Param("route_id")

	// Start transaction
	tx, err := config.DB.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}
	defer tx.Rollback()

	// Get current assignment
	var driverID string
	var routeName string
	err = tx.QueryRow(`
		SELECT rda.driver_id, r.name
		FROM route_driver_assignment rda
		JOIN routes r ON r.id = rda.route_id
		WHERE rda.route_id = $1 AND rda.active_to IS NULL
	`, routeID).Scan(&driverID, &routeName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active assignment found for this route"})
		return
	}

	// Deactivate assignment
	_, err = tx.Exec(`
		UPDATE route_driver_assignment 
		SET active_to = NOW() 
		WHERE route_id = $1 AND active_to IS NULL
	`, routeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unassign driver"})
		return
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	// Send SSE notification to driver
	eventData := map[string]interface{}{
		"routeId":      routeID,
		"routeName":    routeName,
		"driverId":     driverID,
		"unassignedAt": time.Now().Format(time.RFC3339),
	}

	jsonData, _ := json.Marshal(eventData)
	sent := Broker.SendEvent(driverID, SSEEvent{
		EventType: "ROUTE_UNASSIGNED",
		Data:      string(jsonData),
	})

	c.JSON(http.StatusOK, gin.H{
		"message":           "Driver unassigned from route successfully",
		"route_id":          routeID,
		"route_name":        routeName,
		"driver_id":         driverID,
		"notification_sent": sent,
	})
}

// GetRouteAssignments gets all route assignments (for admin dashboard)
// GET /api/v1/admin/routes/assignments
func GetRouteAssignments(c *gin.Context) {
	query := `
		SELECT 
			r.id as route_id,
			r.name as route_name,
			r.status as route_status,
			u.id as driver_id,
			u.name as driver_name,
			u.phone as driver_phone,
			rda.active_from,
			rda.active_to
		FROM routes r
		LEFT JOIN route_driver_assignment rda ON r.id = rda.route_id AND rda.active_to IS NULL
		LEFT JOIN users u ON rda.driver_id = u.id
		WHERE r.status = 'ACTIVE'
		ORDER BY r.name
	`

	rows, err := config.DB.Query(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	type Assignment struct {
		RouteID      string     `json:"route_id"`
		RouteName    string     `json:"route_name"`
		RouteStatus  string     `json:"route_status"`
		DriverID     *string    `json:"driver_id"`
		DriverName   *string    `json:"driver_name"`
		DriverPhone  *string    `json:"driver_phone"`
		ActiveFrom   *time.Time `json:"active_from"`
		ActiveTo     *time.Time `json:"active_to"`
	}

	var assignments []Assignment
	for rows.Next() {
		var a Assignment
		if err := rows.Scan(
			&a.RouteID,
			&a.RouteName,
			&a.RouteStatus,
			&a.DriverID,
			&a.DriverName,
			&a.DriverPhone,
			&a.ActiveFrom,
			&a.ActiveTo,
		); err != nil {
			continue
		}
		assignments = append(assignments, a)
	}

	c.JSON(http.StatusOK, assignments)
}
