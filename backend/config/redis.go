package config

import (
	"context"
	"fmt"
	"log"

	"github.com/redis/go-redis/v9"
)

var RedisClient *redis.Client
var ctx = context.Background()

func InitRedis() {
	host := GetEnv("REDIS_HOST", "localhost")
	port := GetEnv("REDIS_PORT", "6379")

	RedisClient = redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%s", host, port),
		DB:   0,
	})

	if err := RedisClient.Ping(ctx).Err(); err != nil {
		log.Println("Redis connection failed:", err)
		log.Println("Continuing without Redis...")
		RedisClient = nil
		return
	}

	log.Println("Redis connected successfully")
}

func CloseRedis() {
	if RedisClient != nil {
		RedisClient.Close()
	}
}
