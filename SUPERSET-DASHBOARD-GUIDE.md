# BTRC QoS Monitoring - Superset Dashboard Creation Guide

## Prerequisites

- Superset running at http://localhost:8088
- Database connected: `postgresql://btrc:btrc_password@localhost:5434/btrc_qos`

---

## Step 1: Add Database Connection

1. Go to **Settings** → **Database Connections**
2. Click **+ Database**
3. Select **PostgreSQL**
4. Enter connection string: `postgresql://btrc:btrc_password@localhost:5434/btrc_qos`
5. Name it: `BTRC QoS Database`
6. Click **Test Connection** → **Connect**

---

## Step 2: Create Datasets

Go to **Data** → **Datasets** → **+ Dataset**

### Required Datasets:

| Dataset Name | Table | Description |
|--------------|-------|-------------|
| ISPs | isps | ISP master data |
| PoPs | pops | Points of Presence |
| QoS Measurements | ts_qos_measurements | Speed/latency metrics |
| Interface Metrics | ts_interface_metrics | SNMP traffic data |
| Subscriber Counts | ts_subscriber_counts | Session counts |
| Violations | sla_violations | SLA violations |
| Divisions | geo_divisions | Geographic divisions |
| Districts | geo_districts | Geographic districts |

---

# EXECUTIVE DASHBOARD

## Tab 1: Performance Scorecard

### Chart 1.1: National Average Speed (Big Number)

**Chart Type:** Big Number with Trendline

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('day', time) as __timestamp,
    ROUND(AVG(download_mbps)::numeric, 1) as download_speed
FROM ts_qos_measurements
WHERE time >= NOW() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', time)
ORDER BY __timestamp
```

**Configuration:**
- Metric: `download_speed`
- Subheader: `Mbps (National Average)`

---

### Chart 1.2: Service Availability % (Big Number)

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('day', time) as __timestamp,
    ROUND(
        (COUNT(*) FILTER (WHERE download_mbps > 0)::numeric /
         NULLIF(COUNT(*)::numeric, 0)) * 100, 2
    ) as availability_pct
FROM ts_qos_measurements
WHERE time >= NOW() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', time)
ORDER BY __timestamp
```

---

### Chart 1.3: Speed Trend (Line Chart)

**Chart Type:** Time-series Line Chart

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('day', time) as __timestamp,
    ROUND(AVG(download_mbps)::numeric, 1) as avg_speed
FROM ts_qos_measurements
WHERE time >= NOW() - INTERVAL '90 days'
GROUP BY DATE_TRUNC('day', time)
ORDER BY __timestamp
```

**Configuration:**
- X-Axis: `__timestamp`
- Metrics: `avg_speed`
- Show Legend: Yes

---

### Chart 1.4: Division Performance (Bar Chart)

**Chart Type:** Horizontal Bar Chart

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= NOW() - INTERVAL '30 days'
GROUP BY d.name_en
ORDER BY avg_speed DESC
```

**Configuration:**
- Dimension: `division`
- Metric: `avg_speed`
- Sort Descending: Yes

---

### Chart 1.5: ISP Category Performance (Table)

**Chart Type:** Table

**SQL Query:**
```sql
SELECT
    lc.name_en as category,
    COUNT(DISTINCT i.id) as isp_count,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND(AVG(q.latency_ms)::numeric, 1) as avg_latency,
    COUNT(*) FILTER (WHERE q.download_mbps < 10) as violations
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN isps i ON p.isp_id = i.id
JOIN isp_license_categories lc ON i.license_category_id = lc.id
WHERE q.time >= NOW() - INTERVAL '30 days'
GROUP BY lc.name_en
ORDER BY avg_speed DESC
```

---

## Tab 2: Geographic Intelligence

