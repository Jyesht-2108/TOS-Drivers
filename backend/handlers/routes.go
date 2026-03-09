package handlers

import (
	"net/http"
	"tos-backend/config"
	"tos-backend/models"

	"github.com/gin-gonic/gin"
)

func GetRoutes(c *gin.Context) {
	query := `SELECT id, tenant_id, name, status, created_at, updated_at 
	          FROM routes WHERE status = 'ACTIVE' ORDER BY name`

	rows, err := config.DB.Query(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	var routes []models.Route
	for rows.Next() {
		var route models.Route
		if err := rows.Scan(&route.ID, &route.TenantID, &route.Name, 
			&route.Status, &route.CreatedAt, &route.UpdatedAt); err != nil {
			continue
		}
		routes = append(routes, route)
	}

	c.JSON(http.StatusOK, routes)
}

func GetRouteByID(c *gin.Context) {
	routeID := c.Param("id")

	var route models.Route
	query := `SELECT id, tenant_id, name, status, created_at, updated_at 
	          FROM routes WHERE id = $1`

	err := config.DB.QueryRow(query, routeID).Scan(
		&route.ID, &route.TenantID, &route.Name, 
		&route.Status, &route.CreatedAt, &route.UpdatedAt,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Route not found"})
		return
	}

	c.JSON(http.StatusOK, route)
}

func GetStudentsByRoute(c *gin.Context) {
	routeID := c.Param("id")

	query := `SELECT s.id, s.tenant_id, s.name, s.grade, s.section, s.created_at, s.updated_at
	          FROM students s
	          INNER JOIN route_students rs ON s.id = rs.student_id
	          WHERE rs.route_id = $1
	          ORDER BY s.name`

	rows, err := config.DB.Query(query, routeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	var students []models.Student
	for rows.Next() {
		var student models.Student
		if err := rows.Scan(&student.ID, &student.TenantID, &student.Name,
			&student.Grade, &student.Section, &student.CreatedAt, &student.UpdatedAt); err != nil {
			continue
		}
		students = append(students, student)
	}

	c.JSON(http.StatusOK, students)
}
