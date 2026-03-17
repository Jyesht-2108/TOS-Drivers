package handlers

import (
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// SSEClient represents a connected SSE client
type SSEClient struct {
	DriverID string
	Channel  chan SSEEvent
}

// SSEEvent represents an event to be sent via SSE
type SSEEvent struct {
	EventType string
	Data      string
}

// SSEBroker manages SSE client connections and event broadcasting
type SSEBroker struct {
	mu      sync.RWMutex
	clients map[string]*SSEClient // driverID -> client
}

// Global broker instance
var Broker = &SSEBroker{
	clients: make(map[string]*SSEClient),
}

// AddClient registers a new SSE client
func (b *SSEBroker) AddClient(driverID string) *SSEClient {
	b.mu.Lock()
	defer b.mu.Unlock()

	// Close existing connection for this driver if any
	if existing, ok := b.clients[driverID]; ok {
		close(existing.Channel)
		delete(b.clients, driverID)
	}

	client := &SSEClient{
		DriverID: driverID,
		Channel:  make(chan SSEEvent, 10), // buffered channel
	}
	b.clients[driverID] = client
	log.Printf("SSE: Client connected for driver: %s (total: %d)", driverID, len(b.clients))
	return client
}

// RemoveClient unregisters an SSE client
func (b *SSEBroker) RemoveClient(driverID string) {
	b.mu.Lock()
	defer b.mu.Unlock()

	if client, ok := b.clients[driverID]; ok {
		close(client.Channel)
		delete(b.clients, driverID)
		log.Printf("SSE: Client disconnected for driver: %s (total: %d)", driverID, len(b.clients))
	}
}

// SendEvent sends an event to a specific driver
func (b *SSEBroker) SendEvent(driverID string, event SSEEvent) bool {
	b.mu.RLock()
	defer b.mu.RUnlock()

	if client, ok := b.clients[driverID]; ok {
		select {
		case client.Channel <- event:
			log.Printf("SSE: Event sent to driver %s: %s", driverID, event.EventType)
			return true
		default:
			log.Printf("SSE: Channel full for driver %s, dropping event", driverID)
			return false
		}
	}
	return false
}

// BroadcastEvent sends an event to all connected drivers
func (b *SSEBroker) BroadcastEvent(event SSEEvent) {
	b.mu.RLock()
	defer b.mu.RUnlock()

	for driverID, client := range b.clients {
		select {
		case client.Channel <- event:
			log.Printf("SSE: Broadcast event to driver %s: %s", driverID, event.EventType)
		default:
			log.Printf("SSE: Channel full for driver %s, skipping broadcast", driverID)
		}
	}
}

// DriverEvents handles the SSE endpoint: GET /api/v1/driver/events?driverId={id}
func DriverEvents(c *gin.Context) {
	driverID := c.Query("driverId")
	if driverID == "" {
		c.JSON(400, gin.H{"error": "driverId query parameter is required"})
		return
	}

	// Set SSE headers
	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("Access-Control-Allow-Origin", "*")

	// Register client
	client := Broker.AddClient(driverID)

	// Send initial CONNECTED event
	fmt.Fprintf(c.Writer, "event: CONNECTED\n")
	fmt.Fprintf(c.Writer, "data: Connection established for driver %s\n\n", driverID)
	c.Writer.Flush()

	// Clean up on disconnect
	notify := c.Request.Context().Done()

	// Keep-alive ticker (every 30 seconds)
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-notify:
			// Client disconnected
			Broker.RemoveClient(driverID)
			return

		case event, ok := <-client.Channel:
			if !ok {
				// Channel closed (replaced by new connection)
				return
			}
			fmt.Fprintf(c.Writer, "event: %s\n", event.EventType)
			fmt.Fprintf(c.Writer, "data: %s\n\n", event.Data)
			c.Writer.Flush()

		case <-ticker.C:
			// Send keep-alive comment to prevent connection timeout
			fmt.Fprintf(c.Writer, ": keepalive\n\n")
			c.Writer.Flush()
		}
	}
}

// SendNotification is an admin endpoint to push a notification to a driver
// POST /api/v1/driver/notify
func SendNotification(c *gin.Context) {
	var req struct {
		DriverID  string `json:"driver_id" binding:"required"`
		EventType string `json:"event_type" binding:"required"`
		Data      string `json:"data" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	sent := Broker.SendEvent(req.DriverID, SSEEvent{
		EventType: req.EventType,
		Data:      req.Data,
	})

	if sent {
		c.JSON(200, gin.H{"message": "Notification sent", "driver_id": req.DriverID})
	} else {
		c.JSON(404, gin.H{"error": "Driver not connected", "driver_id": req.DriverID})
	}
}
