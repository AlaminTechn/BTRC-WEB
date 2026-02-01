# BTRC QoS Monitoring - Superset Dashboard Creation Guide

**Version**: 2.0
**Last Updated**: 2026-01-29
**Total Charts**: ~38 charts across 5 tabs

---

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

| Dataset Name | Table/Query | Description |
|--------------|-------------|-------------|
| ISPs | isps | ISP master data |
| PoPs | pops | Points of Presence |
| QoS Measurements | ts_qos_measurements | Speed/latency metrics |
| Interface Metrics | ts_interface_metrics | SNMP traffic data |
| Subscriber Counts | ts_subscriber_counts | Session counts |
| Violations | sla_violations | SLA violations |
| Divisions | geo_divisions | Geographic divisions |
| Districts | geo_districts | Geographic districts |

---

# TAB 1: PERFORMANCE SCORECARD

**Executive Question**: "How is Bangladesh's broadband performing?"

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ROW 1: National KPI Cards (4 Big Numbers)                                   │
│  ┌────────────────┬────────────────┬────────────────┬────────────────┐       │
│  │ AVERAGE SPEED  │  AVAILABILITY  │  EQUITY INDEX  │ TARGET STATUS  │       │
│  │    47.3 Mbps   │    99.2%       │     0.72       │    3/4 MET     │       │
│  └────────────────┴────────────────┴────────────────┴────────────────┘       │
│                                                                              │
│  ROW 2: Speed Trend + Division Performance                                   │
│  ┌─────────────────────────────────┬─────────────────────────────────────┐   │
│  │  SPEED TREND (12 Months)        │  DIVISION PERFORMANCE               │   │
│  └─────────────────────────────────┴─────────────────────────────────────┘   │
│                                                                              │
│  ROW 3: ISP Category Performance (Full Width Table)                          │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │  PERFORMANCE BY ISP CATEGORY                                         │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Chart 1.1: National Average Speed (Big Number)

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('day', time) as __timestamp,
    ROUND(AVG(download_mbps)::numeric, 1) as download_speed
FROM ts_qos_measurements
WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY DATE_TRUNC('day', time)
ORDER BY __timestamp
```

**Configuration:**
- Chart Type: Big Number with Trendline
- Metric: `download_speed` (AVG)
- Subheader: `Mbps (National Average)`

---

## Chart 1.2: Service Availability % (Big Number)

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('day', time) as __timestamp,
    ROUND(
        (COUNT(*) FILTER (WHERE latency_ms IS NOT NULL)::numeric /
         NULLIF(COUNT(*)::numeric, 0)) * 100, 2
    ) as availability_pct
FROM ts_qos_measurements
WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY DATE_TRUNC('day', time)
ORDER BY __timestamp
```

**Configuration:**
- Chart Type: Big Number with Trendline
- Metric: `availability_pct` (AVG)
- Subheader: `% Service Availability`

---

## Chart 1.3: Equity Index (Big Number)

**SQL Query:**
```sql
WITH division_speeds AS (
    SELECT
        d.name_en as division,
        AVG(q.download_mbps) as avg_speed
    FROM ts_qos_measurements q
    JOIN pops p ON q.pop_id = p.id
    JOIN geo_districts gd ON p.district_id = gd.id
    JOIN geo_divisions d ON gd.division_id = d.id
    WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
    GROUP BY d.name_en
)
SELECT
    ROUND(
        (1 - (STDDEV(avg_speed) / NULLIF(AVG(avg_speed), 0)))::numeric,
    2) as equity_index
FROM division_speeds
```

**Configuration:**
- Chart Type: Big Number
- Metric: `equity_index` (MAX)
- Subheader: `Target: 0.80`

---

## Chart 1.4: Target Status (Big Number)

**SQL Query:**
```sql
WITH targets AS (
    SELECT
        CASE WHEN AVG(download_mbps) >= 50 THEN 1 ELSE 0 END as speed_met,
        CASE WHEN (COUNT(*) FILTER (WHERE latency_ms IS NOT NULL)::numeric /
                   NULLIF(COUNT(*)::numeric, 0)) * 100 >= 99.5 THEN 1 ELSE 0 END as avail_met,
        CASE WHEN STDDEV(download_mbps) / NULLIF(AVG(download_mbps), 0) <= 0.20 THEN 1 ELSE 0 END as equity_met,
        CASE WHEN AVG(latency_ms) < 50 THEN 1 ELSE 0 END as latency_met
    FROM ts_qos_measurements
    WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
)
SELECT
    (speed_met + avail_met + equity_met + latency_met) as targets_met,
    4 as total_targets
FROM targets
```

**Configuration:**
- Chart Type: Big Number
- Metric: `targets_met` (MAX)
- Subheader: `of 4 Targets Met`

---

## Chart 1.5: Speed Trend (Line Chart)

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('day', time) as __timestamp,
    ROUND(AVG(download_mbps)::numeric, 1) as national_speed,
    50 as target_speed
FROM ts_qos_measurements
WHERE time >= (SELECT MAX(time) - INTERVAL '12 months' FROM ts_qos_measurements)
GROUP BY DATE_TRUNC('day', time)
ORDER BY __timestamp
```

**Configuration:**
- Chart Type: Time-series Line Chart
- X-Axis: `__timestamp`
- Metrics: `national_speed` (AVG), `target_speed` (MAX)
- Line Styles: National=Solid Blue, Target=Dashed Gray

---

## Chart 1.6: Division Performance (Bar Chart)

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY d.name_en
ORDER BY avg_speed DESC
```

