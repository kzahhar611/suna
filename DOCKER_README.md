# Suna Docker Deployment

This document provides instructions for deploying Suna using Docker containers.

## Overview

This Docker deployment includes:

- **Frontend**: Next.js application with optimized multi-stage build
- **Backend API**: FastAPI service with Gunicorn for production serving
- **Backend Worker**: Background processing for agent tasks
- **Redis**: For caching and session management
- **RabbitMQ**: Message queue for backend workers

## Prerequisites

- Docker and Docker Compose installed
- Git (to clone the repository)
- Basic knowledge of Docker and containerization

## Quick Start

The easiest way to deploy is using the provided script:

```bash
./deploy-docker.sh
```

This script will:
1. Check for dependencies and environment files
2. Set up the necessary environment variables
3. Build the Docker images with optimized, multi-stage builds
4. Start all services with the correct configuration

## Manual Deployment

You can also deploy manually using Docker Compose:

```bash
# Set environment variables (optional)
export FRONTEND_PORT=3001
export BACKEND_PORT=8000
export REDIS_PORT=6380
export RABBITMQ_PORT=5673
export RABBITMQ_MANAGEMENT_PORT=15673
export ENV_MODE=production

# Build and start the containers
docker compose build --no-cache
docker compose up -d
```

## Configuration

### Environment Variables

You can customize the deployment by setting these environment variables:

- `FRONTEND_PORT`: Frontend web UI port (default: 3001)
- `BACKEND_PORT`: Backend API port (default: 8000)
- `REDIS_PORT`: Redis port (default: 6379)
- `RABBITMQ_PORT`: RabbitMQ port (default: 5672)
- `RABBITMQ_MANAGEMENT_PORT`: RabbitMQ management interface port (default: 15672)
- `ENV_MODE`: Environment mode (default: production)

### Volume Persistence

The deployment uses named volumes for data persistence:

- `sungai_redis_data`: Redis data
- `sungai_rabbitmq_data`: RabbitMQ data
- `sungai_backend_logs`: Backend application logs

## Accessing Services

After deployment, you can access the services at:

- **Frontend**: http://localhost:<FRONTEND_PORT>
- **Backend API**: http://localhost:<BACKEND_PORT>
- **RabbitMQ Management**: http://localhost:<RABBITMQ_MANAGEMENT_PORT>

## Management Commands

```bash
# View logs
docker compose logs -f

# View logs for a specific service
docker compose logs -f backend

# Stop all services
docker compose down

# Restart a specific service
docker compose restart backend

# Scale worker processes
docker compose up -d --scale backend-worker=3
```

## Architecture

The Docker deployment follows these principles:

1. **Multi-stage builds** for smaller, more efficient images
2. **Non-root users** for enhanced security
3. **Health checks** for service monitoring
4. **Named volumes** for data persistence
5. **Service dependency management** for proper startup order

## Troubleshooting

### Container fails to start

Check the logs:
```bash
docker compose logs <service_name>
```

### Backend can't connect to Redis or RabbitMQ

Verify the services are running and check the environment configuration:
```bash
docker compose ps
docker compose exec backend env | grep REDIS
docker compose exec backend env | grep RABBITMQ
```

### Frontend shows "Cannot connect to backend"

Verify the backend is healthy and CORS is properly configured:
```bash
curl http://localhost:<BACKEND_PORT>/api/health
```