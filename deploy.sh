#!/bin/bash

# Suna Deployment Script
# This script automates the deployment of the Suna project using Docker

set -e

# Default configuration
GITHUB_USERNAME=""
GITHUB_REPO="suna"
DOCKER_REGISTRY="ghcr.io"
USE_PREBUILT_IMAGES=false

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
    echo ""
    echo "Examples:"
    echo "  $0 --local-build                        # Build and deploy locally"
    echo "  $0 --github-username myuser --use-prebuilt  # Use pre-built images"
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

if [ "$USE_PREBUILT_IMAGES" = true ]; then
    echo_color "$BLUE" "Using pre-built images from $DOCKER_REGISTRY/$GITHUB_USERNAME/$GITHUB_REPO"
    export GITHUB_REPOSITORY="$GITHUB_USERNAME/$GITHUB_REPO"
    docker compose -f docker-compose.ghcr.yaml up -d
else
    echo_color "$BLUE" "Building images locally"
    docker compose up -d
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
echo_color "$BLUE" "Access the application at: http://localhost:3000"
echo_color "$BLUE" "Backend API available at: http://localhost:8000"
echo_color "$YELLOW" "For any issues, please check the logs using: docker compose logs"
echo_color "$YELLOW" "To stop the service: docker compose down"