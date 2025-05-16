#!/bin/bash

set -e

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Print colored message
echo_color() {
    echo -e "${1}${2}${NC}"
}

# Environment variables with defaults
ENV_MODE=${ENV_MODE:-production}
FRONTEND_PORT=${FRONTEND_PORT:-3001}
BACKEND_PORT=${BACKEND_PORT:-8000}
REDIS_PORT=${REDIS_PORT:-6379}
RABBITMQ_PORT=${RABBITMQ_PORT:-5672}
RABBITMQ_MANAGEMENT_PORT=${RABBITMQ_MANAGEMENT_PORT:-15672}

# Display deployment configuration
echo_color "$BLUE" "========================================="
echo_color "$BLUE" "      Suna Docker Deployment Tool      "
echo_color "$BLUE" "========================================="
echo_color "$GREEN" "Environment: $ENV_MODE"
echo_color "$GREEN" "Frontend Port: $FRONTEND_PORT"
echo_color "$GREEN" "Backend Port: $BACKEND_PORT"
echo_color "$GREEN" "Redis Port: $REDIS_PORT"
echo_color "$GREEN" "RabbitMQ Port: $RABBITMQ_PORT"
echo_color "$GREEN" "RabbitMQ Management Port: $RABBITMQ_MANAGEMENT_PORT"
echo

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo_color "$RED" "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo_color "$RED" "Docker Compose is not available. Please install Docker Compose or update Docker."
    exit 1
fi

# Check if .env files exist
if [ ! -f "./backend/.env" ]; then
    echo_color "$YELLOW" "Warning: backend/.env file not found."
    
    if [ -f "./backend/.env.example" ]; then
        cp ./backend/.env.example ./backend/.env
        echo_color "$GREEN" "Created backend/.env from example. Please edit it with your actual credentials."
    else
        echo_color "$RED" "No .env.example found. You need to create backend/.env manually."
        touch ./backend/.env
    fi
    
    echo_color "$YELLOW" "Please configure your backend/.env file before continuing."
    echo_color "$YELLOW" "Press Enter to continue or Ctrl+C to exit and configure the file."
    read
fi

if [ ! -f "./frontend/.env.local" ]; then
    echo_color "$YELLOW" "Warning: frontend/.env.local file not found."
    
    if [ -f "./frontend/.env.example" ]; then
        cp ./frontend/.env.example ./frontend/.env.local
        echo_color "$GREEN" "Created frontend/.env.local from example. Please edit it with your actual credentials."
    else
        echo_color "$RED" "No .env.example found. You need to create frontend/.env.local manually."
        touch ./frontend/.env.local
    fi
    
    echo_color "$YELLOW" "Please configure your frontend/.env.local file before continuing."
    echo_color "$YELLOW" "Press Enter to continue or Ctrl+C to exit and configure the file."
    read
fi

# Update environment variables in .env files
echo_color "$BLUE" "Updating environment variables in configuration files..."

# Update backend .env
sed -i.bak "s/^ENV_MODE=.*/ENV_MODE=$ENV_MODE/g" ./backend/.env
sed -i.bak "s/^REDIS_HOST=.*/REDIS_HOST=redis/g" ./backend/.env
sed -i.bak "s/^REDIS_PORT=.*/REDIS_PORT=6379/g" ./backend/.env
sed -i.bak "s/^REDIS_SSL=.*/REDIS_SSL=False/g" ./backend/.env
sed -i.bak "s/^RABBITMQ_HOST=.*/RABBITMQ_HOST=rabbitmq/g" ./backend/.env
sed -i.bak "s/^RABBITMQ_PORT=.*/RABBITMQ_PORT=5672/g" ./backend/.env
rm -f ./backend/.env.bak

# Update frontend .env.local
sed -i.bak "s|^NEXT_PUBLIC_BACKEND_URL=.*|NEXT_PUBLIC_BACKEND_URL=\"http://localhost:$BACKEND_PORT/api\"|g" ./frontend/.env.local
sed -i.bak "s|^NEXT_PUBLIC_URL=.*|NEXT_PUBLIC_URL=\"http://localhost:$FRONTEND_PORT\"|g" ./frontend/.env.local
rm -f ./frontend/.env.local.bak

# Export environment variables for docker-compose
export ENV_MODE FRONTEND_PORT BACKEND_PORT REDIS_PORT RABBITMQ_PORT RABBITMQ_MANAGEMENT_PORT

# Build and start Docker containers
echo_color "$BLUE" "Building and starting Docker containers..."
docker compose down

# Build backend first
echo_color "$BLUE" "Building backend image..."
docker compose build backend

# Build frontend
echo_color "$BLUE" "Building frontend image..."
docker compose build frontend

echo_color "$BLUE" "Starting services..."
docker compose up -d

# Wait for services to start
echo_color "$GREEN" "Waiting for services to start..."
sleep 5

# Check if services are running
if docker compose ps | grep -q "Exit"; then
    echo_color "$RED" "Some containers have exited. Check the logs with 'docker compose logs'"
    exit 1
fi

echo_color "$GREEN" "========================================="
echo_color "$GREEN" "      Suna deployment completed!        "
echo_color "$GREEN" "========================================="
echo_color "$BLUE" "Frontend: http://localhost:$FRONTEND_PORT"
echo_color "$BLUE" "Backend API: http://localhost:$BACKEND_PORT"
echo_color "$BLUE" "Redis: localhost:$REDIS_PORT"
echo_color "$BLUE" "RabbitMQ: localhost:$RABBITMQ_PORT"
echo_color "$BLUE" "RabbitMQ Management: http://localhost:$RABBITMQ_MANAGEMENT_PORT"
echo
echo_color "$YELLOW" "To view logs: docker compose logs -f"
echo_color "$YELLOW" "To stop services: docker compose down"
echo_color "$YELLOW" "To restart services: docker compose restart"