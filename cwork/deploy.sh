#!/bin/bash

# Cwork Deployment Script
# This script builds and deploys the Cwork MVP using Docker Compose

set -e  # Exit on error

echo "🚀 Starting Cwork MVP Deployment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build and start services using docker-compose
echo "📦 Building and starting services..."
docker-compose -f docker-compose.yml up --build -d

echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Services are now running:"
echo "   - Auth Service: http://localhost:3000"
echo "   - Marketplace Service: http://localhost:3002"
echo "   - PostgreSQL Database: localhost:5432"
echo "   - Redis: localhost:6379"
echo ""
echo "To view logs, run: docker-compose logs -f"
echo "To stop services, run: docker-compose down"