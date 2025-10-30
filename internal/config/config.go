/*
 * Project: AirSense Backend (airsense-be)
 * Filename: config.go
 * Author: [trung.la]
 * Created: [2025-10-30]
 * Last Updated: [2025-10-30]
 * Description: This file contains the data models for sensor data in the AirSense system.
 *
 * Copyright (c) [2025] [AirSense Organization]. All rights reserved.
 */

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
