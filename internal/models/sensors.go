/*
 * Project: AirSense Backend (airsense-be)
 * Filename: sensors.go
 * Author: [trung.la]
 * Created: [2025-10-30]
 * Last Updated: [2025-10-30]
 * Description: This file contains the data models for sensor data in the AirSense system.
 *
 * Copyright (c) [2025] [AirSense Organization]. All rights reserved.
 */

package models

import "time"

type SensorData struct {
	ID        string    `bson:"_id" json:"id"`
	DeviceID  string    `bson:"device_id" json:"device_id"`
	Timestamp time.Time `bson:"timestamp" json:"timestamp"`
	Sensors   Sensors   `bson:"sensors" json:"sensors"`
}

type Sensors struct {
	PM25        SensorValue `bson:"pm25" json:"pm25"`
	CO2         SensorValue `bson:"co2" json:"co2"`
	CO          SensorValue `bson:"co" json:"co"`
	Temperature SensorValue `bson:"temperature" json:"temperature"`
	Humidity    SensorValue `bson:"humidity" json:"humidity"`
}

type SensorValue struct {
	Value float64 `bson:"value" json:"value"`
	Unit  string  `bson:"unit" json:"unit"`
}
