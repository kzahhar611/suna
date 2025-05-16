#!/bin/bash

set -e

# Define custom ports
FRONTEND_PORT=3001
BACKEND_PORT=8001
REDIS_PORT=6380
RABBITMQ_PORT=5673

echo "Creating docker-compose override file for development mode"

# Create docker-compose override file for development
cat > docker-compose.dev.yml << EOL
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - redis-data:/data
    command: redis-server --save 60 1 --loglevel warning

  rabbitmq:
    image: rabbitmq
    ports:
      - "${RABBITMQ_PORT}:5672"
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq

volumes:
  redis-data:
  rabbitmq_data:
EOL

echo "Starting Redis and RabbitMQ services for development"

# Start only the Redis and RabbitMQ services for development
docker compose -f docker-compose.dev.yml up -d

echo "Deployment completed! Redis and RabbitMQ services are now running."
echo "Redis is available at port: ${REDIS_PORT}"
echo "RabbitMQ is available at port: ${RABBITMQ_PORT}"
echo ""
echo "For local development:"
echo "1. Update 'backend/.env' with these connection details:"
echo "   REDIS_HOST=localhost"
echo "   REDIS_PORT=${REDIS_PORT}"
echo "   RABBITMQ_HOST=localhost"
echo "   RABBITMQ_PORT=${RABBITMQ_PORT}"
echo ""
echo "2. Start backend locally:"
echo "   cd backend && python3 api.py"
echo ""
echo "3. Start frontend locally:"
echo "   cd frontend && npm run dev -- -p ${FRONTEND_PORT}"
