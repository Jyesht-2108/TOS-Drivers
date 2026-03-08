package handlers

import (
	"net/http"
	"tos-backend/config"
	"tos-backend/models"

	"github.com/gin-gonic/gin"
)

func Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Query user by phone
	var user models.User
	query := `SELECT id, role, tenant_id, phone, status, created_at, updated_at 
	          FROM users WHERE phone = $1 AND status = 'ACTIVE'`
	
	err := config.DB.QueryRow(query, req.Phone).Scan(
		&user.ID, &user.Role, &user.TenantID, &user.Phone, 
		&user.Status, &user.CreatedAt, &user.UpdatedAt,
	)

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// For MVP, we'll skip JWT and just return user
	// In production, generate JWT token here
	token := "mock-token-" + user.ID

	c.JSON(http.StatusOK, models.LoginResponse{
		Token: token,
		User:  user,
	})
}