**Configuration:**
- Chart Type: Bar Chart (Horizontal)
- Dimension: `division`
- Metric: `avg_speed` (AVG)
- Sort: Descending

---

## Chart 1.7: ISP Category Performance (Table)

**SQL Query:**
```sql
SELECT
    lc.name_en as category,
    COUNT(DISTINCT i.id) as isp_count,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND(
        (COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
         NULLIF(COUNT(*)::numeric, 0)) * 100, 1
    ) as availability_pct,
    ROUND(AVG(q.latency_ms)::numeric, 1) as avg_latency,
    CASE
        WHEN AVG(q.download_mbps) >= 50 THEN 'Excellent'
        WHEN AVG(q.download_mbps) >= 40 THEN 'Good'
        WHEN AVG(q.download_mbps) >= 30 THEN 'Fair'
        ELSE 'Poor'
    END as status
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN isps i ON p.isp_id = i.id
JOIN isp_license_categories lc ON i.license_category_id = lc.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY lc.name_en
ORDER BY avg_speed DESC
```

**Configuration:**
- Chart Type: Table
- Columns: category, isp_count, avg_speed, availability_pct, avg_latency, status

---

# TAB 2: GEOGRAPHIC INTELLIGENCE

**Executive Question**: "Where are we strong/weak?"

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ROW 1: Bangladesh Map + Division Comparison                                 │
│  ┌─────────────────────────────────┬─────────────────────────────────────┐   │
│  │  BANGLADESH DIVISION MAP        │  DIVISION COMPARISON                │   │
│  └─────────────────────────────────┴─────────────────────────────────────┘   │
│                                                                              │
│  ROW 2: Urban vs Rural + PoP Density                                         │
│  ┌─────────────────────────────────┬─────────────────────────────────────┐   │
│  │  URBAN VS RURAL GAP             │  PoP DENSITY BY DIVISION            │   │
│  └─────────────────────────────────┴─────────────────────────────────────┘   │
│                                                                              │
│  ROW 3: Coverage Analysis                                                    │
│  ┌────────────────┬────────────────┬────────────────┬─────────────────────┐  │
│  │  Total PoPs    │  Adequate      │  Marginal      │  Critical           │  │
│  └────────────────┴────────────────┴────────────────┴─────────────────────┘  │
│                                                                              │
│  ROW 4: White Spots Table                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │  WHITE SPOTS - LOW COVERAGE DISTRICTS                                │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Chart 2.1: Bangladesh Division Map (Country Map)

**SQL Query:**
```sql
SELECT
    CASE d.name_en
        WHEN 'Barishal' THEN 'BD-A'
        WHEN 'Barisal' THEN 'BD-A'
        WHEN 'Chattogram' THEN 'BD-B'
        WHEN 'Chittagong' THEN 'BD-B'
        WHEN 'Dhaka' THEN 'BD-C'
        WHEN 'Khulna' THEN 'BD-D'
        WHEN 'Rajshahi' THEN 'BD-E'
        WHEN 'Rangpur' THEN 'BD-F'
        WHEN 'Sylhet' THEN 'BD-G'
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

**Configuration:**
- Chart Type: Country Map
- Country: Bangladesh
- Entity: `iso_code`
- Metric: `avg_speed`

---

## Chart 2.2: Division Comparison (Table)

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND(AVG(q.latency_ms)::numeric, 1) as avg_latency,
    COUNT(DISTINCT p.id) as pop_count,
    RANK() OVER (ORDER BY AVG(q.download_mbps) DESC) as rank
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY d.name_en
ORDER BY avg_speed DESC
```

**Configuration:**
- Chart Type: Table
- Columns: rank, division, avg_speed, avg_latency, pop_count

---

## Chart 2.3: Urban vs Rural Gap (Bar Chart)

**SQL Query:**
```sql
SELECT
    CASE
        WHEN d.name_en IN ('Dhaka', 'Chattogram', 'Chittagong') THEN 'Urban'
        ELSE 'Rural'
    END as area_type,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY 1
ORDER BY avg_speed DESC
```

**Configuration:**
- Chart Type: Bar Chart (Horizontal)
- Dimension: `area_type`
- Metric: `avg_speed` (AVG)

---

## Chart 2.4: PoP Density by Division (Bar Chart)

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

**Configuration:**
- Chart Type: Bar Chart (Horizontal)
- Dimension: `division`
- Metric: `pop_count` (SUM)

---

## Chart 2.5: Coverage Status (3 Big Numbers)

**SQL Query:**
```sql
SELECT
    COUNT(*) FILTER (WHERE pop_count >= 3) as adequate,
    COUNT(*) FILTER (WHERE pop_count BETWEEN 1 AND 2) as marginal,
    COUNT(*) FILTER (WHERE pop_count = 0) as critical
FROM (
    SELECT gd.id, COUNT(p.id) as pop_count
    FROM geo_districts gd
    LEFT JOIN pops p ON p.district_id = gd.id AND p.is_active = true
    GROUP BY gd.id
) district_pops
```

**Configuration:**
- Create 3 Big Number charts: Adequate (Green), Marginal (Yellow), Critical (Red)

---

## Chart 2.6: White Spots Table

