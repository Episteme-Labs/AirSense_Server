/*
 * Project: AirSense Backend (airsense-be)
 * Filename: device.go
 * Author: [trung.la]
 * Created: [2025-10-30]
 * Last Updated: [2025-10-30]
 * Description: This file contains the data models for device data in the AirSense system.
 *
 * Copyright (c) [2025] [AirSense Organization]. All rights reserved.
 */

package models

import "time"

type Device struct {
	ID        string    `bson:"_id" json:"id"`
	UserID    string    `bson:"user_id" json:"user_id"`
	Name      string    `bson:"name" json:"name"`
	Location  string    `bson:"location" json:"location"`
	CreatedAt time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt time.Time `bson:"updated_at" json:"updated_at"`
}
