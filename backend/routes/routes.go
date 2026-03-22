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
		protected.GET("/routes/:id", handlers.GetRouteByID)
		protected.GET("/routes/:id/students", handlers.GetStudentsByRoute)

		// Trips
		protected.POST("/trips/start", handlers.StartTrip)
		protected.POST("/trips/end", handlers.EndTrip)
		protected.GET("/trips/active", handlers.GetActiveTrip)
		protected.GET("/trips/:trip_id/attendance", handlers.GetAttendance)

		// Attendance - support both path param and query param
		protected.GET("/attendance", handlers.GetAttendance) // Query param: ?trip_id=xxx
		protected.POST("/attendance/mark", handlers.MarkAttendance)

		// Location
		protected.POST("/location/update", handlers.UpdateLocation)

		// SSE - Driver notifications stream
		protected.GET("/driver/events", handlers.DriverEvents)

		// Admin - Send notification to driver
		protected.POST("/driver/notify", handlers.SendNotification)
	}

	// Admin routes
	admin := router.Group("/admin")
	// admin.Use(middleware.AuthMiddleware(), middleware.AdminOnly())
	{
		// Route assignments
		admin.GET("/routes/assignments", handlers.GetRouteAssignments)
		admin.POST("/routes/:route_id/assign-driver", handlers.AssignDriverToRoute)
		admin.POST("/routes/:route_id/unassign-driver", handlers.UnassignDriverFromRoute)
	}
}
