package config

import "time"

type Config struct {
	Server  ServerConfig
	MongoDB MongoDBConfig
	MQTT    MQTTConfig
	JWT     JWTConfig
}

type ServerConfig struct {
	Port string
}

type MongoDBConfig struct {
	URI      string
	Database string
}

type MQTTConfig struct {
	Broker   string
	Username string
	Password string
	ClientID string
}

type JWTConfig struct {
	Secret string
	Expire time.Duration
}
