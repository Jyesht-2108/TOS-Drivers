package models

import "time"

type Trip struct {
	ID        string     `json:"id"`
	TenantID  string     `json:"tenant_id"`
	RouteID   string     `json:"route_id"`
	DriverID  string     `json:"driver_id"`
	TripType  string     `json:"trip_type"`
	Status    string     `json:"status"`
	StartTime time.Time  `json:"start_time"`
	EndTime   *time.Time `json:"end_time,omitempty"`
	CreatedAt time.Time  `json:"created_at"`
}

type StartTripRequest struct {
	RouteID  string `json:"route_id" binding:"required"`
	TripType string `json:"trip_type" binding:"required"`
}

type EndTripRequest struct {
	TripID string `json:"trip_id" binding:"required"`
}
