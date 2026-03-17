package handlers

import (
	"log"
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

	log.Printf("Login attempt for phone: %s", req.Phone)

	// Query user by phone
	var user models.User
	query := `SELECT id, role, tenant_id, phone, name, status, created_at, updated_at 
	          FROM users WHERE phone = $1 AND status = 'ACTIVE'`
	
	err := config.DB.QueryRow(query, req.Phone).Scan(
		&user.ID, &user.Role, &user.TenantID, &user.Phone, &user.Name,
		&user.Status, &user.CreatedAt, &user.UpdatedAt,
	)

	if err != nil {
		log.Printf("Login failed for phone %s: %v", req.Phone, err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	log.Printf("Login successful for user: %s (ID: %s)", user.Name, user.ID)

	// For MVP, we'll skip JWT and just return user
	// In production, generate JWT token here
	token := "mock-token-" + user.ID

	c.JSON(http.StatusOK, models.LoginResponse{
		Token: token,
		User:  user,
	})
}
