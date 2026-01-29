# BTRC QoS Monitoring Dashboard - Apache Superset Setup

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Python 3.8+ (for data loading)

### 1. Start the Services

```bash
# Option A: Using the startup script
./start.sh

# Option B: Manual startup
docker-compose up -d
```

### 2. Initialize Superset (first time only)

```bash
docker-compose up superset-init
```

### 3. Load Data into Database

```bash
# Install Python dependency
pip install psycopg2-binary

# Load the data
python load_data.py
```

### 4. Access Superset

Open http://localhost:8088 in your browser

**Login Credentials:**
- Username: `admin`
- Password: `admin123`

## Configure Superset Database Connection

1. Login to Superset
2. Go to **Settings** → **Database Connections** → **+ Database**
3. Select **PostgreSQL**
4. Enter connection details:
   - Host: `btrc-db`
   - Port: `5432`
   - Database: `btrc_qos`
   - Username: `btrc`
   - Password: `btrc_password`

Or use this connection string:
```
postgresql://btrc:btrc_password@btrc-db:5432/btrc_qos
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| Superset | 8088 | Apache Superset Dashboard |
| BTRC DB | 5432 | TimescaleDB (main data) |
| Superset DB | - | PostgreSQL (Superset metadata) |
| Redis | - | Caching |

## Managing Services

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f superset

# Restart a specific service
docker-compose restart superset
```

## Data Files

Located in `dummy_data_v/dummy_data/`:

| File | Records | Description |
|------|---------|-------------|
| P.01_geo_divisions.json | 8 | Bangladesh divisions |
| P.02_geo_districts.json | 64 | Bangladesh districts |
| P.04_isp_license_categories.json | 3 | ISP license types |
| A.01-A.05 | 27 | Lookup tables |
| B.01-B.06 | ~550 | Master data (ISPs, PoPs, etc.) |
| C.01-C.02 | ~640 | Relationships |
| D.01-D.03 | ~750,000 | Time-series metrics |
| E.01 | ~150 | SLA violations |

## Troubleshooting

### Database Connection Failed
```bash
# Check if btrc-db is running
docker ps | grep btrc-db

# Check database logs
docker-compose logs btrc-db
```

### Superset Not Starting
```bash
# Check Superset logs
docker-compose logs superset

# Restart Superset
docker-compose restart superset
```

### Data Loading Issues
```bash
# Connect to database directly
docker exec -it btrc-db psql -U btrc -d btrc_qos

# Check table counts
SELECT 'isps' as table_name, COUNT(*) FROM isps
UNION ALL SELECT 'pops', COUNT(*) FROM pops
UNION ALL SELECT 'ts_qos_measurements', COUNT(*) FROM ts_qos_measurements;
```
