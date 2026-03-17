package models

import "time"

type User struct {
	ID        string    `json:"id"`
	Role      string    `json:"role"`
	TenantID  string    `json:"tenant_id"`
	Phone     string    `json:"phone"`
	Name      string    `json:"name"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type LoginRequest struct {
	Phone string `json:"phone" binding:"required"`
}

type LoginResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}
