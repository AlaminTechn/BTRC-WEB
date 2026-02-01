#!/bin/bash
# BTRC QoS Database Import Script
# Restores database from backup file

set -e

if [ -z "$1" ]; then
    echo "Usage: ./import_data.sh <backup_file.sql>"
    echo ""
    echo "Example: ./import_data.sh exports/btrc_qos_backup_20260129.sql"
    exit 1
fi

IMPORT_FILE="$1"

# Check if file exists
if [ ! -f "${IMPORT_FILE}" ]; then
    # Try with .gz extension
    if [ -f "${IMPORT_FILE}.gz" ]; then
        echo "Decompressing ${IMPORT_FILE}.gz..."
        gunzip -k "${IMPORT_FILE}.gz"
    else
        echo "Error: File not found: ${IMPORT_FILE}"
        exit 1
    fi
fi

echo "=========================================="
echo "  BTRC QoS Database Import"
echo "=========================================="
echo ""

# Check if container is running
if ! docker ps | grep -q btrc-db; then
    echo "Error: btrc-db container is not running"
    echo "Start it with: docker-compose up -d btrc-db"
    exit 1
fi

echo "WARNING: This will replace all existing data!"
read -p "Continue? (y/N): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Importing from: ${IMPORT_FILE}"
echo ""

# Drop and recreate database
echo "Recreating database..."
docker exec btrc-db psql -U btrc -d postgres -c "DROP DATABASE IF EXISTS btrc_qos;"
docker exec btrc-db psql -U btrc -d postgres -c "CREATE DATABASE btrc_qos;"

# Import data
echo "Importing data..."
docker exec -i btrc-db psql -U btrc -d btrc_qos < "${IMPORT_FILE}"

echo ""
echo "=========================================="
echo "  Import Complete!"
echo "=========================================="
echo ""

# Verify
echo "Verification:"
docker exec btrc-db psql -U btrc -d btrc_qos -c "
SELECT
    (SELECT COUNT(*) FROM isps) as isps,
    (SELECT COUNT(*) FROM pops) as pops,
    (SELECT COUNT(*) FROM ts_qos_measurements) as qos_records;
"
