#!/bin/bash

# Suna Deployment Script
# This script automates the deployment of the Suna project using Docker

set -e

# Default configuration
GITHUB_USERNAME=""
GITHUB_REPO="suna"
DOCKER_REGISTRY="ghcr.io"
USE_PREBUILT_IMAGES=false

# Default ports
FRONTEND_PORT=3000
BACKEND_PORT=8000
REDIS_PORT=6379
RABBITMQ_PORT=5672

# Color codes for output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Print colored message
echo_color() {
    echo -e "${1}${2}${NC}"
}

# Check if a port is available
check_port_available() {
    local port=$1
    if command -v nc &> /dev/null; then
        nc -z localhost $port &>/dev/null
        if [ $? -eq 0 ]; then
            echo_color "$YELLOW" "Port $port is in use."
            return 1  # Port is in use
        else
            echo_color "$GREEN" "Port $port is available."
            return 0  # Port is available
        fi
    elif command -v lsof &> /dev/null; then
        lsof -i:$port &>/dev/null
        if [ $? -eq 0 ]; then
            echo_color "$YELLOW" "Port $port is in use."
            return 1  # Port is in use
        else
            echo_color "$GREEN" "Port $port is available."
            return 0  # Port is available
        fi
    else
        # If neither nc nor lsof is available, assume port is available but warn user
        echo_color "$YELLOW" "Warning: Cannot check if port $port is available. Proceeding anyway."
        return 0
    fi
}

# Find an available port starting from the given port
find_available_port() {
    local start_port=$1
    local current_port=$start_port
    local max_attempts=10  # Try 10 ports starting from the given one
    
    for (( i=0; i<$max_attempts; i++ )); do
        check_port_available $current_port
        if [ $? -eq 0 ]; then
            echo $current_port
            return 0
        fi
        current_port=$((current_port + 1))
    done
    
    # If we couldn't find an available port, return the original one and the script will handle the error
    echo $start_port
    return 1
}

# Print help message
show_help() {
    echo "Suna Deployment Script"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                     Show this help message"
    echo "  -u, --github-username NAME    Set GitHub username (required for pre-built images)"
    echo "  -r, --github-repo NAME        Set GitHub repository name (default: suna)"
    echo "  -p, --use-prebuilt            Use pre-built images from GitHub Container Registry"
    echo "  -l, --local-build             Build images locally (default)"
    echo "  --frontend-port PORT          Set frontend port (default: $FRONTEND_PORT)"
    echo "  --backend-port PORT           Set backend port (default: $BACKEND_PORT)"
    echo "  --redis-port PORT             Set Redis port (default: $REDIS_PORT)"
    echo "  --rabbitmq-port PORT          Set RabbitMQ port (default: $RABBITMQ_PORT)"
    echo ""
    echo "Examples:"
    echo "  $0 --local-build                        # Build and deploy locally"
    echo "  $0 --github-username myuser --use-prebuilt  # Use pre-built images"
    echo "  $0 --frontend-port 3001 --backend-port 8001  # Use custom ports"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--github-username)
            GITHUB_USERNAME="$2"
            shift
            shift
            ;;
        -r|--github-repo)
            GITHUB_REPO="$2"
            shift
            shift
            ;;
        -p|--use-prebuilt)
            USE_PREBUILT_IMAGES=true
            shift
            ;;
        -l|--local-build)
            USE_PREBUILT_IMAGES=false
            shift
            ;;
        --frontend-port)
            FRONTEND_PORT="$2"
            shift
            shift
            ;;
        --backend-port)
            BACKEND_PORT="$2"
            shift
            shift
            ;;
        --redis-port)
            REDIS_PORT="$2"
            shift
            shift
            ;;
        --rabbitmq-port)
            RABBITMQ_PORT="$2"
            shift
            shift
            ;;
        *)
            echo_color "$RED" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate GitHub username if using pre-built images
if [ "$USE_PREBUILT_IMAGES" = true ] && [ -z "$GITHUB_USERNAME" ]; then
    echo_color "$RED" "ERROR: GitHub username is required when using pre-built images"
    echo_color "$YELLOW" "Please provide a username with --github-username or use --local-build"
    exit 1
fi

echo_color "$BLUE" "============================================"
echo_color "$BLUE" "         Suna Deployment Setup"
echo_color "$BLUE" "============================================"