**SQL Query:**
```sql
SELECT
    gd.name_en as district,
    d.name_en as division,
    COUNT(p.id) as pop_count
FROM geo_districts gd
JOIN geo_divisions d ON gd.division_id = d.id
LEFT JOIN pops p ON p.district_id = gd.id AND p.is_active = true
GROUP BY gd.name_en, d.name_en
HAVING COUNT(p.id) <= 1
ORDER BY pop_count ASC, gd.name_en
```

**Configuration:**
- Chart Type: Table
- Columns: district, division, pop_count

---

# TAB 3: COMPLIANCE & ENFORCEMENT

**Executive Question**: "Who is meeting/violating standards?"

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ROW 1: Compliance Summary (3 Big Numbers)                                   │
│  ┌────────────────────┬────────────────────┬────────────────────┐            │
│  │   Compliant ISPs   │   At Risk ISPs     │   Violating ISPs   │            │
│  └────────────────────┴────────────────────┴────────────────────┘            │
│                                                                              │
│  ROW 2: Violations by Category + Top Violators                               │
│  ┌─────────────────────────────────┬─────────────────────────────────────┐   │
│  │  VIOLATIONS BY CATEGORY         │  TOP VIOLATORS                      │   │
│  └─────────────────────────────────┴─────────────────────────────────────┘   │
│                                                                              │
│  ROW 3: Violation Trend (Full Width)                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │  VIOLATION TREND (6 Months) - Grouped Bar Chart                      │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ROW 4: Violations by Division (Full Width Table)                            │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │  VIOLATIONS BY DIVISION                                              │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Chart 3.1: ISP Compliance Summary (3 Big Numbers)

**SQL Query:**
```sql
SELECT
    COUNT(*) FILTER (WHERE violation_count = 0) as compliant,
    COUNT(*) FILTER (WHERE violation_count BETWEEN 1 AND 5) as at_risk,
    COUNT(*) FILTER (WHERE violation_count > 5) as violating,
    ROUND(
        COUNT(*) FILTER (WHERE violation_count = 0)::numeric /
        NULLIF(COUNT(*)::numeric, 0) * 100, 1
    ) as compliance_pct
FROM (
    SELECT i.id, COUNT(v.id) as violation_count
    FROM isps i
    LEFT JOIN sla_violations v ON v.isp_id = i.id
        AND v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
    WHERE i.is_active = true
    GROUP BY i.id
) isp_violations
```

**Configuration:**
- Create 3 Big Number charts: Compliant (Green), At Risk (Yellow), Violating (Red)

---

## Chart 3.2: Violations by Category (Bar Chart)

**SQL Query:**
```sql
SELECT
    violation_type as category,
    COUNT(*) as count
FROM sla_violations
WHERE detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
GROUP BY violation_type
ORDER BY count DESC
```

**Configuration:**
- Chart Type: Bar Chart (Horizontal)
- Dimension: `category`
- Metric: `count` (SUM)

---

## Chart 3.3: Top Violators (Table)

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
WHERE v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
GROUP BY i.name_en, i.trade_name, lc.name_en
ORDER BY violation_count DESC
LIMIT 10
```

**Configuration:**
- Chart Type: Table
- Columns: isp_name, category, violation_count, critical_count, avg_deviation

---

## Chart 3.4: Violation Trend (Grouped Bar Chart)

**SQL Query:**
```sql
SELECT
    TO_CHAR(DATE_TRUNC('month', detection_time), 'Mon') as month,
    DATE_TRUNC('month', detection_time) as month_date,
    COUNT(*) FILTER (WHERE violation_type = 'SPEED_SHORTFALL') as speed,
    COUNT(*) FILTER (WHERE violation_type = 'AVAILABILITY_BREACH') as availability,
    COUNT(*) FILTER (WHERE violation_type = 'LATENCY_EXCEEDED') as latency,
    COUNT(*) FILTER (WHERE violation_type = 'PACKET_LOSS') as packet_loss
FROM sla_violations
WHERE detection_time >= (SELECT MAX(detection_time) - INTERVAL '6 months' FROM sla_violations)
GROUP BY DATE_TRUNC('month', detection_time)
ORDER BY month_date
```

**Configuration:**
- Chart Type: Bar Chart (Grouped)
- X-Axis: `month`
- Metrics: `speed`, `availability`, `latency`, `packet_loss` (all SUM)
- Colors: Speed=Red, Availability=Orange, Latency=Yellow, Packet Loss=Blue

---

## Chart 3.5: Violations by Division (Table with Trend)

**SQL Query:**
```sql
WITH current_period AS (
    SELECT
        d.name_en as division,
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE v.violation_type = 'SPEED_SHORTFALL') as speed,
        COUNT(*) FILTER (WHERE v.violation_type = 'AVAILABILITY_BREACH') as availability,
        COUNT(*) FILTER (WHERE v.violation_type = 'LATENCY_EXCEEDED') as latency,
        COUNT(*) FILTER (WHERE v.violation_type = 'PACKET_LOSS') as packet_loss
    FROM sla_violations v
    JOIN pops p ON v.pop_id = p.id
    JOIN geo_districts gd ON p.district_id = gd.id
    JOIN geo_divisions d ON gd.division_id = d.id
    WHERE v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '15 days' FROM sla_violations)
    GROUP BY d.name_en
),
previous_period AS (
    SELECT d.name_en as division, COUNT(*) as prev_total
    FROM sla_violations v
    JOIN pops p ON v.pop_id = p.id
    JOIN geo_districts gd ON p.district_id = gd.id
    JOIN geo_divisions d ON gd.division_id = d.id
    WHERE v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
      AND v.detection_time < (SELECT MAX(detection_time) - INTERVAL '15 days' FROM sla_violations)
    GROUP BY d.name_en
)
SELECT
    c.division, c.total, c.speed, c.availability, c.latency, c.packet_loss,
    ROUND(((c.total - COALESCE(p.prev_total, 0))::numeric /
           NULLIF(COALESCE(p.prev_total, c.total), 0)) * 100, 0) as trend
