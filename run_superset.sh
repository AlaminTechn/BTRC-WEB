#!/bin/bash
# BTRC QoS Monitoring - Run Apache Superset

cd "/home/alamin/Desktop/Python Projects/BTRC-QoS-Monitoring-Dashboard"

# Activate virtual environment
source superset-venv/bin/activate

# Load environment variables
source .env

echo "========================================"
echo "  Starting Apache Superset"
echo "========================================"
echo ""
echo "Access Superset at: http://localhost:8088"
echo ""
echo "Login credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "Press Ctrl+C to stop"
echo "========================================"
echo ""

# Run Superset
superset run -h 0.0.0.0 -p 8088 --with-threads --reload
