#!/bin/bash

set -e

# Define custom ports
FRONTEND_PORT=3001
BACKEND_PORT=8001
REDIS_PORT=6380
RABBITMQ_PORT=5673

echo "Creating docker-compose override file"

# Create docker-compose override file
cat > docker-compose.override.yml << EOL
version: '3.8'

services:
  redis:
    ports:
      - "${REDIS_PORT}:6379"
  
  rabbitmq:
    ports:
      - "${RABBITMQ_PORT}:5672"
  
  backend:
    ports:
      - "${BACKEND_PORT}:8000"
    environment:
      - REDIS_PORT=${REDIS_PORT}
      - RABBITMQ_PORT=${RABBITMQ_PORT}
  
  frontend:
    ports:
      - "${FRONTEND_PORT}:3000"
    environment:
      - NEXT_PUBLIC_BACKEND_URL=http://localhost:${BACKEND_PORT}/api
      - NEXT_PUBLIC_URL=http://localhost:${FRONTEND_PORT}
EOL

echo "Starting services with docker-compose"

# Start services with docker compose
docker compose -f docker-compose.yaml -f docker-compose.override.yml up -d

echo "Deployment completed!"
echo "Access the application at: http://localhost:${FRONTEND_PORT}"
echo "Backend API available at: http://localhost:${BACKEND_PORT}"