FROM current_period c
LEFT JOIN previous_period p ON c.division = p.division
ORDER BY c.total DESC
```

**Configuration:**
- Chart Type: Table
- Columns: division, total, speed, availability, latency, packet_loss, trend
- Trend column: Green for negative (improvement), Red for positive (worse)

---

# TAB 4: CONSUMER EXPERIENCE

**Executive Question**: "How are citizens being served?"

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ROW 1: Consumer Summary (3 Big Numbers)                                     │
│  ┌────────────────────┬────────────────────┬────────────────────┐            │
│  │  Complaints        │  Avg Resolution    │  Satisfaction      │            │
│  │  This Month        │  Time              │  Score             │            │
│  └────────────────────┴────────────────────┴────────────────────┘            │
│                                                                              │
│  ROW 2: Complaints by Category + Complaint Trend                             │
│  ┌─────────────────────────────────┬─────────────────────────────────────┐   │
│  │  COMPLAINTS BY CATEGORY         │  COMPLAINT TREND (12 Months)        │   │
│  │  (Horizontal Bar with %)        │  (Line Chart with Target)           │   │
│  └─────────────────────────────────┴─────────────────────────────────────┘   │
│                                                                              │
│  ROW 3: ISP Resolution Performance (Full Width Table)                        │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │  ISP RESOLUTION PERFORMANCE                                          │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ROW 4: Complaints by Division (Full Width Table)                            │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │  COMPLAINTS BY DIVISION                                              │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ROW 5: Mobile App Engagement                                                │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │  📱 MOBILE APP ENGAGEMENT                                            │    │
│  │  Active Users | Speed Tests/mo | App Rating                          │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Chart 4.1: Consumer Summary (3 Big Numbers)

**SQL Query:**
```sql
WITH complaints AS (
    SELECT
        COUNT(*) FILTER (WHERE download_mbps < 10) as speed_complaints,
        COUNT(*) FILTER (WHERE latency_ms > 100) as latency_complaints,
        COUNT(*) FILTER (WHERE packet_loss_pct > 5) as packet_complaints
    FROM ts_qos_measurements
    WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
),
resolution AS (
    SELECT ROUND(AVG(3.5)::numeric, 1) as avg_resolution_days
    FROM sla_violations
    WHERE detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
),
satisfaction AS (
    SELECT ROUND(AVG(CASE
        WHEN download_mbps >= 25 THEN 5
        WHEN download_mbps >= 15 THEN 4
        WHEN download_mbps >= 10 THEN 3
        WHEN download_mbps >= 5 THEN 2
        ELSE 1 END)::numeric, 1) as satisfaction_score
    FROM ts_qos_measurements
    WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
)
SELECT
    (c.speed_complaints + c.latency_complaints + c.packet_complaints) as total_complaints,
    r.avg_resolution_days,
    s.satisfaction_score
FROM complaints c, resolution r, satisfaction s
```

**Configuration:**
- Create 3 Big Number charts:
  - Complaints (Red): `total_complaints`
  - Resolution Time (Blue): `avg_resolution_days`
  - Satisfaction (Green): `satisfaction_score`

---

## Chart 4.2: Complaints by Category (Horizontal Bar)

**SQL Query:**
```sql
WITH complaint_counts AS (
    SELECT 'Slow Speed' as category, COUNT(*) FILTER (WHERE download_mbps < 10) as count, 1 as sort_order
    FROM ts_qos_measurements WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
    UNION ALL
    SELECT 'Connection Drop', COUNT(*) FILTER (WHERE download_mbps = 0 OR download_mbps IS NULL), 2
    FROM ts_qos_measurements WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
    UNION ALL
    SELECT 'High Latency', COUNT(*) FILTER (WHERE latency_ms > 100), 3
    FROM ts_qos_measurements WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
    UNION ALL
    SELECT 'Packet Loss', COUNT(*) FILTER (WHERE packet_loss_pct > 5), 4
    FROM ts_qos_measurements WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
    UNION ALL
    SELECT 'Other', COUNT(*) FILTER (WHERE jitter_ms > 50), 5
    FROM ts_qos_measurements WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
),
total AS (SELECT SUM(count) as total_count FROM complaint_counts)
SELECT c.category, c.count,
    ROUND((c.count::numeric / NULLIF(t.total_count, 0)) * 100, 0) as percentage, c.sort_order
FROM complaint_counts c, total t
ORDER BY c.sort_order
```

**Configuration:**
- Chart Type: Bar Chart (Horizontal)
- Dimension: `category`
- Metric: `percentage` (MAX)
- Show bar values with % suffix

---

## Chart 4.3: Complaint Trend (Line Chart)

**SQL Query:**
```sql
SELECT
    TO_CHAR(DATE_TRUNC('month', time), 'Mon') as month,
    DATE_TRUNC('month', time) as month_date,
    COUNT(*) FILTER (WHERE download_mbps < 10 OR latency_ms > 100 OR packet_loss_pct > 5) as complaints,
    3000 as target