# Check prerequisites
echo_color "$GREEN" "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo_color "$RED" "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo_color "$RED" "Docker Compose is not available. Please install Docker Compose or update Docker."
    exit 1
fi

# Check if ports are available and find alternatives if needed
echo_color "$GREEN" "Checking port availability..."
echo_color "$BLUE" "Checking frontend port: $FRONTEND_PORT"

# Check Frontend port
check_port_available $FRONTEND_PORT
FRONTEND_PORT_AVAILABLE=$?
echo_color "$BLUE" "Frontend port $FRONTEND_PORT availability status: $FRONTEND_PORT_AVAILABLE"
if [ $FRONTEND_PORT_AVAILABLE -ne 0 ]; then
    echo_color "$YELLOW" "Port $FRONTEND_PORT for frontend is already in use."
    NEW_PORT=$(find_available_port $((FRONTEND_PORT + 1)))
    if [ $? -eq 0 ]; then
        echo_color "$GREEN" "Using alternative port $NEW_PORT for frontend."
        FRONTEND_PORT=$NEW_PORT
    else
        echo_color "$RED" "Could not find an available port for frontend."
        echo_color "$YELLOW" "Please specify a different port with --frontend-port or free up port $FRONTEND_PORT."
        exit 1
    fi
fi

# Check Backend port
check_port_available $BACKEND_PORT
if [ $? -ne 0 ]; then
    echo_color "$YELLOW" "Port $BACKEND_PORT for backend is already in use."
    NEW_PORT=$(find_available_port $((BACKEND_PORT + 1)))
    if [ $? -eq 0 ]; then
        echo_color "$GREEN" "Using alternative port $NEW_PORT for backend."
        BACKEND_PORT=$NEW_PORT
    else
        echo_color "$RED" "Could not find an available port for backend."
        echo_color "$YELLOW" "Please specify a different port with --backend-port or free up port $BACKEND_PORT."
        exit 1
    fi
fi

# Check Redis port
check_port_available $REDIS_PORT
if [ $? -ne 0 ]; then
    echo_color "$YELLOW" "Port $REDIS_PORT for Redis is already in use."
    NEW_PORT=$(find_available_port $((REDIS_PORT + 1)))
    if [ $? -eq 0 ]; then
        echo_color "$GREEN" "Using alternative port $NEW_PORT for Redis."
        REDIS_PORT=$NEW_PORT
    else
        echo_color "$RED" "Could not find an available port for Redis."
        echo_color "$YELLOW" "Please specify a different port with --redis-port or free up port $REDIS_PORT."
        exit 1
    fi
fi

# Check RabbitMQ port
check_port_available $RABBITMQ_PORT
if [ $? -ne 0 ]; then
    echo_color "$YELLOW" "Port $RABBITMQ_PORT for RabbitMQ is already in use."
    NEW_PORT=$(find_available_port $((RABBITMQ_PORT + 1)))
    if [ $? -eq 0 ]; then
        echo_color "$GREEN" "Using alternative port $NEW_PORT for RabbitMQ."
        RABBITMQ_PORT=$NEW_PORT
    else
        echo_color "$RED" "Could not find an available port for RabbitMQ."
        echo_color "$YELLOW" "Please specify a different port with --rabbitmq-port or free up port $RABBITMQ_PORT."
        exit 1
    fi
fi

# Check if backend/.env exists
if [ ! -f "./backend/.env" ]; then
    echo_color "$YELLOW" "Warning: backend/.env file not found. Creating from example."
    
    if [ -f "./backend/.env.example" ]; then
        cp ./backend/.env.example ./backend/.env
        echo_color "$GREEN" "Created backend/.env from example. Please edit it with your actual credentials."
    else
        echo_color "$RED" "No .env.example found. You'll need to create backend/.env manually."
        touch ./backend/.env
    fi
    
    echo_color "$YELLOW" "Please edit backend/.env with your credentials before continuing."
    echo_color "$YELLOW" "Press Enter to continue after editing, or Ctrl+C to exit..."
    read
fi

