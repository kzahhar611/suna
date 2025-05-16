# Suna Docker Deployment

This repository contains deployment scripts and configuration for the Suna AI Agent project. It's based on the [original Suna project](https://github.com/kortix-ai/suna) with added Docker deployment automation.

## Features

- **Automated Deployment**: Simple shell script for one-command deployment
- **Docker-based**: All components run in containers for consistent deployment
- **Flexible Configuration**: Use local builds or pre-built images
- **Dynamic Port Management**: Automatic port availability checking and reassignment
- **Environment Management**: Helper functions for environment setup

## Quick Start

```bash
# Clone the repository
git clone https://github.com/your-username/suna-deployment.git
cd suna-deployment

# Run the deployment script
./deploy.sh --local-build
```

The application will be available at:
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000

## Deployment Options

### Local Build (Default)

Build all Docker images locally:

```bash
./deploy.sh --local-build
```

### Pre-built Images

Use pre-built images from GitHub Container Registry:

```bash
./deploy.sh --github-username your-username --use-prebuilt
```

### Custom Ports

Specify custom ports for services:

```bash
./deploy.sh --frontend-port 3001 --backend-port 8001
```

The script automatically checks if specified ports are available. If a port is already in use, it will find the next available port automatically.

## Configuration

Before deployment, you need to set up environment files:

1. Copy the example files:
   ```bash
   cp backend/.env.example backend/.env
   cp frontend/.env.example frontend/.env.local
   ```

2. Edit the files with your credentials (see [DEPLOYMENT.md](DEPLOYMENT.md) for details)

## Documentation

For detailed deployment instructions, configuration options, and troubleshooting, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Project Architecture

Suna consists of four main components:

1. **Backend API**: Python/FastAPI service for REST endpoints, thread management, and LLM integration
2. **Frontend**: Next.js/React application with chat interface and dashboard
3. **Agent Docker**: Isolated execution environment for each agent
4. **Supabase Database**: Handles data persistence, authentication, and real-time subscriptions

## License

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](./LICENSE) file for details.