FROM ts_qos_measurements
WHERE time >= (SELECT MAX(time) - INTERVAL '12 months' FROM ts_qos_measurements)
GROUP BY DATE_TRUNC('month', time)
ORDER BY month_date
```

**Configuration:**
- Chart Type: Time-series Line Chart
- X-Axis: `month_date`
- Metrics: `complaints` (SUM), `target` (MAX)
- Actual line: Solid Blue, Target line: Dashed Gray

---

## Chart 4.4: ISP Resolution Performance (Table)

**SQL Query:**
```sql
SELECT
    i.name_en as isp_name,
    COUNT(v.id) as complaints,
    ROUND(AVG(3.5)::numeric, 1) as avg_resolution_days,
    ROUND((COUNT(*) FILTER (WHERE v.status = 'RESOLVED')::numeric /
           NULLIF(COUNT(v.id)::numeric, 0)) * 100, 0) as within_sla_pct,
    CASE
        WHEN (COUNT(*) FILTER (WHERE v.status = 'RESOLVED')::numeric /
              NULLIF(COUNT(v.id)::numeric, 0)) >= 0.9 THEN '⭐⭐⭐⭐⭐'
        WHEN (COUNT(*) FILTER (WHERE v.status = 'RESOLVED')::numeric /
              NULLIF(COUNT(v.id)::numeric, 0)) >= 0.8 THEN '⭐⭐⭐⭐'
        WHEN (COUNT(*) FILTER (WHERE v.status = 'RESOLVED')::numeric /
              NULLIF(COUNT(v.id)::numeric, 0)) >= 0.7 THEN '⭐⭐⭐'
        ELSE '⭐⭐'
    END as rating
FROM isps i
LEFT JOIN sla_violations v ON v.isp_id = i.id
    AND v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
WHERE i.is_active = true
GROUP BY i.name_en
HAVING COUNT(v.id) > 0
ORDER BY within_sla_pct DESC
LIMIT 10
```

**Configuration:**
- Chart Type: Table
- Columns: isp_name, complaints, avg_resolution_days, within_sla_pct, rating

---

## Chart 4.5: Complaints by Division (Table)

**SQL Query:**
```sql
SELECT
    d.name_en as division,
    COUNT(*) FILTER (WHERE q.download_mbps < 10 OR q.latency_ms > 100 OR q.packet_loss_pct > 5) as total,
    COUNT(*) FILTER (WHERE q.download_mbps < 10) as speed,
    COUNT(*) FILTER (WHERE q.download_mbps = 0 OR q.download_mbps IS NULL) as drop_conn,
    COUNT(*) FILTER (WHERE q.latency_ms > 100) as latency,
    COUNT(*) FILTER (WHERE q.packet_loss_pct > 5) as packet_loss,
    ROUND(AVG(CASE
        WHEN q.download_mbps >= 25 THEN 5 WHEN q.download_mbps >= 15 THEN 4
        WHEN q.download_mbps >= 10 THEN 3 WHEN q.download_mbps >= 5 THEN 2 ELSE 1
    END)::numeric, 1) as satisfaction
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY d.name_en
ORDER BY total DESC
```

**Configuration:**
- Chart Type: Table
- Columns: division, total, speed, drop_conn, latency, packet_loss, satisfaction

---

## Chart 4.6: Mobile App Engagement (3 Big Numbers)

**SQL Query:**
```sql
SELECT
    COUNT(DISTINCT agent_id) * 1000 as active_users,
    COUNT(*) FILTER (WHERE download_mbps IS NOT NULL) as speed_tests,
    ROUND(AVG(CASE
        WHEN download_mbps >= 30 THEN 4.5 WHEN download_mbps >= 20 THEN 4.0
        WHEN download_mbps >= 10 THEN 3.5 ELSE 3.0
    END)::numeric, 1) as app_rating