### Chart 2.1: Division Heat Map (Choropleth or Table)

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    d.bbs_code,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND(AVG(q.latency_ms)::numeric, 1) as avg_latency,
    COUNT(DISTINCT p.id) as pop_count,
    CASE
        WHEN AVG(q.download_mbps) >= 45 THEN 'Excellent'
        WHEN AVG(q.download_mbps) >= 35 THEN 'Good'
        WHEN AVG(q.download_mbps) >= 25 THEN 'Fair'
        ELSE 'Poor'
    END as performance_tier
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= NOW() - INTERVAL '30 days'
GROUP BY d.name_en, d.bbs_code
ORDER BY avg_speed DESC
```

---

### Chart 2.2: PoP Density by Division (Bar Chart)

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    COUNT(DISTINCT p.id) as pop_count,
    ROUND(COUNT(DISTINCT p.id)::numeric / 10, 2) as pops_per_100k
FROM pops p
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE p.is_active = true
GROUP BY d.name_en
ORDER BY pop_count DESC
```

---

### Chart 2.3: District Performance Table

**SQL Query:**
```sql
SELECT
    gd.name_en as district,
    d.name_en as division,
    COUNT(DISTINCT p.id) as pop_count,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND(AVG(q.upload_mbps)::numeric, 1) as avg_upload,
    ROUND(AVG(q.latency_ms)::numeric, 1) as avg_latency
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= NOW() - INTERVAL '30 days'
GROUP BY gd.name_en, d.name_en
ORDER BY avg_speed DESC
LIMIT 20
```

---

## Tab 3: Compliance & Enforcement

### Chart 3.1: Violation Summary (Big Numbers)

**SQL Query:**
```sql
SELECT
    COUNT(*) as total_violations,
    COUNT(*) FILTER (WHERE severity = 'CRITICAL') as critical,
    COUNT(*) FILTER (WHERE severity = 'HIGH') as high,
    COUNT(*) FILTER (WHERE severity = 'MEDIUM') as medium,
    COUNT(*) FILTER (WHERE severity = 'LOW') as low
FROM sla_violations
WHERE detection_time >= NOW() - INTERVAL '30 days'
```

---

### Chart 3.2: Violations by Category (Pie Chart)

**Chart Type:** Pie Chart

**SQL Query:**
```sql
SELECT
    violation_type,
    COUNT(*) as count
FROM sla_violations
WHERE detection_time >= NOW() - INTERVAL '30 days'
GROUP BY violation_type
ORDER BY count DESC
```

---

### Chart 3.3: Top Violators (Table)

**SQL Query:**
```sql
SELECT
    i.name_en as isp_name,
    i.trade_name,
    lc.name_en as category,
    COUNT(*) as violation_count,
    COUNT(*) FILTER (WHERE v.severity = 'CRITICAL') as critical_count,
    ROUND(AVG(v.deviation_pct)::numeric, 1) as avg_deviation
FROM sla_violations v
JOIN isps i ON v.isp_id = i.id
JOIN isp_license_categories lc ON i.license_category_id = lc.id
WHERE v.detection_time >= NOW() - INTERVAL '30 days'
GROUP BY i.name_en, i.trade_name, lc.name_en
ORDER BY violation_count DESC
LIMIT 10
```

---

### Chart 3.4: Violation Trend (Line Chart)

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('day', detection_time) as __timestamp,
    COUNT(*) as violations,
    COUNT(*) FILTER (WHERE severity = 'CRITICAL') as critical
FROM sla_violations
WHERE detection_time >= NOW() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', detection_time)
ORDER BY __timestamp
```

---

### Chart 3.5: Violations by Division (Bar Chart)

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    COUNT(*) as violation_count,
    COUNT(*) FILTER (WHERE v.severity = 'CRITICAL') as critical
FROM sla_violations v
JOIN pops p ON v.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE v.detection_time >= NOW() - INTERVAL '30 days'
GROUP BY d.name_en
ORDER BY violation_count DESC
```

---

## Tab 4: Consumer Experience

### Chart 4.1: Speed Distribution (Histogram)

**SQL Query:**
```sql
SELECT
    CASE
        WHEN download_mbps < 10 THEN '0-10 Mbps'
        WHEN download_mbps < 25 THEN '10-25 Mbps'
        WHEN download_mbps < 50 THEN '25-50 Mbps'
        WHEN download_mbps < 100 THEN '50-100 Mbps'
        ELSE '100+ Mbps'
    END as speed_range,
    COUNT(*) as measurement_count
FROM ts_qos_measurements
WHERE time >= NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 1
```

