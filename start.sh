#!/bin/bash
# BTRC QoS Monitoring - Startup Script

set -e

echo "========================================"
echo "  BTRC QoS Monitoring - Setup"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Step 1: Start containers
echo -e "\n${YELLOW}Step 1: Starting Docker containers...${NC}"
docker-compose up -d btrc-db redis superset-db

# Wait for databases to be ready
echo -e "\n${YELLOW}Waiting for databases to be ready...${NC}"
sleep 10

# Check if btrc-db is ready
echo "Checking btrc-db..."
until docker exec btrc-db pg_isready -U btrc -d btrc_qos > /dev/null 2>&1; do
    echo "  Waiting for btrc-db..."
    sleep 2
done
echo -e "${GREEN}btrc-db is ready!${NC}"

# Check if superset-db is ready
echo "Checking superset-db..."
until docker exec superset-db pg_isready -U superset -d superset > /dev/null 2>&1; do
    echo "  Waiting for superset-db..."
    sleep 2
done
echo -e "${GREEN}superset-db is ready!${NC}"

# Step 2: Initialize Superset
echo -e "\n${YELLOW}Step 2: Initializing Superset...${NC}"
docker-compose up superset-init
echo -e "${GREEN}Superset initialized!${NC}"

# Step 3: Start Superset
echo -e "\n${YELLOW}Step 3: Starting Superset...${NC}"
docker-compose up -d superset

# Wait for Superset to be ready
echo "Waiting for Superset to start..."
sleep 15

# Step 4: Load data (optional)
echo -e "\n${YELLOW}Step 4: Do you want to load the dummy data? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Installing Python dependencies..."
    pip install psycopg2-binary > /dev/null 2>&1 || pip3 install psycopg2-binary > /dev/null 2>&1

    echo "Loading data..."
    python3 load_data.py || python load_data.py
fi

echo -e "\n========================================"
echo -e "${GREEN}  Setup Complete!${NC}"
echo "========================================"
echo ""
echo "Access Superset at: http://localhost:8088"
echo ""
echo "Login credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "BTRC Database connection string (for Superset):"
echo "  postgresql://btrc:btrc_password@btrc-db:5432/btrc_qos"
echo ""
echo "To stop all services:"
echo "  docker-compose down"
echo ""
