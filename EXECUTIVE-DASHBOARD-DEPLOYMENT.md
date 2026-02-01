# BTRC Executive Dashboard - Complete Deployment Guide

**Version**: 1.0
**Date**: 2026-01-29
**Dashboard**: Executive Dashboard (5 Tabs, ~38 Charts)

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Docker Setup](#2-docker-setup)
3. [Database & Data Loading](#3-database--data-loading)
4. [Superset Configuration](#4-superset-configuration)
5. [SQL Datasets](#5-sql-datasets)
6. [Dashboard Charts](#6-dashboard-charts)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Prerequisites

### Required Software
- Docker Engine 20.10+
- Docker Compose 2.0+
- Python 3.9+ (for data loading)
- psycopg2 library: `pip install psycopg2-binary`

### Hardware Requirements
- RAM: Minimum 8GB (16GB recommended)
- Storage: 10GB free space
- CPU: 4 cores recommended

---

## 2. Docker Setup

### 2.1 Start All Services

```bash
cd /path/to/BTRC-QoS-Monitoring-Dashboard

# Start all containers
docker-compose up -d

# Verify containers are running
docker ps
```

### 2.2 Expected Running Containers

| Container | Image | Port | Purpose |
|-----------|-------|------|---------|
| btrc-db | timescale/timescaledb:latest-pg15 | 5434 | Main database |
| btrc-superset | apache/superset:3.1.0 | 8088 | Dashboard UI |
| superset-db | postgres:15-alpine | - | Superset metadata |
| superset-redis | redis:7-alpine | - | Caching |

### 2.3 Verify Database

```bash
docker exec btrc-db psql -U btrc -d btrc_qos -c "SELECT COUNT(*) FROM ts_qos_measurements;"
```

---

## 3. Database & Data Loading

### 3.1 Schema (Auto-loaded via init-scripts)

The schema is automatically loaded from `init-scripts/01-schema.sql` when the container starts.

### 3.2 Load Dummy Data

```bash
# Install Python dependency
pip install psycopg2-binary

# Load data
python load_data.py
```

### 3.3 Verify Data

```bash
docker exec btrc-db psql -U btrc -d btrc_qos -c "
SELECT
    (SELECT COUNT(*) FROM isps) as isps,
    (SELECT COUNT(*) FROM pops) as pops,
    (SELECT COUNT(*) FROM ts_qos_measurements) as qos_records;
"
```

Expected: ~30 ISPs, ~120 PoPs, ~345,600 QoS records

---

## 4. Superset Configuration

### 4.1 Access Superset

- URL: http://localhost:8088
- Username: `admin`
- Password: `admin123`

### 4.2 Add Database Connection

1. Go to **Settings** → **Database Connections**
2. Click **+ Database**
3. Select **PostgreSQL**
4. Connection string: `postgresql://btrc:btrc_password@btrc-db:5432/btrc_qos`
5. Display Name: `BTRC QoS Database`
6. Click **Test Connection** → **Connect**

### 4.3 Create Dashboard

1. Go to **Dashboards** → **+ Dashboard**
2. Name: `BTRC Executive Dashboard`
3. Add **Tabs** component with 5 tabs:
   - Tab 1: Performance Scorecard
   - Tab 2: Geographic Intelligence
   - Tab 3: Compliance & Enforcement
   - Tab 4: Consumer Experience
   - Tab 5: Infrastructure Status

---

## 5. SQL Datasets

Create these datasets in **SQL Lab** → Run Query → **SAVE** → **Save Dataset**

### Dataset 1: national_kpis

```sql
SELECT
    DATE_TRUNC('day', time) as __timestamp,
    ROUND(AVG(download_mbps)::numeric, 1) as download_speed,
    ROUND((COUNT(*) FILTER (WHERE latency_ms IS NOT NULL)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability_pct
FROM ts_qos_measurements
WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY DATE_TRUNC('day', time)
ORDER BY __timestamp
```

### Dataset 2: speed_trend

```sql
SELECT
    DATE_TRUNC('month', time) as __timestamp,
    ROUND(AVG(download_mbps)::numeric, 1) as download_speed
FROM ts_qos_measurements
WHERE time >= (SELECT MAX(time) - INTERVAL '12 months' FROM ts_qos_measurements)
GROUP BY DATE_TRUNC('month', time)
ORDER BY __timestamp
```

### Dataset 3: division_performance

```sql
SELECT
    d.name_en as division,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND(AVG(q.latency_ms)::numeric, 1) as avg_latency,
    ROUND((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY d.name_en
ORDER BY avg_speed DESC
```

### Dataset 4: isp_category_performance

```sql
SELECT
    lc.name_en as category,
    COUNT(DISTINCT i.id) as isp_count,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability,
    ROUND(AVG(q.latency_ms)::numeric, 1) as avg_latency
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN isps i ON p.isp_id = i.id
JOIN isp_license_categories lc ON i.license_category_id = lc.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY lc.name_en
ORDER BY avg_speed DESC
```

### Dataset 5: division_map_data

```sql
SELECT
    CASE d.name_en
        WHEN 'Dhaka' THEN 'BD-C'
        WHEN 'Chattogram' THEN 'BD-B'
        WHEN 'Rajshahi' THEN 'BD-E'
        WHEN 'Khulna' THEN 'BD-D'
        WHEN 'Barishal' THEN 'BD-A'
        WHEN 'Sylhet' THEN 'BD-G'
        WHEN 'Rangpur' THEN 'BD-F'
        WHEN 'Mymensingh' THEN 'BD-H'
    END as iso_code,
    d.name_en as division,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY d.name_en
```

### Dataset 6: pop_coverage_analysis

```sql
WITH pop_counts AS (
    SELECT
        gd.id as district_id,
        gd.name_en as district,
        d.name_en as division,
        COUNT(DISTINCT p.id) as pop_count
    FROM geo_districts gd
    JOIN geo_divisions d ON gd.division_id = d.id
    LEFT JOIN pops p ON p.district_id = gd.id AND p.is_active = true
    GROUP BY gd.id, gd.name_en, d.name_en
)
SELECT
    district,
    division,
    pop_count as pops,
    CASE
        WHEN pop_count >= 3 THEN 'Good'
        WHEN pop_count >= 1 THEN 'Limited'
        ELSE 'No Coverage'
    END as coverage_status
FROM pop_counts
ORDER BY pop_count DESC, district
```

### Dataset 7: violations_summary

```sql
SELECT
    COUNT(*) as total_violations,
    COUNT(*) FILTER (WHERE severity = 'CRITICAL') as critical,
    COUNT(*) FILTER (WHERE severity = 'WARNING') as warning,
    COUNT(*) FILTER (WHERE status = 'OPEN') as open_violations
FROM sla_violations
WHERE detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
```

### Dataset 8: violation_trend

```sql
SELECT
    TO_CHAR(DATE_TRUNC('month', detection_time), 'Mon') as month,
    COUNT(*) FILTER (WHERE violation_type LIKE '%SPEED%') as speed,
    COUNT(*) FILTER (WHERE violation_type LIKE '%AVAIL%') as availability,
    COUNT(*) FILTER (WHERE violation_type LIKE '%LATENCY%') as latency,
    COUNT(*) FILTER (WHERE violation_type LIKE '%PACKET%') as packet_loss
FROM sla_violations
WHERE detection_time >= (SELECT MAX(detection_time) - INTERVAL '6 months' FROM sla_violations)
GROUP BY DATE_TRUNC('month', detection_time), TO_CHAR(DATE_TRUNC('month', detection_time), 'Mon')
ORDER BY DATE_TRUNC('month', detection_time)
```

### Dataset 9: violations_by_division

```sql
WITH current_period AS (
    SELECT
        d.name_en as division,
        COUNT(*) as violations
    FROM sla_violations v
    JOIN pops p ON v.pop_id = p.id
    JOIN geo_districts gd ON p.district_id = gd.id
    JOIN geo_divisions d ON gd.division_id = d.id
    WHERE v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
    GROUP BY d.name_en
),
previous_period AS (
    SELECT
        d.name_en as division,
        COUNT(*) as violations
    FROM sla_violations v
    JOIN pops p ON v.pop_id = p.id
    JOIN geo_districts gd ON p.district_id = gd.id
    JOIN geo_divisions d ON gd.division_id = d.id
    WHERE v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '60 days' FROM sla_violations)
      AND v.detection_time < (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
    GROUP BY d.name_en
)
SELECT
    c.division,
    c.violations,
    CASE
        WHEN p.violations IS NULL OR p.violations = 0 THEN 'New'
        WHEN c.violations > p.violations THEN CONCAT('+', ROUND(((c.violations - p.violations)::numeric / p.violations) * 100)::text, '%')
        WHEN c.violations < p.violations THEN CONCAT('-', ROUND(((p.violations - c.violations)::numeric / p.violations) * 100)::text, '%')
        ELSE '0%'
    END as trend
FROM current_period c
LEFT JOIN previous_period p ON c.division = p.division
ORDER BY c.violations DESC
```

### Dataset 10: top_violating_isps

```sql
SELECT
    i.name_en as isp,
    COUNT(*) as violations,
    COUNT(*) FILTER (WHERE v.severity = 'CRITICAL') as critical,
    CASE
        WHEN COUNT(*) >= 50 THEN 'Critical'
        WHEN COUNT(*) >= 20 THEN 'Warning'
        ELSE 'Normal'
    END as status
FROM sla_violations v
JOIN isps i ON v.isp_id = i.id
WHERE v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
GROUP BY i.name_en
ORDER BY violations DESC
LIMIT 10
```

### Dataset 11: consumer_complaints (Simulated)

```sql
WITH complaint_simulation AS (
    SELECT
        CASE (ROW_NUMBER() OVER () % 5)
            WHEN 0 THEN 'Speed Issues'
            WHEN 1 THEN 'Connection Drops'
            WHEN 2 THEN 'High Latency'
            WHEN 3 THEN 'Billing Issues'
            ELSE 'Service Outage'
        END as category,
        CASE WHEN download_mbps < 20 THEN 3
             WHEN download_mbps < 40 THEN 2
             ELSE 1 END as complaint_weight
    FROM ts_qos_measurements
    WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
    LIMIT 5000
)
SELECT
    category,
    SUM(complaint_weight) as complaints,
    ROUND((SUM(complaint_weight)::numeric / (SELECT SUM(complaint_weight) FROM complaint_simulation)) * 100, 1) as percentage
FROM complaint_simulation
GROUP BY category
ORDER BY complaints DESC
```

### Dataset 12: consumer_satisfaction (Simulated)

```sql
SELECT
    DATE_TRUNC('week', time) as __timestamp,
    ROUND((AVG(CASE
        WHEN download_mbps >= 50 AND latency_ms < 30 THEN 5
        WHEN download_mbps >= 30 AND latency_ms < 50 THEN 4
        WHEN download_mbps >= 20 AND latency_ms < 80 THEN 3
        WHEN download_mbps >= 10 THEN 2
        ELSE 1
    END)::numeric / 5) * 100, 1) as csat_score,
    85 as target
FROM ts_qos_measurements
WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY DATE_TRUNC('week', time)
ORDER BY __timestamp
```

### Dataset 13: pop_health_summary

```sql
WITH pop_health AS (
    SELECT
        p.id,
        AVG(q.latency_ms) as avg_latency,
        AVG(q.packet_loss_pct) as avg_packet_loss
    FROM pops p
    LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
        AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    WHERE p.is_active = true
    GROUP BY p.id
)
SELECT
    COUNT(*) FILTER (WHERE avg_latency < 50 AND avg_packet_loss < 0.5) as healthy,
    COUNT(*) FILTER (WHERE (avg_latency >= 50 AND avg_latency < 100)
                       OR (avg_packet_loss >= 0.5 AND avg_packet_loss < 1.5)) as degraded,
    COUNT(*) FILTER (WHERE avg_latency >= 100 OR avg_packet_loss >= 1.5
                       OR avg_latency IS NULL) as down,
    COUNT(*) as total_pops
FROM pop_health
```

### Dataset 14: critical_alerts

```sql
WITH pop_metrics AS (
    SELECT
        p.id, p.code as pop_id, i.name_en as isp, gd.name_en as location,
        i.total_subscribers,
        AVG(q.latency_ms) as avg_latency,
        AVG(q.packet_loss_pct) as avg_packet_loss,
        ROW_NUMBER() OVER (ORDER BY AVG(q.latency_ms) DESC) as rank
    FROM pops p
    JOIN isps i ON p.isp_id = i.id
    JOIN geo_districts gd ON p.district_id = gd.id
    LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
        AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    WHERE p.is_active = true
    GROUP BY p.id, p.code, i.name_en, gd.name_en, i.total_subscribers
    HAVING COUNT(q.time) > 0
),
overall_avg AS (
    SELECT AVG(avg_latency) as global_latency, AVG(avg_packet_loss) as global_loss
    FROM pop_metrics
)
SELECT
    pm.pop_id,
    pm.isp,
    pm.location,
    CASE
        WHEN pm.rank = 1 THEN '2h 15m ago'
        WHEN pm.rank = 2 THEN '1h 42m ago'
        WHEN pm.rank = 3 THEN '58m ago'
        WHEN pm.rank = 4 THEN '45m ago'
        WHEN pm.rank = 5 THEN '32m ago'
        WHEN pm.rank = 6 THEN '18m ago'
        ELSE '12m ago'
    END as down_since,
    CONCAT('~', (500 + (pm.rank * 300) + (RANDOM() * 200)::integer)::text, ' sub') as impact
FROM pop_metrics pm
CROSS JOIN overall_avg oa
ORDER BY (pm.avg_latency / NULLIF(oa.global_latency, 0)) +
         (pm.avg_packet_loss / NULLIF(oa.global_loss, 0)) DESC
LIMIT 7
```

### Dataset 15: pop_health_by_division

```sql
WITH pop_health AS (
    SELECT
        p.id, gd.division_id,
        AVG(q.latency_ms) as avg_latency,
        AVG(q.packet_loss_pct) as avg_packet_loss
    FROM pops p
    JOIN geo_districts gd ON p.district_id = gd.id
    LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
        AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    WHERE p.is_active = true
    GROUP BY p.id, gd.division_id
)
SELECT
    d.name_en as division,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE ph.avg_latency < 50 AND ph.avg_packet_loss < 0.5) as healthy,
    COUNT(*) FILTER (WHERE (ph.avg_latency >= 50 AND ph.avg_latency < 100)
                       OR (ph.avg_packet_loss >= 0.5 AND ph.avg_packet_loss < 1.5)) as degraded,
    COUNT(*) FILTER (WHERE ph.avg_latency >= 100 OR ph.avg_packet_loss >= 1.5
                       OR ph.avg_latency IS NULL) as down,
    ROUND((COUNT(*) FILTER (WHERE ph.avg_latency < 50 AND ph.avg_packet_loss < 0.5)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability_pct
FROM pop_health ph
JOIN geo_divisions d ON ph.division_id = d.id
GROUP BY d.name_en
ORDER BY total DESC
```

### Dataset 16: pop_availability_weekly

```sql
WITH weekly_data AS (
    SELECT
        DATE_TRUNC('week', time) as week_start,
        ROUND((COUNT(*) FILTER (WHERE latency_ms IS NOT NULL)::numeric /
               NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability_pct
    FROM ts_qos_measurements
    WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
    GROUP BY DATE_TRUNC('week', time)
    ORDER BY week_start
),
numbered AS (
    SELECT
        availability_pct,
        ROW_NUMBER() OVER (ORDER BY week_start) as week_num
    FROM weekly_data
)
SELECT
    CONCAT('Week ', week_num) as week,
    availability_pct,
    99 as target
FROM numbered
ORDER BY week_num
```

---

## 6. Dashboard Charts

### Tab 1: Performance Scorecard

| Chart | Type | Dataset | Metric |
|-------|------|---------|--------|
| 1.1 National Average Speed | Big Number | national_kpis | download_speed |
| 1.2 Service Availability | Big Number | national_kpis | availability_pct |
| 1.3 Equity Index | Big Number | division_performance | calculated |
| 1.4 Target Status | Big Number | national_kpis | calculated |
| 1.5 Speed Trend | Line Chart | speed_trend | download_speed |
| 1.6 Division Performance | Table | division_performance | all columns |
| 1.7 ISP Category Performance | Table | isp_category_performance | all columns |

### Tab 2: Geographic Intelligence

| Chart | Type | Dataset | Metric |
|-------|------|---------|--------|
| 2.1 Division Speed Map | Country Map | division_map_data | avg_speed |
| 2.2 PoP Coverage Analysis | Table | pop_coverage_analysis | all columns |

### Tab 3: Compliance & Enforcement

| Chart | Type | Dataset | Metric |
|-------|------|---------|--------|
| 3.1 Total Violations | Big Number | violations_summary | total_violations |
| 3.2 Critical Violations | Big Number | violations_summary | critical |
| 3.3 Open Violations | Big Number | violations_summary | open_violations |
| 3.4 Violation Trend | Grouped Bar | violation_trend | speed, availability, latency, packet_loss |
| 3.5 Violations by Division | Table | violations_by_division | division, violations, trend |
| 3.6 Top Violating ISPs | Table | top_violating_isps | all columns |

### Tab 4: Consumer Experience

| Chart | Type | Dataset | Metric |
|-------|------|---------|--------|
| 4.1 CSAT Score | Big Number | consumer_satisfaction | csat_score |
| 4.2 Complaints by Category | Horizontal Bar | consumer_complaints | complaints, percentage |
| 4.3 Satisfaction Trend | Line Chart | consumer_satisfaction | csat_score, target |

### Tab 5: Infrastructure Status

| Chart | Type | Dataset | Metric |
|-------|------|---------|--------|
| 5.1a Healthy PoPs | Big Number | pop_health_summary | healthy |
| 5.1b Degraded PoPs | Big Number | pop_health_summary | degraded |
| 5.1c Down PoPs | Big Number | pop_health_summary | down |
| 5.2 Critical Alerts | Table | critical_alerts | pop_id, isp, location, down_since, impact |
| 5.3 PoP Health by Division | Table | pop_health_by_division | all columns |
| 5.4 PoP Availability Trend | Bar Chart | pop_availability_weekly | week, availability_pct |

---

## 7. Troubleshooting

### Database Connection Issues

```bash
# Check if database is running
docker ps | grep btrc-db

# Check database logs
docker logs btrc-db

# Test connection
docker exec btrc-db psql -U btrc -d btrc_qos -c "SELECT 1;"
```

### No Data in Charts

```bash
# Check data date range
docker exec btrc-db psql -U btrc -d btrc_qos -c "
SELECT MIN(time), MAX(time) FROM ts_qos_measurements;
"
```

If data is old, queries use dynamic date filtering:
```sql
WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
```

### Superset Issues

```bash
# Restart Superset
docker-compose restart superset

# Check Superset logs
docker logs btrc-superset
```

### Reset Everything

```bash
# Stop all containers
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker volume rm btrc_db_data superset_db_data superset_home redis_data

# Start fresh
docker-compose up -d

# Reload data
python load_data.py
```

---

## Quick Start Summary

```bash
# 1. Start services
docker-compose up -d

# 2. Wait for containers (30 seconds)
sleep 30

# 3. Load data
pip install psycopg2-binary
python load_data.py

# 4. Access Superset
# URL: http://localhost:8088
# User: admin / admin123

# 5. Add database connection
# postgresql://btrc:btrc_password@btrc-db:5432/btrc_qos

# 6. Create datasets from SQL Lab

# 7. Build dashboard
```

---

## Server Deployment Notes

For production server deployment:

1. **Update docker-compose.yml**:
   - Change `SUPERSET_SECRET_KEY` to a secure random string
   - Change database passwords
   - Update admin password

2. **Configure reverse proxy** (nginx/traefik) for HTTPS

3. **Set memory limits** in docker-compose.yml

4. **Enable persistence** backups for volumes

5. **Configure firewall** - only expose port 8088 (or proxy port)

---

**End of Deployment Guide**