---

### Chart 4.2: Latency Distribution (Histogram)

**SQL Query:**
```sql
SELECT
    CASE
        WHEN latency_ms < 20 THEN 'Excellent (<20ms)'
        WHEN latency_ms < 50 THEN 'Good (20-50ms)'
        WHEN latency_ms < 100 THEN 'Fair (50-100ms)'
        ELSE 'Poor (>100ms)'
    END as latency_category,
    COUNT(*) as count
FROM ts_qos_measurements
WHERE time >= NOW() - INTERVAL '7 days'
  AND latency_ms IS NOT NULL
GROUP BY 1
ORDER BY 1
```

---

## Tab 5: Infrastructure Status

### Chart 5.1: PoP Status Summary (Big Numbers)

**SQL Query:**
```sql
SELECT
    COUNT(*) as total_pops,
    COUNT(*) FILTER (WHERE status = 'OPERATIONAL') as operational,
    COUNT(*) FILTER (WHERE status = 'DEGRADED') as degraded,
    COUNT(*) FILTER (WHERE status = 'DOWN') as down
FROM pops
WHERE is_active = true
```

---

### Chart 5.2: PoP Health by Division (Table)

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    COUNT(*) as total_pops,
    COUNT(*) FILTER (WHERE p.status = 'OPERATIONAL') as operational,
    COUNT(*) FILTER (WHERE p.status = 'DEGRADED') as degraded,
    COUNT(*) FILTER (WHERE p.status = 'DOWN') as down,
    ROUND(
        COUNT(*) FILTER (WHERE p.status = 'OPERATIONAL')::numeric /
        NULLIF(COUNT(*)::numeric, 0) * 100, 1
    ) as availability_pct
FROM pops p
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE p.is_active = true
GROUP BY d.name_en
ORDER BY total_pops DESC
```

---

### Chart 5.3: Interface Utilization (Line Chart)

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('hour', time) as __timestamp,
    ROUND(AVG(utilization_in_pct)::numeric, 1) as avg_in_util,
    ROUND(AVG(utilization_out_pct)::numeric, 1) as avg_out_util
FROM ts_interface_metrics
WHERE time >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', time)
ORDER BY __timestamp
```

---

# REGULATORY DASHBOARD

## Tab 1: SLA Monitoring

### Chart R1.1: SLA Compliance Overview (Big Numbers)

**SQL Query:**
```sql
WITH isp_compliance AS (
    SELECT
        i.id,
        i.name_en,
        AVG(q.download_mbps) as avg_speed,
        COUNT(*) FILTER (WHERE q.download_mbps < 10) as violations
    FROM isps i
    JOIN pops p ON p.isp_id = i.id
    LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
        AND q.time >= NOW() - INTERVAL '24 hours'
    GROUP BY i.id, i.name_en
)
SELECT
    COUNT(*) FILTER (WHERE violations = 0) as compliant,
    COUNT(*) FILTER (WHERE violations BETWEEN 1 AND 5) as at_risk,
    COUNT(*) FILTER (WHERE violations > 5) as violation
FROM isp_compliance
```

---

### Chart R1.2: Package Compliance Matrix (Table)

**SQL Query:**
```sql
SELECT
    pt.name_en as package_type,
    ROUND(AVG(pk.download_speed_mbps)::numeric, 1) as target_speed,
    ROUND(AVG(q.download_mbps)::numeric, 1) as actual_speed,
    ROUND(
        (AVG(q.download_mbps) - AVG(pk.download_speed_mbps)) /
        NULLIF(AVG(pk.download_speed_mbps), 0) * 100, 1
    ) as gap_pct
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN packages pk ON pk.isp_id = p.isp_id
JOIN package_types pt ON pk.package_type_id = pt.id
WHERE q.time >= NOW() - INTERVAL '24 hours'
GROUP BY pt.name_en
ORDER BY actual_speed DESC
```

