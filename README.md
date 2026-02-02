# BTRC QoS Monitoring Dashboard

A comprehensive Quality of Service monitoring system for Bangladesh Telecommunication Regulatory Commission (BTRC), built with Apache Superset and TimescaleDB.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2 (use `docker compose` command, not `docker-compose`)

**No local Python installation required!** Everything runs in Docker containers.

---

## Quick Start

### 1. Setup Environment Variables

```bash
# Copy example env file
cp .env.example .env

# Edit if needed (defaults work for local development)
nano .env
```

### 2. Start Database

```bash
docker compose up -d btrc-db
```

Wait for database to be healthy:

```bash
docker compose ps
# Should show: btrc-db ... healthy
```

### 3. Load Sample Data

```bash
docker compose run --rm data-loader
```

This loads all JSON data files from `dummy_data_v/dummy_data/` into the database.

### 4. Start Superset

```bash
# Initialize Superset (first time only)
docker compose up superset-init

# Start all services
docker compose up -d
```

### 5. Access Dashboard

- **URL**: http://localhost:8088
- **Username**: `admin`
- **Password**: `admin123`

---

## Services

| Service | Container | Port | Description |
|---------|-----------|------|-------------|
| btrc-db | btrc-db | 5434 | TimescaleDB (PostgreSQL) with QoS data |
| superset | btrc-superset | 8088 | Apache Superset dashboard |
| superset-db | superset-db | - | Superset metadata database |
| redis | superset-redis | - | Superset caching |
| data-loader | btrc-data-loader | - | Loads JSON data (run once) |

---

## Common Commands

### Start/Stop Services

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d btrc-db

# Stop all services
docker compose down

# Stop and remove volumes (CAUTION: deletes data)
docker compose down -v
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f superset
docker compose logs -f btrc-db
```

### Database Operations

```bash
# Connect to database
docker exec -it btrc-db psql -U btrc -d btrc_qos

# Export database
docker exec btrc-db pg_dump -U btrc -d btrc_qos > exports/backup.sql

# Import database
docker exec -i btrc-db psql -U btrc -d btrc_qos < exports/backup.sql

# Check table counts
docker exec btrc-db psql -U btrc -d btrc_qos -c "
SELECT
    (SELECT COUNT(*) FROM isps) as isps,
    (SELECT COUNT(*) FROM pops) as pops,
    (SELECT COUNT(*) FROM ts_qos_measurements) as qos_records;
"
```

### Reload Data

```bash
# Run data loader again
docker compose run --rm data-loader
```

---

## Database Connection

Connect Superset to the BTRC database:

| Setting | Value |
|---------|-------|
| Host | `btrc-db` (Docker network) or `localhost` (external) |
| Port | `5432` (Docker network) or `5434` (external) |
| Database | `btrc_qos` |
| Username | `btrc` |
| Password | `btrc_password` |

**SQLAlchemy URI (for Superset):**
```
postgresql://btrc:btrc_password@btrc-db:5432/btrc_qos
```

---

## Project Structure

```
BTRC-QoS-Monitoring-Dashboard/
├── docker-compose.yml          # Docker services configuration
├── Dockerfile.dataloader       # Data loader image
├── requirements.txt            # Python dependencies (for Docker)
├── load_data_docker.py         # Data loader script (Docker version)
├── load_data.py                # Data loader script (local version)
├── superset_config.py          # Superset configuration
├── init-scripts/               # Database initialization scripts
├── dummy_data_v/               # Sample JSON data files
│   └── dummy_data/
│       ├── P.01_geo_divisions.json
│       ├── B.01_isps.json
│       ├── D.03_ts_qos_measurements.json
│       └── ...
├── exports/                    # Database backups
├── REGULATORY-DASHBOARD-GUIDE.md
├── REGULATORY-DASHBOARD-DATASETS.md
├── EXECUTIVE-DASHBOARD-DEPLOYMENT.md
└── SUPERSET-DASHBOARD-GUIDE.md
```

---

## Dashboards

### 1. Executive Dashboard
High-level KPIs for management decisions.

### 2. Regulatory Dashboard (5 Tabs)
- **Tab 1**: SLA Monitoring - Are ISPs meeting commitments?
- **Tab 2**: Regional Analysis - Where are issues concentrated?
- **Tab 3**: Violation Reporting - Document violations
- **Tab 4**: Investigation Center - Root cause analysis
- **Tab 5**: License Compliance - Infrastructure commitments

### 3. Tech-Ops Dashboard (Coming Soon)
Technical operations monitoring.

---

## Data Statistics

| Table | Records |
|-------|---------|
| ISPs | 40 |
| PoPs | 120 |
| QoS Measurements | ~345,600 |
| Violations | 150 |
| Divisions | 8 |
| Districts | 64 |

**Date Range**: 2025-11-30 to 2025-12-15

---

## Troubleshooting

### Port 8088 already in use

```bash
# Find process using port
lsof -i :8088

# Kill process or use different port
docker compose down
# Edit docker-compose.yml to change port, then:
docker compose up -d
```

### Database connection failed

```bash
# Check if database is running
docker compose ps

# Check database logs
docker compose logs btrc-db

# Restart database
docker compose restart btrc-db
```

### Superset not starting

```bash
# Check logs
docker compose logs superset

# Re-initialize
docker compose down
docker compose up superset-init
docker compose up -d
```

### Data loader fails

```bash
# Check if database is healthy first
docker compose ps

# Run with logs visible
docker compose run data-loader

# Check data directory exists
ls -la dummy_data_v/dummy_data/
```

---

## License

BTRC Internal Use Only