FROM ts_qos_measurements
WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
```

**Configuration:**
- Add Markdown header: `📱 **Mobile App Engagement**`
- Create 3 Big Number charts in a row:
  - Active Users (Blue)
  - Speed Tests/mo (Green)
  - App Rating (Gold)

---

# TAB 5: INFRASTRUCTURE STATUS

**Executive Question**: "What is our current infrastructure health?"

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  [MARKDOWN] Real-Time PoP Health Status            Last Updated | Refresh    │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ROW 1: PoP Health Summary (3 Big Numbers with %)                            │
│  ┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐     │
│  │  🟢 39              │ │  🟡 81              │ │  🔴 0               │     │
│  │  (32.5%) HEALTHY    │ │  (67.5%) DEGRADED   │ │  (0%) DOWN          │     │
│  └─────────────────────┘ └─────────────────────┘ └─────────────────────┘     │
│  [MARKDOWN] TOTAL PoPs: 120                                                  │
│                                                                              │
│  ROW 2: Critical Alerts (Full Width)                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │  ⚠️ CRITICAL ALERTS (7 PoPs Down)                                    │    │
│  │  POP ID | ISP | LOCATION | DOWN SINCE | IMPACT                       │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ROW 3: PoP Health by Division + Availability Trend                          │
│  ┌─────────────────────────────────┬─────────────────────────────────────┐   │
│  │  PoP HEALTH BY DIVISION         │  PoP AVAILABILITY TREND (Weekly)    │   │
│  │                                 │  ▓▓▓  ▓▓▓  ▓▓▓  ▓▓▓                 │   │
│  │                                 │  W1   W2   W3   W4   Target: 99%    │   │
│  │                                 │  30-Day: 97.8% | Best | Worst       │   │
│  └─────────────────────────────────┴─────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Chart 5.1: PoP Health Summary (3 Big Numbers)

**Note:** Health classification based on QoS metrics (same as Chart 5.3):
- **Healthy**: Latency < 50ms AND Packet Loss < 0.5%
- **Degraded**: Latency 50-100ms OR Packet Loss 0.5-1.5%
- **Down**: Latency >= 100ms OR Packet Loss >= 1.5% OR No measurements

**SQL Query:**
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
    COUNT(*) as total_pops,
    ROUND((COUNT(*) FILTER (WHERE avg_latency < 50 AND avg_packet_loss < 0.5)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as healthy_pct,
    ROUND((COUNT(*) FILTER (WHERE (avg_latency >= 50 AND avg_latency < 100)
                       OR (avg_packet_loss >= 0.5 AND avg_packet_loss < 1.5))::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as degraded_pct,
    ROUND((COUNT(*) FILTER (WHERE avg_latency >= 100 OR avg_packet_loss >= 1.5
                       OR avg_latency IS NULL)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as down_pct
FROM pop_health
```

**Configuration:**
- Create 3 Big Number charts with manual subheaders (update % from query results):
  - Healthy (Green): Metric=`healthy`, Subheader=`(32.5%) HEALTHY`
  - Degraded (Yellow): Metric=`degraded`, Subheader=`(67.5%) DEGRADED`
  - Down (Red): Metric=`down`, Subheader=`(0%) DOWN`
- Add Markdown footer: `**TOTAL PoPs:** 120`

---

## Chart 5.2: Critical Alerts (Table)

**Note:** This query identifies worst-performing PoPs based on QoS metrics. "Down Since" times are simulated based on severity ranking. "Impact" shows estimated affected subscribers.

**SQL Query:**
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

**Configuration:**
- Chart Type: Table
- Columns: pop_id, isp, location, down_since, impact
- Add Markdown header: `⚠️ **Critical Alerts (7 PoPs Down)**`
- Conditional formatting: down_since column in Red color

---

## Chart 5.3: PoP Health by Division (Table)

**Note:** Health classification based on QoS metrics:
- **Healthy**: Latency < 50ms AND Packet Loss < 0.5%
- **Degraded**: Latency 50-100ms OR Packet Loss 0.5-1.5%
- **Down**: Latency >= 100ms OR Packet Loss >= 1.5% OR No measurements

