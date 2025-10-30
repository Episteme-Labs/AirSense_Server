/*
 * Project: AirSense Backend (airsense-be)
 * Filename: command.go
 * Author: [trung.la]
 * Created: [2025-10-30]
 * Last Updated: [2025-10-30]
 * Description: This file contains the data models for command data in the AirSense system.
 *
 * Copyright (c) [2025] [AirSense Organization]. All rights reserved.
 */

package models

import "time"

type Command struct {
	CommandID string         `bson:"command_id" json:"commandID"`
	DeviceID  string         `bson:"device_id" json:"deviceID"`
	Action    string         `bson:"action" json:"action"`
	Params    map[string]any `bson:"params" json:"params"`
	Status    CommandStatus  `bson:"status" json:"status"`
	CreatedAt time.Time      `bson:"created_at" json:"createdAt"`
	UpdatedAt time.Time      `bson:"updated_at" json:"updatedAt"`
}

type CommandStatus string

const (
	CommandPending CommandStatus = "pending"
	CommandSuccess CommandStatus = "success"
	CommandError   CommandStatus = "error"
)