---

### Chart R1.3: Real-time Threshold Alerts (Table)

**SQL Query:**
```sql
SELECT
    v.id as incident_id,
    i.name_en as isp,
    gd.name_en as location,
    v.violation_type as metric,
    v.severity,
    v.actual_value,
    v.expected_value,
    v.detection_time,
    v.status
FROM sla_violations v
JOIN isps i ON v.isp_id = i.id
LEFT JOIN pops p ON v.pop_id = p.id
LEFT JOIN geo_districts gd ON p.district_id = gd.id
WHERE v.detection_time >= NOW() - INTERVAL '24 hours'
ORDER BY v.detection_time DESC
LIMIT 20
```

---

## Tab 2: Regional Analysis

### Chart R2.1: Division Performance Ranking (Table)

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND(AVG(q.latency_ms)::numeric, 1) as avg_latency,
    COUNT(DISTINCT p.id) as pop_count,
    COUNT(*) FILTER (WHERE q.download_mbps < 10) as violations,
    ROUND(
        (AVG(q.download_mbps) * 0.5 +
         (100 - LEAST(AVG(q.latency_ms), 100)) * 0.3 +
         LEAST(COUNT(DISTINCT p.id), 100) * 0.2)::numeric, 1
    ) as score
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= NOW() - INTERVAL '24 hours'
GROUP BY d.name_en
ORDER BY score DESC
```

---

### Chart R2.2: ISP Performance by Area (Table)

**SQL Query:**
```sql
SELECT
    i.name_en as isp,
    d.name_en as division,
    COUNT(DISTINCT p.id) as pop_count,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    COUNT(*) FILTER (WHERE q.download_mbps < 10) as violations
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN isps i ON p.isp_id = i.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= NOW() - INTERVAL '24 hours'
GROUP BY i.name_en, d.name_en
ORDER BY d.name_en, avg_speed DESC
```

---

## Tab 3: Violation Reporting

### Chart R3.1: Violation Summary Cards

**SQL Query:**
```sql
SELECT
    COUNT(*) FILTER (WHERE status = 'OPEN') as pending,
    COUNT(*) FILTER (WHERE status = 'INVESTIGATING') as under_review,
    COUNT(*) FILTER (WHERE status = 'RESOLVED') as completed
FROM sla_violations
WHERE detection_time >= NOW() - INTERVAL '30 days'
```

---

### Chart R3.2: Violation Details Table

**SQL Query:**
```sql
SELECT
    v.id as violation_id,
    i.name_en as isp,
    i.trade_name,
    v.violation_type,
    v.severity,
    ROUND(v.actual_value::numeric, 2) as actual,
    ROUND(v.expected_value::numeric, 2) as expected,
    ROUND(v.deviation_pct::numeric, 1) as deviation_pct,
    v.detection_time,
    v.status
FROM sla_violations v
JOIN isps i ON v.isp_id = i.id
ORDER BY v.detection_time DESC
LIMIT 50
```

---

## Tab 4: Investigation Center

### Chart R4.1: ISP Timeline Analysis (Line Chart)

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('hour', q.time) as __timestamp,
    i.name_en as isp,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND(AVG(q.latency_ms)::numeric, 1) as avg_latency
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN isps i ON p.isp_id = i.id
WHERE q.time >= NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', q.time), i.name_en
ORDER BY __timestamp
```

---

### Chart R4.2: PoP Infrastructure Impact (Table)

**SQL Query:**
```sql
SELECT
    p.code as pop_code,
    p.name_en as pop_name,
    i.name_en as isp,
    gd.name_en as district,
    p.status,
    ROUND(AVG(m.utilization_in_pct)::numeric, 1) as avg_utilization,
    COUNT(v.id) as violations
FROM pops p
JOIN isps i ON p.isp_id = i.id
JOIN geo_districts gd ON p.district_id = gd.id
LEFT JOIN ts_interface_metrics m ON m.pop_id = p.id
    AND m.time >= NOW() - INTERVAL '24 hours'
LEFT JOIN sla_violations v ON v.pop_id = p.id
    AND v.detection_time >= NOW() - INTERVAL '24 hours'
GROUP BY p.code, p.name_en, i.name_en, gd.name_en, p.status
ORDER BY avg_utilization DESC NULLS LAST
LIMIT 20
```