# Check if frontend/.env.local exists
if [ ! -f "./frontend/.env.local" ]; then
    echo_color "$YELLOW" "Warning: frontend/.env.local file not found. Creating from example."
    
    if [ -f "./frontend/.env.example" ]; then
        cp ./frontend/.env.example ./frontend/.env.local
        echo_color "$GREEN" "Created frontend/.env.local from example. Please edit it with your actual credentials."
    else
        echo_color "$RED" "No .env.example found. You'll need to create frontend/.env.local manually."
        touch ./frontend/.env.local
    fi
    
    echo_color "$YELLOW" "Please edit frontend/.env.local with your credentials before continuing."
    echo_color "$YELLOW" "Press Enter to continue after editing, or Ctrl+C to exit..."
    read
fi

# Configure and start services
echo_color "$GREEN" "Starting deployment..."

# Create temporary docker-compose override file with custom port mappings
COMPOSE_OVERRIDE_FILE="docker-compose.override.yml"
cat > $COMPOSE_OVERRIDE_FILE << EOL
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

# Update environment files with the new ports
if [ -f "./backend/.env" ]; then
    # Update Redis port
    sed -i.bak "s/REDIS_PORT=.*/REDIS_PORT=${REDIS_PORT}/g" ./backend/.env
    # Update RabbitMQ port
    sed -i.bak "s/RABBITMQ_PORT=.*/RABBITMQ_PORT=${RABBITMQ_PORT}/g" ./backend/.env
    # Update public URL
    sed -i.bak "s|NEXT_PUBLIC_URL=.*|NEXT_PUBLIC_URL=\"http://localhost:${FRONTEND_PORT}\"|g" ./backend/.env
    rm -f ./backend/.env.bak 2>/dev/null || true
fi

if [ -f "./frontend/.env.local" ]; then
    # Update backend URL
    sed -i.bak "s|NEXT_PUBLIC_BACKEND_URL=.*|NEXT_PUBLIC_BACKEND_URL=\"http://localhost:${BACKEND_PORT}/api\"|g" ./frontend/.env.local
    # Update public URL
    sed -i.bak "s|NEXT_PUBLIC_URL=.*|NEXT_PUBLIC_URL=\"http://localhost:${FRONTEND_PORT}\"|g" ./frontend/.env.local
    rm -f ./frontend/.env.local.bak 2>/dev/null || true
fi

if [ "$USE_PREBUILT_IMAGES" = true ]; then
    echo_color "$BLUE" "Using pre-built images from $DOCKER_REGISTRY/$GITHUB_USERNAME/$GITHUB_REPO"
    export GITHUB_REPOSITORY="$GITHUB_USERNAME/$GITHUB_REPO"
    docker compose -f docker-compose.ghcr.yaml -f $COMPOSE_OVERRIDE_FILE up -d
else
    echo_color "$BLUE" "Building images locally"
    docker compose -f docker-compose.yaml -f $COMPOSE_OVERRIDE_FILE up -d
fi

# Wait for services to start
echo_color "$GREEN" "Waiting for services to start..."
sleep 5

# Check if services are running
BACKEND_RUNNING=$(docker compose ps | grep backend | grep running | wc -l)
FRONTEND_RUNNING=$(docker compose ps | grep frontend | grep running | wc -l)

if [ "$BACKEND_RUNNING" -eq 0 ] || [ "$FRONTEND_RUNNING" -eq 0 ]; then
    echo_color "$RED" "Some services failed to start. Check the logs:"
    echo_color "$YELLOW" "docker compose logs"
    exit 1
fi

echo_color "$GREEN" "=================================================="
echo_color "$GREEN" "Suna deployment completed successfully!"
echo_color "$GREEN" "=================================================="
echo_color "$BLUE" "Access the application at: http://localhost:${FRONTEND_PORT}"
echo_color "$BLUE" "Backend API available at: http://localhost:${BACKEND_PORT}"
echo_color "$BLUE" "Redis port: ${REDIS_PORT}"
echo_color "$BLUE" "RabbitMQ port: ${RABBITMQ_PORT}"
echo_color "$YELLOW" "For any issues, please check the logs using: docker compose logs"
echo_color "$YELLOW" "To stop the service: docker compose down"

# Clean up the temporary override file when finishing or on interrupt
cleanup() {
    rm -f $COMPOSE_OVERRIDE_FILE 2>/dev/null || true
}

# Register cleanup function for exit and interrupt
trap cleanup EXIT INT TERM