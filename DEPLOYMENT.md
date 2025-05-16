# Suna Deployment Guide

This guide provides instructions for deploying the Suna AI Agent using Docker.

## Prerequisites

Before deploying Suna, ensure you have the following installed on your system:

1. [Docker](https://docs.docker.com/get-docker/)
2. [Docker Compose](https://docs.docker.com/compose/install/) (included in Docker Desktop for Mac/Windows)
3. Git

## Configuration Requirements

You'll need the following to fully configure Suna:

1. **Supabase Project**
   - Create a project at [Supabase](https://supabase.com/dashboard/projects)
   - You'll need the project URL, anon key, and service role key

2. **API Keys**
   - Anthropic API key (recommended) or OpenAI API key
   - Optional: Tavily API key for enhanced search capabilities
   - Optional: Firecrawl API key for web scraping
   - Optional: RapidAPI key for additional API services

3. **Daytona Account** (for agent execution)
   - Create an account at [Daytona](https://app.daytona.io/)
   - Generate an API key from your account settings
   - Add the `kortix/suna:0.1.2` image in your Daytona dashboard

## Deployment Options

You can deploy Suna in two ways:

### Option 1: Using the Deployment Script (Recommended)

The included `deploy.sh` script automates the deployment process:

```bash
# For local build (default)
./deploy.sh --local-build

# For using pre-built images from GitHub Container Registry
./deploy.sh --github-username your-username --use-prebuilt
```

The script will:
1. Check prerequisites
2. Create environment files if they don't exist
3. Build or pull required Docker images
4. Start all services with Docker Compose

### Option 2: Manual Deployment

If you prefer to deploy manually:

1. Create environment files:
   ```bash
   # Backend environment
   cp backend/.env.example backend/.env
   
   # Frontend environment
   cp frontend/.env.example frontend/.env.local
   ```

2. Edit the environment files with your credentials

3. Start the services using Docker Compose:
   ```bash
   # For local build
   docker compose up -d
   
   # OR for pre-built images
   export GITHUB_REPOSITORY="your-username/suna"
   docker compose -f docker-compose.ghcr.yaml up -d
   ```

## Access the Application

After successful deployment, access Suna at:
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000

## Environment Variables

### Backend (.env)

```
NEXT_PUBLIC_URL="http://localhost:3000"

# Supabase credentials
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Redis configuration (for local development)
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_SSL=False

# RabbitMQ configuration
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672

# Daytona credentials
DAYTONA_API_KEY=your_daytona_api_key
DAYTONA_SERVER_URL="https://app.daytona.io/api"
DAYTONA_TARGET="us"

# LLM API keys
ANTHROPIC_API_KEY=your_anthropic_api_key
OPENAI_API_KEY=your_openai_api_key

# Optional API keys
TAVILY_API_KEY=your_tavily_api_key
FIRECRAWL_API_KEY=your_firecrawl_api_key
RAPID_API_KEY=your_rapid_api_key
```

### Frontend (.env.local)

```
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
NEXT_PUBLIC_BACKEND_URL="http://backend:8000/api"
NEXT_PUBLIC_URL="http://localhost:3000"
```

## Managing Your Deployment

- **View logs**: `docker compose logs -f`
- **Stop services**: `docker compose down`
- **Restart services**: `docker compose restart`
- **Update deployment**: Pull the latest changes and run the deploy script again

## Troubleshooting

1. **Services not starting**: Check logs with `docker compose logs`
2. **Connection issues**: Ensure all environment variables are correctly set
3. **Supabase errors**: Verify Supabase project setup and credentials
4. **API connection problems**: Check that the backend API is accessible from the frontend