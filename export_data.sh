#!/bin/bash
# BTRC QoS Database Export Script
# Exports all data for backup or migration

set -e

EXPORT_DIR="./exports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EXPORT_FILE="${EXPORT_DIR}/btrc_qos_backup_${TIMESTAMP}.sql"

# Create exports directory
mkdir -p "${EXPORT_DIR}"

echo "=========================================="
echo "  BTRC QoS Database Export"
echo "=========================================="
echo ""

# Check if container is running
if ! docker ps | grep -q btrc-db; then
    echo "Error: btrc-db container is not running"
    echo "Start it with: docker-compose up -d btrc-db"
    exit 1
fi

echo "Exporting database to: ${EXPORT_FILE}"
echo ""

# Full database dump
docker exec btrc-db pg_dump -U btrc -d btrc_qos > "${EXPORT_FILE}"

echo "Creating compressed archive..."
gzip -k "${EXPORT_FILE}"

echo ""
echo "=========================================="
echo "  Export Complete!"
echo "=========================================="
echo ""
echo "Files created:"
echo "  - ${EXPORT_FILE}"
echo "  - ${EXPORT_FILE}.gz"
echo ""
echo "File sizes:"
ls -lh "${EXPORT_FILE}"* 2>/dev/null
echo ""
echo "To restore on another server:"
echo "  gunzip ${EXPORT_FILE}.gz"
echo "  docker exec -i btrc-db psql -U btrc -d btrc_qos < ${EXPORT_FILE}"
