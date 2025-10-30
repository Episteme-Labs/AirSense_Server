# AirSense Backend

A Golang backend service for IoT air quality monitoring system that handles communication between mobile apps and IoT devices using MQTT and REST APIs.

## Architecture Overview

```
Mobile Apps (REST API) ←→ Golang Backend ←→ IoT Devices (MQTT)
                              ↓
                          MongoDB (Data Storage)
```

## Features

- **REST API** for mobile app communication with JWT authentication
- **MQTT Integration** for real-time device communication
- **Sensor Data Processing** with validation and storage
- **Device Management** for user device registration and control
- **Command System** for remote device control
- **Time-series Data Storage** in MongoDB

## Prerequisites

- Go 1.19+
- MongoDB 5.0+
- MQTT Broker (EMQX, Mosquitto, or AWS IoT Core)
- Make (optional)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/airsense-be.git
cd airsense-be
```

### 2. Configuration

Create configuration file `.env`:

```env
# Server Configuration
SERVER_PORT=8080
SERVER_ENV=development

# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017
MONGODB_DATABASE=airsense

# MQTT Configuration
MQTT_BROKER=tcp://localhost:1883
MQTT_USERNAME=admin
MQTT_PASSWORD=password
MQTT_CLIENT_ID=airsense-backend

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRY=24h

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081
```

### 3. Using Docker (Recommended)

```bash
# Start all dependencies
docker-compose up -d

# Build and run the application
docker build -t airsense-be .
docker run -p 8080:8080 --env-file .env airsense-be
```

### 4. Manual Setup

#### Install Dependencies

```bash
go mod download
go mod verify
```

#### Setup MongoDB

```bash
# Start MongoDB (if using local instance)
mongod --dbpath ./data/db

# Or use Docker
docker run -d -p 27017:27017 --name mongodb mongo:5.0
```

#### Setup MQTT Broker

```bash
# Using EMQX (recommended)
docker run -d --name emqx -p 1883:1883 -p 8083:8083 -p 8084:8084 -p 8883:8883 -p 18083:18083 emqx/emqx:5.0

# Or using Mosquitto
docker run -d --name mosquitto -p 1883:1883 -p 9001:9001 eclipse-mosquitto
```

## Building the Project

### Build for Development

```bash
make build
# or
go build -o bin/airsense-be cmd/server/main.go
```

### Build for Production

```bash
make build-prod
# or
GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o bin/airsense-be cmd/server/main.go
```

### Build with Docker

```bash
docker build -t airsense-be:latest .
```

## Running the Application

### Development Mode

```bash
make dev
# or
go run cmd/server/main.go
```

### Production Mode

```bash
make run
# or
./bin/airsense-be
```

### Using Docker Compose

```bash
docker-compose up -d
```

The application will be available at `http://localhost:8080`

## Testing

### Run Unit Tests

```bash
make test
# or
go test ./internal/...
```

### Run Integration Tests

```bash
make test-integration
# or
go test -tags=integration ./internal/...
```

### Run Tests with Coverage

```bash
make test-coverage
# or
go test -coverprofile=coverage.out ./internal/...
go tool cover -html=coverage.out
```

### Test API Endpoints

```bash
# Get all devices (requires authentication)
curl -H "Authorization: Bearer <jwt-token>" http://localhost:8080/api/v1/devices

# Send command to device
curl -X POST -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{"action": "calibrate", "params": {"targetSensor": "co2"}}' \
  http://localhost:8080/api/v1/devices/device-123/commands
```

### Test MQTT Communication

```bash
# Subscribe to device data (in separate terminal)
mosquitto_sub -h localhost -t "devices/+/data" -v

# Publish test sensor data
mosquitto_pub -h localhost -t "devices/test-device/data" -m '{
  "timestamp": "2024-01-15T10:30:00Z",
  "deviceID": "test-device",
  "sensors": {
    "pm25": {"value": 25.5, "unit": "μg/m³"},
    "co2": {"value": 450, "unit": "ppm"},
    "co": {"value": 0.5, "unit": "ppm"},
    "temperature": {"value": 22.5, "unit": "°C"},
    "humidity": {"value": 55.0, "unit": "%"}
  }
}'
```

## API Documentation

### Swagger/OpenAPI

After starting the server, access the API documentation at:
```
http://localhost:8080/swagger/index.html
```

### Import Swagger Definition

```bash
# Import into Swagger Editor
npx @apidevtools/swagger-cli validate api/swagger/airsense.swagger.json
```

### Main Endpoints

| Method | Endpoint | Description | Authentication |
|--------|----------|-------------|----------------|
| GET | `/api/v1/devices` | Get user's devices | JWT Required |
| POST | `/api/v1/devices` | Register new device | JWT Required |
| GET | `/api/v1/devices/{id}` | Get device details | JWT Required |
| PUT | `/api/v1/devices/{id}` | Update device metadata | JWT Required |
| GET | `/api/v1/devices/{id}/history` | Get sensor history | JWT Required |
| POST | `/api/v1/devices/{id}/commands` | Send command to device | JWT Required |
| GET | `/api/v1/devices/{id}/commands/{cmdId}` | Get command status | JWT Required |

## MQTT Topics

### Publishing (Device → Backend)

| Topic | QoS | Description | Payload |
|-------|-----|-------------|---------|
| `devices/{deviceID}/data` | 0 | Sensor readings | SensorData JSON |
| `devices/{deviceID}/status` | 1 | Device status | Status JSON |
| `devices/{deviceID}/response/{commandID}` | 1 | Command response | Response JSON |

### Subscribing (Backend → Device)

| Topic | QoS | Description | Payload |
|-------|-----|-------------|---------|
| `devices/{deviceID}/commands` | 0 | Device commands | Command JSON |

## Project Structure

```
airsense-be/
├── cmd/server/          # Application entry point
├── internal/
│   ├── api/            # REST API handlers and routes
│   ├── mqtt/           # MQTT client and message handlers
│   ├── models/         # Data structures
│   ├── repository/     # Database abstraction layer
│   ├── service/        # Business logic
│   └── config/         # Configuration management
├── api/swagger/        # OpenAPI specifications
└── pkg/                # Reusable packages
```

## Environment Variables

See [Configuration](#configuration) section for all available environment variables.

## Make Commands

```bash
make help              # Show all available commands
make build            # Build the application
make run              # Run the application
make dev              # Run in development mode with hot reload
make test             # Run unit tests
make test-coverage    # Run tests with coverage report
make lint             # Run linter
make clean            # Clean build artifacts
make docker-build     # Build Docker image
make docker-run       # Run Docker container
```

### Debug Mode

Enable debug logging:

```bash
export LOG_LEVEL=debug
./bin/airsense-be
```

### Script Build
```bash
chmod +x build.sh
./build.sh dev          # Usage: ./build.sh [dev|prod|test|clean|docker|release]
```

## Support

For support and questions:
- Create an issue in the GitHub repository
- Email: support@airsense.example.com
- Documentation: [docs.airsense.example.com](https://docs.airsense.example.com)

---

**AirSense Backend** - Built with ❤️ using Golang