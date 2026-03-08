package routes

import (
	"tos-backend/handlers"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(router *gin.RouterGroup) {
	// Auth routes
	auth := router.Group("/auth")
	{
		auth.POST("/login", handlers.Login)
	}

	// Protected routes (require authentication)
	protected := router.Group("/")
	// protected.Use(middleware.AuthMiddleware())
	{
		// Routes
		protected.GET("/routes", handlers.GetRoutes)
		protected.GET("/routes/:route_id/students", handlers.GetStudentsByRoute)
		protected.GET("/routes/:id", handlers.GetRouteByID)

		// Trips
		protected.POST("/trips/start", handlers.StartTrip)
		protected.POST("/trips/end", handlers.EndTrip)
		protected.GET("/trips/active", handlers.GetActiveTrip)
		protected.GET("/trips/:trip_id/attendance", handlers.GetAttendance)

		// Attendance
		protected.POST("/attendance/mark", handlers.MarkAttendance)

		// Location
		protected.POST("/location/update", handlers.UpdateLocation)
	}
}