---

## Tab 5: License Compliance

### Chart R5.1: License Compliance Overview

**SQL Query:**
```sql
SELECT
    lc.name_en as category,
    COUNT(DISTINCT i.id) as isp_count,
    COUNT(DISTINCT p.id) as total_pops,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed
FROM isps i
JOIN isp_license_categories lc ON i.license_category_id = lc.id
LEFT JOIN pops p ON p.isp_id = i.id
LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
    AND q.time >= NOW() - INTERVAL '24 hours'
GROUP BY lc.name_en
ORDER BY isp_count DESC
```

---

### Chart R5.2: PoP Deployment by Division

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    COUNT(DISTINCT p.id) as actual_pops,
    50 as target_pops,  -- placeholder target
    COUNT(DISTINCT p.id) - 50 as gap
FROM pops p
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE p.is_active = true
GROUP BY d.name_en
ORDER BY actual_pops DESC
```

---

### Chart R5.3: Capacity Utilization (Table)

**SQL Query:**
```sql
SELECT
    p.code as pop_code,
    i.name_en as isp,
    gd.name_en as district,
    ROUND(AVG(m.utilization_in_pct)::numeric, 1) as in_utilization,
    ROUND(AVG(m.utilization_out_pct)::numeric, 1) as out_utilization,
    CASE
        WHEN AVG(m.utilization_in_pct) > 90 THEN 'Critical'
        WHEN AVG(m.utilization_in_pct) > 75 THEN 'Warning'
        ELSE 'Normal'
    END as status
FROM ts_interface_metrics m
JOIN pops p ON m.pop_id = p.id
JOIN isps i ON p.isp_id = i.id
JOIN geo_districts gd ON p.district_id = gd.id
WHERE m.time >= NOW() - INTERVAL '24 hours'
GROUP BY p.code, i.name_en, gd.name_en
ORDER BY in_utilization DESC
LIMIT 20
```

---

## Creating Dashboards

### Step 1: Create Charts
1. Go to **Charts** → **+ Chart**
2. Select dataset (create SQL Lab query for complex ones)
3. Choose chart type
4. Configure metrics and dimensions
5. Save chart with descriptive name

### Step 2: Create Dashboard
1. Go to **Dashboards** → **+ Dashboard**
2. Name: "BTRC Executive Dashboard" or "BTRC Regulatory Dashboard"
3. Drag charts from the panel
4. Arrange in grid layout
5. Add tabs using the **Tabs** component
6. Configure filters

### Step 3: Add Filters
1. Click **Filter** icon in dashboard edit mode
2. Add filters for:
   - Time Range (Last 24h, 7d, 30d)
   - Division
   - ISP Category
   - ISP Name

### Step 4: Set Auto-Refresh
1. In dashboard view, click **⚙️ Settings**
2. Set auto-refresh: 5 minutes

---

## Color Scheme

Use these colors for consistency:

| Status | Color |
|--------|-------|
| Good/Healthy | #52c41a (Green) |
| Warning/At Risk | #faad14 (Yellow) |
| Critical/Violation | #ff4d4f (Red) |
| Info | #1890ff (Blue) |
| BTRC Brand | #00a651 |

---

## Tips

1. **Use SQL Lab** for complex queries
2. **Create Virtual Datasets** from SQL queries
3. **Set meaningful chart titles**
4. **Add annotations** for threshold lines
5. **Configure drill-down** between charts
6. **Export dashboards** for backup

---

## Quick Reference: Chart Types

| Data Type | Recommended Chart |
|-----------|------------------|
| Single KPI | Big Number |
| Trend over time | Line Chart |
| Comparison | Bar Chart |
| Distribution | Pie/Donut |
| Rankings | Table |
| Geographic | Map (if available) |
| Status | Big Number Cards |