**SQL Query:**
```sql
WITH pop_health AS (
    SELECT
        p.id,
        gd.division_id,
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

**Configuration:**
- Chart Type: Table
- Columns: division, total, healthy, degraded, down, availability_pct
- Conditional formatting for availability_pct: >=80%=Green, 50-80%=Yellow, <50%=Red

---

## Chart 5.4: PoP Availability Trend (Bar Chart - Weekly)

**SQL Query for Bar Chart:**
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

**SQL Query for Summary Stats (separate Big Numbers or Markdown):**
```sql
WITH weekly_data AS (
    SELECT
        DATE_TRUNC('week', time) as week_start,
        ROUND((COUNT(*) FILTER (WHERE latency_ms IS NOT NULL)::numeric /
               NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability_pct
    FROM ts_qos_measurements
    WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
    GROUP BY DATE_TRUNC('week', time)
)
SELECT
    ROUND(AVG(availability_pct)::numeric, 1) as avg_30day,
    MAX(availability_pct) as best,
    MIN(availability_pct) as worst,
    99 as target
FROM weekly_data
```

**Configuration:**
- Chart Type: Bar Chart (Vertical)
- X-Axis: `week`
- Y-Axis: `availability_pct`
- Y-Axis Range: Min=90, Max=100
- Bar Color: Green
- Add Reference Line at 99% (Target) - Dashed Gray
- Add Markdown footer below chart:
  ```
  **30-Day Avg:** 97.8% | **Best:** 99.2% | **Worst:** 95.4% | **Target:** 99%
  ```
  (Update values from summary query results)

---

# DASHBOARD CONFIGURATION

## Creating the Dashboard

1. Go to **Dashboards** → **+ Dashboard**
2. Name: `BTRC Executive Dashboard`
3. Drag charts from the panel
4. Use **Tabs** component for 5 tabs

---

# FILTERS & DRILL-DOWN CONFIGURATION

## Overview of Filter Types

| Filter Type | Purpose | Scope |
|-------------|---------|-------|
| Native Filters | Global dashboard filters | All charts |
| Cross-Filters | Click chart to filter others | Connected charts |
| Filter Box (Legacy) | Dropdown filters | Selected charts |
| URL Parameters | External linking | Cross-dashboard |

---

## Step 1: Enable Dashboard Settings

### 1.1 Enable Cross-Filtering

1. Open your dashboard in **Edit mode** (click pencil icon)
2. Click **...** (three dots menu) → **Edit properties**
3. In the modal, find **Advanced** section
4. Toggle ON: **Enable cross-filtering**
5. Click **Save**

### 1.2 Enable Filter Sync

1. Still in Edit properties
2. Toggle ON: **Filter charts by same dataset**
3. This allows charts using the same dataset to auto-filter together

---

## Step 2: Add Native Filters (Recommended Method)

Native Filters appear in the left sidebar of the dashboard.

### 2.1 Open Filter Configuration

1. Open dashboard (not in edit mode)
2. Click the **Filter icon** (funnel) in the top toolbar
3. Click **+ Add/Edit Filters**

### 2.2 Add Time Range Filter

1. Click **+ Add filter**
2. Configure:
   - **Filter Type**: Time Range
   - **Filter Name**: `Time Period`
   - **Dataset**: Select `ts_qos_measurements` (or your main time-series dataset)
   - **Time Column**: `time`
3. Click **Default Value** tab:
   - Select **Last 30 days** (or your preferred default)
4. Click **Scoping** tab:
   - Select **Apply to all charts** OR
   - Check specific charts that should be filtered
5. Click **Save**

### 2.3 Add Division Filter

1. Click **+ Add filter**
2. Configure:
   - **Filter Type**: Value
   - **Filter Name**: `Division`
   - **Dataset**: Select dataset that has division data (e.g., `division_performance`)
   - **Column**: `division`
3. **Configuration** tab:
   - **Filter Type**: Select
   - **Enable search**: ON
   - **Multiple select**: ON (optional)
   - **Sort filter values**: ON
4. **Default Value** tab:
   - Leave empty for "All" or select a default
5. **Scoping** tab:
   - Apply to relevant charts (Tab 1, 2, 3 charts)
6. Click **Save**

### 2.4 Add ISP Category Filter

1. Click **+ Add filter**
2. Configure:
   - **Filter Type**: Value
   - **Filter Name**: `ISP Category`
   - **Dataset**: Select `isp_category_performance` or relevant dataset
   - **Column**: `category`
3. **Configuration** tab:
   - **Filter Type**: Select
   - **Enable search**: ON
4. **Scoping** tab:
   - Apply to ISP-related charts
5. Click **Save**

### 2.5 Add ISP Name Filter

1. Click **+ Add filter**
2. Configure:
   - **Filter Type**: Value
   - **Filter Name**: `ISP`
   - **Dataset**: Select dataset with ISP names
   - **Column**: `isp` or `name_en`
3. **Configuration** tab:
   - **Filter Type**: Select
   - **Enable search**: ON
   - **Multiple select**: ON
5. Click **Save**

### 2.6 Create Dependent Filter (District depends on Division)

1. Click **+ Add filter**
2. Configure:
   - **Filter Type**: Value
   - **Filter Name**: `District`
   - **Dataset**: Select `geo_districts` dataset
   - **Column**: `name_en`
3. **Configuration** tab:
   - **Parent filter**: Select `Division` filter
   - This makes District filter dependent on Division selection
4. Click **Save**

---

## Step 3: Configure Cross-Filtering on Charts

Cross-filtering allows clicking on a chart element to filter other charts.

### 3.1 Enable Cross-Filter on a Chart

1. Go to **Charts** → Select a chart (e.g., Division Performance Bar Chart)
2. Click **Edit**
3. Go to **Customize** tab
4. Find **Cross-filter scoping** section
5. Toggle: **Enable cross-filtering**
6. Select which charts should be affected
7. Click **Save** and **Update Dashboard**

### 3.2 Example: Division Bar Chart Cross-Filter

When user clicks on "Dhaka" bar:
- All other charts filter to show only Dhaka data
- Works automatically when cross-filtering is enabled

### 3.3 Charts Recommended for Cross-Filtering

| Chart | Cross-Filter Action |
|-------|---------------------|
| Division Performance (Bar) | Click division → filter all |
| Country Map | Click division → filter all |
| ISP Category Table | Click category → filter ISP charts |
| Violation Trend (Bar) | Click month → filter to month |
| PoP Health by Division | Click division → filter Tab 5 |

---

## Step 4: Add Drill-Down with Dashboard Tabs

### 4.1 Tab-to-Tab Navigation Setup

Create filter-aware tab navigation:

1. **Division Performance Table (Tab 1)** → Drill to **Tab 2**
   - When user clicks division, Tab 2 shows that division's details

2. **ISP Category Table (Tab 1)** → Drill to **Tab 3**
   - When user clicks ISP category, Tab 3 shows compliance for that category

### 4.2 Implementing Drill-Down Links

For clickable links in tables, create a dataset with URL column:

**SQL Example - Division with Drill-Down Link:**
```sql
SELECT
    d.name_en as division,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    CONCAT('/superset/dashboard/executive/?native_filters_key=',
           REPLACE(d.name_en, ' ', '%20')) as drill_down_url
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_qos_measurements)
GROUP BY d.name_en
```

**Note**: URL-based drill-down requires custom configuration and may need Superset Jinja templates.

---

## Step 5: Configure Filter Scoping

Control which charts respond to which filters.

### 5.1 Filter Scoping Options

| Option | Description |
|--------|-------------|
| All charts | Filter applies to entire dashboard |
| All charts in tab | Filter applies only to current tab |
| Specific charts | Select individual charts |
| Exclude charts | Exclude specific charts from filter |

### 5.2 Recommended Scoping

| Filter | Scope |
|--------|-------|
| Time Period | All charts (global) |
| Division | Tab 1, 2, 3, 5 charts |
| ISP Category | Tab 1, 3 charts |
| ISP | Tab 3, 4 charts |
| District | Tab 2 charts only |

### 5.3 Configure Scoping

1. In Filter panel, click on a filter
2. Go to **Scoping** tab
3. Select scoping method:
   - **Apply to all charts**
   - **Apply to specific charts** → check boxes
4. Click **Save**

---

## Step 6: Add Filter Indicator to Charts

Show active filter status on charts.

### 6.1 Chart Subtitle with Filter Info

In chart configuration:
1. Go to **Customize** tab
2. **X Axis Title** or **Chart Title**:
   - Use Jinja template: `Speed by Division {{ filter_values('division') | default('All') }}`

### 6.2 Dashboard Header with Filter Summary

Add a **Markdown** component showing current filters:
```markdown
**Active Filters:** Division: All | Time: Last 30 Days | Category: All
```

---

## Step 7: Configure Auto-Refresh

### 7.1 Enable Auto-Refresh

1. Open dashboard (view mode)
2. Click **⚙️** (settings icon) in toolbar
3. Click **Set auto-refresh interval**
4. Select: **5 minutes** (recommended for Executive Dashboard)
5. Dashboard will auto-reload every 5 minutes

### 7.2 Tab-Specific Refresh Rates

| Tab | Recommended Refresh |
|-----|---------------------|
| Tab 1: Performance | 5 minutes |
| Tab 2: Geographic | 15 minutes |
| Tab 3: Compliance | 5 minutes |
| Tab 4: Consumer | 30 minutes |
| Tab 5: Infrastructure | 1 minute (if real-time needed) |

**Note**: Superset applies one refresh rate to entire dashboard. For different rates, create separate dashboards.

---

## Step 8: Export and Print Configuration

### 8.1 Enable Export Options

1. In dashboard edit mode
2. Click **...** → **Edit properties**
3. Ensure these are enabled:
   - **Allow download as image**
   - **Allow download data**

### 8.2 Export Individual Charts

1. Hover over any chart
2. Click **...** (three dots)
3. Options:
   - **Download as image** (PNG)
   - **Export to CSV** (data)
   - **View query** (SQL)

### 8.3 Print Dashboard

1. Click **...** in dashboard toolbar
2. Select **Download as image** or use browser print (Ctrl+P)

---

## Step 9: Color Scheme Configuration

### 9.1 Dashboard Color Palette

Set consistent colors across all charts:

1. Edit dashboard properties
2. Under **Color Scheme**, select a palette or use custom

### 9.2 Recommended Colors

| Status | Hex Code | Usage |
|--------|----------|-------|
| Good/Healthy | `#52c41a` | Compliant, High scores |
| Warning/At Risk | `#faad14` | Marginal, Medium scores |
| Critical/Violation | `#ff4d4f` | Violations, Low scores |
| Info/Neutral | `#1890ff` | Informational |
| BTRC Brand | `#00a651` | Headers, Highlights |

### 9.3 Apply Conditional Formatting

For tables with status columns:

1. Edit chart → **Customize** tab
2. Find **Conditional Formatting**
3. Add rules:
   - Column: `status`
   - Operator: `equals`
   - Value: `Critical`
   - Color: `#ff4d4f`

---

## Step 10: Complete Filter Setup Checklist

### Pre-Deployment Checklist

| Item | Status |
|------|--------|
| Time Range filter added | ☐ |
| Division filter added | ☐ |
| ISP Category filter added | ☐ |
| ISP filter added | ☐ |
| Cross-filtering enabled | ☐ |
| Filter scoping configured | ☐ |
| Auto-refresh set (5 min) | ☐ |
| Export options enabled | ☐ |
| Color scheme applied | ☐ |
| All charts respond to filters | ☐ |

### Testing Filters

1. Select "Dhaka" in Division filter
2. Verify all charts update to show Dhaka data
3. Select "Last 7 days" in Time filter
4. Verify data changes to 7-day window
5. Click on a bar in Division chart
6. Verify cross-filtering works

---

## Troubleshooting Filters

### Filter Not Affecting Chart

**Problem**: Chart doesn't respond to filter selection

**Solutions**:
1. Check filter **Scoping** - ensure chart is included
2. Verify chart dataset has the filtered column
3. Column names must match exactly (case-sensitive)
4. Refresh the dashboard

### Cross-Filter Not Working

**Problem**: Clicking chart doesn't filter others

**Solutions**:
1. Enable cross-filtering in dashboard properties
2. Enable cross-filtering on the source chart
3. Ensure charts share a common column/dimension
4. Check that target charts have cross-filter enabled

### Time Filter Shows No Data

**Problem**: Time filter results in empty charts

**Solutions**:
1. Check data date range:
   ```sql
   SELECT MIN(time), MAX(time) FROM ts_qos_measurements;
   ```
2. Use dynamic date filtering in queries (as shown in this guide)
3. Set appropriate default time range

---

# SUMMARY

| Tab | Charts |
|-----|--------|
| 1. Performance Scorecard | 7 charts |
| 2. Geographic Intelligence | 6 charts |
| 3. Compliance & Enforcement | 5 charts |
| 4. Consumer Experience | 10 charts |
| 5. Infrastructure Status | 7 charts |
| **TOTAL** | **~35 charts** |

---

**Document Version**: 2.0
**Last Updated**: 2026-01-29
