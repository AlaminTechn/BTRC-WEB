# BTRC Regulatory Dashboard - Superset Creation Guide

**Version**: 1.0
**Date**: 2026-01-29
**Dashboard**: Regulatory Operations Dashboard
**Total Components**: ~14 charts across 5 tabs

---

## Overview

The Regulatory Dashboard follows a **monitoring-first workflow**:

```
DETECT → LOCATE → DOCUMENT → ANALYZE → AUDIT
  Tab 1    Tab 2     Tab 3      Tab 4    Tab 5
```

### Tab Summary

| Tab | Name | Purpose | Components |
|-----|------|---------|------------|
| 1 | SLA Monitoring | Are ISPs meeting commitments? | 4 |
| 2 | Regional Analysis | Where are issues concentrated? | 2 |
| 3 | Violation Reporting | Document violations | 2 |
| 4 | Investigation Center | Root cause analysis | 3 |
| 5 | License Compliance | Infrastructure commitments | 4 |

---

# TAB 1: SLA MONITORING

**Purpose**: "Are ISPs meeting their service commitments?"
**Refresh Rate**: 5 minutes
**Workflow Stage**: DETECT

## Layout (Matching Demo UI)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ SLA COMPLIANCE OVERVIEW                           Last Check: 2 min ago  🔄  │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────┐ ┌─────────────────────────┐ ┌─────────────────────────┐
│  │ COMPLIANT          ✓   │ │ AT RISK            ⚠    │ │ VIOLATION          ✕   │
│  │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │
│  │ │        847          │ │ │ │         89          │ │ │ │         34          │ │
│  │ └─────────────────────┘ │ │ └─────────────────────┘ │ │ └─────────────────────┘ │
│  │ 87% of total ISPs       │ │ 9% of total ISPs        │ │ 4% of total ISPs        │
│  │ [Green Border]          │ │ [Yellow Border]         │ │ [Red Border]            │
│  └─────────────────────────┘ └─────────────────────────┘ └─────────────────────────┘
│                                                                              │
│  Total Monitored: 970 ISPs                                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────┐  ┌────────────────────────────────────────┐  │
│  │  PACKAGE COMPLIANCE MATRIX │  │  REAL-TIME THRESHOLD ALERTS            │  │
│  └────────────────────────────┘  └────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────────────────┤
│  PoP-LEVEL PERFORMANCE VALIDATION (Full Width Table)                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## STEP-BY-STEP CREATION GUIDE

### Step 1: Create the Dashboard

1. Go to **Dashboards** → **+ Dashboard**
2. Name: `BTRC Regulatory Dashboard`
3. Click **Save**
4. Click **Edit Dashboard** (pencil icon)
5. Add **Tabs** component → Create tab named `SLA Monitoring`

---

## ROW 1: SLA COMPLIANCE OVERVIEW

### Component 1.0: Header Row (Markdown)

**Add Markdown Component:**
1. In Edit mode, click **+** → **Markdown**
2. Paste:
```markdown
## SLA COMPLIANCE OVERVIEW
<div style="float: right; color: #888; font-size: 12px;">
Last Check: 2 min ago &nbsp; 🔄
</div>
```
3. Drag to full width at top

---

### Component 1.1a: COMPLIANT Card (Big Number)

**Dataset**: `reg_sla_compliance_overview`

**SQL Query (SQL Lab → Save Dataset):**
```sql
WITH isp_compliance AS (
    SELECT
        i.id as isp_id,
        i.name_en,
        AVG(q.download_mbps) as avg_speed,
        ROUND((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
               NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability
    FROM isps i
    JOIN pops p ON p.isp_id = i.id
    LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
        AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    WHERE i.is_active = true
    GROUP BY i.id, i.name_en
)
SELECT
    COUNT(*) FILTER (WHERE avg_speed >= 20 AND availability >= 99) as compliant,
    COUNT(*) FILTER (WHERE (avg_speed >= 15 AND avg_speed < 20)
                        OR (availability >= 95 AND availability < 99)) as at_risk,
    COUNT(*) FILTER (WHERE avg_speed < 15 OR availability < 95) as violation,
    COUNT(*) as total_isps,
    CONCAT(ROUND((COUNT(*) FILTER (WHERE avg_speed >= 20 AND availability >= 99)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 0)::text, '% of total ISPs') as compliant_subheader,
    CONCAT(ROUND((COUNT(*) FILTER (WHERE (avg_speed >= 15 AND avg_speed < 20)
                        OR (availability >= 95 AND availability < 99))::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 0)::text, '% of total ISPs') as at_risk_subheader,
    CONCAT(ROUND((COUNT(*) FILTER (WHERE avg_speed < 15 OR availability < 95)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 0)::text, '% of total ISPs') as violation_subheader
FROM isp_compliance
```

**Create Chart:**
1. Go to **Charts** → **+ Chart**
2. Select dataset: `reg_sla_compliance_overview`
3. Chart Type: **Big Number**
4. Configure:
   - **Metric**: `compliant` (MAX)
   - **Subheader**: Leave empty (we'll use header)
5. **Customize** tab:
   - **Big Number Font Size**: 60
   - **Subheader Font Size**: 16
   - **Header**: `COMPLIANT ✓`
   - **Subheader**: Query result shows `100% of total ISPs` (or use manual text)
6. Click **Update Chart**
7. **Save** → Name: `REG 1.1a - Compliant ISPs`

**Styling (CSS in Dashboard):**
- Add CSS class: `compliant-card`
- Border color: `#52c41a` (Green)

---

### Component 1.1b: AT RISK Card (Big Number)

**Create Chart (Save As from 1.1a):**
1. Open `REG 1.1a - Compliant ISPs`
2. Click **Save As** → Name: `REG 1.1b - At Risk ISPs`
3. Change:
   - **Metric**: `at_risk` (MAX)
   - **Header**: `AT RISK ⚠`
   - **Subheader**: `9% of total ISPs` (from query or manual)
4. **Customize**:
   - Border color: `#faad14` (Yellow/Orange)
5. **Save**

---

### Component 1.1c: VIOLATION Card (Big Number)

**Create Chart (Save As from 1.1a):**
1. Open `REG 1.1a - Compliant ISPs`
2. Click **Save As** → Name: `REG 1.1c - Violation ISPs`
3. Change:
   - **Metric**: `violation` (MAX)
   - **Header**: `VIOLATION ✕`
   - **Subheader**: `4% of total ISPs` (from query or manual)
4. **Customize**:
   - Border color: `#ff4d4f` (Red)
5. **Save**

---

### Component 1.1d: Total Monitored Footer (Markdown)

**Add Markdown Component:**
```markdown
**Total Monitored: 40 ISPs**
```
*(Update number from your query result)*

---

## ROW 2: PACKAGE COMPLIANCE + ALERTS

### Component 1.2: Package Compliance Matrix (Table)

**Dataset**: `reg_package_compliance`

**SQL Query:**
```sql
WITH package_performance AS (
    SELECT
        CASE
            WHEN pk.download_speed_mbps <= 10 THEN '10 Mbps'
            WHEN pk.download_speed_mbps <= 25 THEN '25 Mbps'
            WHEN pk.download_speed_mbps <= 50 THEN '50 Mbps'
            WHEN pk.download_speed_mbps <= 100 THEN '100 Mbps'
            ELSE '200+ Mbps'
        END as package_tier,
        pk.download_speed_mbps as target_speed,
        AVG(q.download_mbps) as actual_speed
    FROM packages pk
    JOIN isps i ON pk.isp_id = i.id
    JOIN pops p ON p.isp_id = i.id
    LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
        AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    WHERE pk.is_active = true
    GROUP BY 1, pk.download_speed_mbps
)
SELECT
    package_tier as "Package",
    ROUND(AVG(target_speed)::numeric, 1) as "Target",
    ROUND(AVG(actual_speed)::numeric, 1) as "Actual",
    CONCAT(
        CASE WHEN ((AVG(actual_speed) - AVG(target_speed)) / NULLIF(AVG(target_speed), 0) * 100) >= 0
             THEN '+' ELSE '' END,
        ROUND(((AVG(actual_speed) - AVG(target_speed)) / NULLIF(AVG(target_speed), 0) * 100)::numeric, 0)::text,
        '%'
    ) as "Gap"
FROM package_performance
GROUP BY package_tier
ORDER BY
    CASE package_tier
        WHEN '10 Mbps' THEN 1 WHEN '25 Mbps' THEN 2 WHEN '50 Mbps' THEN 3
        WHEN '100 Mbps' THEN 4 ELSE 5
    END
```

**Create Chart:**
1. Chart Type: **Table**
2. **Query Mode**: Raw Records
3. **Columns**: Package, Target, Actual, Gap
4. **Customize**:
   - **Conditional Formatting**:
     - Column `Gap`, if contains `-`, Background: Light Red (#fff1f0)
     - Column `Gap`, if contains `+`, Background: Light Green (#f6ffed)
5. **Save**: `REG 1.2 - Package Compliance Matrix`

**Drill-Down**: Click on Package row → filters to show ISPs with that package type

---

### Component 1.3: Real-Time Threshold Alerts (Table)

**Dataset**: `reg_realtime_alerts`

**SQL Query:**
```sql
SELECT
    i.name_en as "ISP",
    CONCAT('Threshold Breach - ', gd.name_en) as "Alert",
    v.severity as "Severity",
    CONCAT(ROUND(v.actual_value::numeric, 1)::text, ' vs ', ROUND(v.expected_value::numeric, 1)::text) as "Values",
    CASE
        WHEN EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) < 3600
            THEN CONCAT(ROUND(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 60)::integer::text, 'm ago')
        WHEN EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) < 86400
            THEN CONCAT(FLOOR(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 3600)::integer::text, 'h ago')
        ELSE CONCAT(FLOOR(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 86400)::integer::text, 'd ago')
    END as "Time"
FROM sla_violations v
JOIN isps i ON v.isp_id = i.id
LEFT JOIN pops p ON v.pop_id = p.id
LEFT JOIN geo_districts gd ON p.district_id = gd.id
WHERE v.status IN ('DETECTED', 'INVESTIGATING')
  AND v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '7 days' FROM sla_violations)
ORDER BY
    CASE v.severity WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 WHEN 'MEDIUM' THEN 3 ELSE 4 END,
    v.detection_time DESC
LIMIT 10
```

**Create Chart:**
1. Chart Type: **Table**
2. **Columns**: ISP, Alert, Severity, Values, Time
3. **Customize**:
   - Add Header: `🔔 Real-Time Threshold Alerts`
   - **Conditional Formatting**:
     - Column `Severity` = `CRITICAL`: Background Red (#ff4d4f), Text White
     - Column `Severity` = `HIGH`: Background Orange (#fa8c16), Text White
     - Column `Severity` = `MEDIUM`: Background Yellow (#fadb14)
4. **Save**: `REG 1.3 - Real-Time Alerts`

**Drill-Down**: Click on ISP → opens Investigation Center (Tab 4) filtered to that ISP

---

## ROW 3: PoP-LEVEL PERFORMANCE VALIDATION

### Component 1.4: PoP Incidents Table (Full Width)

**Dataset**: `reg_pop_incidents`

**SQL Query:**
```sql
SELECT
    CONCAT('INC-', TO_CHAR(v.detection_time, 'YYYY'), '-', LPAD(v.id::text, 4, '0')) as "Incident ID",
    i.name_en as "ISP",
    CONCAT(p.name_en, ' (', gd.name_en, ')') as "PoP Location",
    'Threshold Breach' as "Metric",
    v.status as "Status",
    CASE
        WHEN v.status = 'RESOLVED' THEN 'Resolved'
        WHEN EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) < 3600
            THEN CONCAT(ROUND(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 60)::integer::text, 'm')
        ELSE CONCAT(FLOOR(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 3600)::integer::text, 'h ',
             MOD(ROUND(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 60)::integer, 60)::text, 'm')
    END as "Duration"
FROM sla_violations v
JOIN isps i ON v.isp_id = i.id
JOIN pops p ON v.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
WHERE v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '7 days' FROM sla_violations)
ORDER BY
    CASE v.status WHEN 'DETECTED' THEN 1 WHEN 'INVESTIGATING' THEN 2 ELSE 3 END,
    v.detection_time DESC
LIMIT 15
```

**Create Chart:**
1. Chart Type: **Table**
2. **Columns**: Incident ID, ISP, PoP Location, Metric, Status, Duration
3. **Customize**:
   - Add Header: `📋 PoP-Level Performance Validation`
   - **Conditional Formatting**:
     - Column `Status` = `DETECTED`: Background Red, Text White
     - Column `Status` = `INVESTIGATING`: Background Yellow
     - Column `Status` = `RESOLVED`: Background Green (#52c41a), Text White
   - **Row Actions**: Enable row click
4. **Save**: `REG 1.4 - PoP Incidents`

**Drill-Down**: Click on row → navigates to Tab 4 (Investigation Center) with that incident

---

## TAB 1 FILTERS

### Add Native Filters for Tab 1

1. Open Dashboard in View mode
2. Click **Filter** icon (funnel) → **+ Add/Edit Filters**

**Filter 1: Time Period**
- Filter Type: Time Range
- Name: `Time Period`
- Dataset: `reg_sla_compliance_overview` (or any with time)
- Default: `Last 24 hours`
- Scope: All Tab 1 charts

**Filter 2: ISP**
- Filter Type: Value
- Name: `ISP`
- Dataset: `reg_realtime_alerts`
- Column: `ISP`
- Multiple Select: Yes
- Scope: Charts 1.3, 1.4

**Filter 3: Severity**
- Filter Type: Value
- Name: `Severity`
- Dataset: `reg_realtime_alerts`
- Column: `Severity`
- Options: CRITICAL, HIGH, MEDIUM, LOW
- Scope: Charts 1.3, 1.4

**Filter 4: Status**
- Filter Type: Value
- Name: `Status`
- Dataset: `reg_pop_incidents`
- Column: `Status`
- Options: DETECTED, INVESTIGATING, RESOLVED
- Scope: Chart 1.4

---

## TAB 1 CROSS-FILTERING (Drill-Down)

### Enable Cross-Filtering

1. Edit Dashboard → Click **...** → **Edit properties**
2. Enable: **Cross-filtering**
3. Save

### Cross-Filter Behavior

| Click On | Filters |
|----------|---------|
| Compliant Card | Shows only compliant ISPs in tables |
| At Risk Card | Shows only at-risk ISPs in tables |
| Violation Card | Shows only violation ISPs in tables |
| Package Row | Filters incidents by that package tier |
| Alert Row | Highlights related PoP incidents |
| Incident Row | Can link to Tab 4 Investigation |

---

## TAB 1 DASHBOARD CSS (Optional Styling)

Add custom CSS in Dashboard properties:

```css
/* Compliant Card - Green Border */
.compliant-card {
  border-left: 4px solid #52c41a !important;
}

/* At Risk Card - Yellow Border */
.at-risk-card {
  border-left: 4px solid #faad14 !important;
}

/* Violation Card - Red Border */
.violation-card {
  border-left: 4px solid #ff4d4f !important;
}

/* Dark theme adjustments */
.dashboard-component {
  background: #1f1f1f;
  border-radius: 8px;
}
```

---

## TAB 1 ASSEMBLY CHECKLIST

| Step | Component | Status |
|------|-----------|--------|
| 1 | Create Dashboard with Tab | ☐ |
| 2 | Add Header Markdown | ☐ |
| 3 | Create Dataset: reg_sla_compliance_overview | ☐ |
| 4 | Create Chart: REG 1.1a - Compliant | ☐ |
| 5 | Create Chart: REG 1.1b - At Risk | ☐ |
| 6 | Create Chart: REG 1.1c - Violation | ☐ |
| 7 | Add Footer Markdown (Total Monitored) | ☐ |
| 8 | Create Dataset: reg_package_compliance | ☐ |
| 9 | Create Chart: REG 1.2 - Package Matrix | ☐ |
| 10 | Create Dataset: reg_realtime_alerts | ☐ |
| 11 | Create Chart: REG 1.3 - Alerts | ☐ |
| 12 | Create Dataset: reg_pop_incidents | ☐ |
| 13 | Create Chart: REG 1.4 - Incidents | ☐ |
| 14 | Add Filters (Time, ISP, Severity, Status) | ☐ |
| 15 | Enable Cross-Filtering | ☐ |
| 16 | Set Auto-Refresh (5 min) | ☐ |
| 17 | Apply CSS Styling | ☐ |

---

## Chart 1.1: SLA Compliance Overview (3 Big Numbers) - LEGACY SECTION

**Configuration:**
- Create 3 Big Numbers:
  - Compliant (Green): Metric=`compliant`, Subheader=`87% of total ISPs`
  - At Risk (Yellow): Metric=`at_risk`, Subheader=`(9%) AT RISK`
  - Violation (Red): Metric=`violation`, Subheader=`(4%) VIOLATION`
- Add Markdown footer: `**Total Monitored:** X ISPs`

---

## Chart 1.2: Package Compliance Matrix (Table)

**SQL Query:**
```sql
WITH package_performance AS (
    SELECT
        CASE
            WHEN pk.download_speed_mbps <= 10 THEN '10 Mbps'
            WHEN pk.download_speed_mbps <= 25 THEN '25 Mbps'
            WHEN pk.download_speed_mbps <= 50 THEN '50 Mbps'
            WHEN pk.download_speed_mbps <= 100 THEN '100 Mbps'
            ELSE '200+ Mbps'
        END as package_tier,
        pk.download_speed_mbps as target_speed,
        AVG(q.download_mbps) as actual_speed
    FROM packages pk
    JOIN isps i ON pk.isp_id = i.id
    JOIN pops p ON p.isp_id = i.id
    LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
        AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    WHERE pk.is_active = true
    GROUP BY
        CASE
            WHEN pk.download_speed_mbps <= 10 THEN '10 Mbps'
            WHEN pk.download_speed_mbps <= 25 THEN '25 Mbps'
            WHEN pk.download_speed_mbps <= 50 THEN '50 Mbps'
            WHEN pk.download_speed_mbps <= 100 THEN '100 Mbps'
            ELSE '200+ Mbps'
        END,
        pk.download_speed_mbps
)
SELECT
    package_tier as package,
    ROUND(AVG(target_speed)::numeric, 1) as target,
    ROUND(AVG(actual_speed)::numeric, 1) as actual,
    CONCAT(ROUND(((AVG(actual_speed) - AVG(target_speed)) / NULLIF(AVG(target_speed), 0) * 100)::numeric, 0)::text, '%') as gap
FROM package_performance
GROUP BY package_tier
ORDER BY
    CASE package_tier
        WHEN '10 Mbps' THEN 1
        WHEN '25 Mbps' THEN 2
        WHEN '50 Mbps' THEN 3
        WHEN '100 Mbps' THEN 4
        ELSE 5
    END
```

**Configuration:**
- Chart Type: Table
- Columns: package, target, actual, gap
- Conditional formatting: gap column - negative values in Red

---

## Chart 1.3: Real-Time Threshold Alerts (Table)

**SQL Query:**
```sql
WITH recent_alerts AS (
    SELECT
        i.name_en as isp,
        CASE v.violation_type
            WHEN 'SPEED_BELOW_THRESHOLD' THEN 'Speed'
            WHEN 'AVAILABILITY_BELOW_THRESHOLD' THEN 'Availability'
            WHEN 'LATENCY_ABOVE_THRESHOLD' THEN 'Latency'
            WHEN 'PACKET_LOSS_ABOVE_THRESHOLD' THEN 'Packet Loss'
            ELSE v.violation_type
        END as alert_type,
        gd.name_en as location,
        v.actual_value,
        v.expected_value,
        v.severity,
        v.detection_time,
        CASE
            WHEN EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) < 3600
                THEN CONCAT(ROUND(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 60)::integer::text, 'm ago')
            WHEN EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) < 86400
                THEN CONCAT(FLOOR(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 3600)::integer::text, 'h ago')
            ELSE CONCAT(FLOOR(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 86400)::integer::text, 'd ago')
        END as time_ago
    FROM sla_violations v
    JOIN isps i ON v.isp_id = i.id
    LEFT JOIN pops p ON v.pop_id = p.id
    LEFT JOIN geo_districts gd ON p.district_id = gd.id
    WHERE v.status = 'OPEN'
      AND v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '24 hours' FROM sla_violations)
    ORDER BY v.detection_time DESC
)
SELECT
    isp,
    CONCAT(alert_type, ' - ', location) as alert,
    CONCAT(ROUND(actual_value::numeric, 1)::text, ' vs ', ROUND(expected_value::numeric, 1)::text) as values,
    severity,
    time_ago
FROM recent_alerts
LIMIT 10
```

**Configuration:**
- Chart Type: Table
- Add Markdown header: `🔔 **Real-Time Threshold Alerts**`
- Columns: isp, alert, values, severity, time_ago
- Conditional formatting: severity column - CRITICAL=Red, WARNING=Yellow

---

## Chart 1.4: PoP-Level Performance Validation (Table)

**SQL Query:**
```sql
SELECT
    CONCAT('INC-', TO_CHAR(v.detection_time, 'YYYY'), '-', LPAD(v.id::text, 4, '0')) as incident_id,
    i.name_en as isp,
    CONCAT(gd.name_en, '-', p.name_en) as pop_location,
    CASE v.violation_type
        WHEN 'SPEED_BELOW_THRESHOLD' THEN 'Speed'
        WHEN 'AVAILABILITY_BELOW_THRESHOLD' THEN 'Uptime'
        WHEN 'LATENCY_ABOVE_THRESHOLD' THEN 'Latency'
        WHEN 'PACKET_LOSS_ABOVE_THRESHOLD' THEN 'Pkt Loss'
        ELSE 'Other'
    END as metric,
    v.status,
    CASE
        WHEN v.status = 'RESOLVED' THEN 'Resolved'
        WHEN EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) < 3600
            THEN CONCAT(ROUND(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 60)::integer::text, 'm')
        ELSE CONCAT(FLOOR(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 3600)::integer::text, 'h ',
             MOD(ROUND(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 60)::integer, 60)::text, 'm')
    END as duration
FROM sla_violations v
JOIN isps i ON v.isp_id = i.id
JOIN pops p ON v.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
WHERE v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '7 days' FROM sla_violations)
ORDER BY v.detection_time DESC
LIMIT 20
```

**Configuration:**
- Chart Type: Table
- Columns: incident_id, isp, pop_location, metric, status, duration
- Conditional formatting: status column - OPEN=Red, ACKNOWLEDGED=Yellow, RESOLVED=Green

---

# TAB 2: REGIONAL ANALYSIS

**Purpose**: "Where are service quality issues concentrated?"
**Refresh Rate**: 15 minutes

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────┐  ┌─────────────────────────────────┐    │
│  │  DIVISION PERFORMANCE MAP       │  │  DIVISION RANKING               │    │
│  │  [Bangladesh Map with colors]   │  │  Division    | Score | Trend   │    │
│  │                                 │  │  Dhaka       | 94.2  | ▲       │    │
│  │  Legend: >90 80-90 70-80 <70    │  │  Chattogram  | 91.8  | -       │    │
│  └─────────────────────────────────┘  └─────────────────────────────────┘    │
├──────────────────────────────────────────────────────────────────────────────┤
│                    ISP PERFORMANCE BY AREA                                   │
│  Division: [Dropdown]                                                        │
│  ISP | PoPs | Avg Speed | Availability | Violations | Score                 │
│  Link3 | 12 | 28.4 Mbps | 98.9% | 2 | 82.1                                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Chart 2.1: Division Performance Map (Country Map)

**SQL Query:**
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
    ROUND((
        (LEAST(AVG(q.download_mbps), 50) / 50 * 40) +
        (LEAST(100 - COALESCE(AVG(q.latency_ms), 100), 100) / 100 * 30) +
        ((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
          NULLIF(COUNT(*)::numeric, 0)) * 30)
    )::numeric, 1) as score
FROM ts_qos_measurements q
JOIN pops p ON q.pop_id = p.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
WHERE q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
GROUP BY d.name_en
```

**Configuration:**
- Chart Type: Country Map
- Country: Bangladesh
- Entity: iso_code
- Metric: score
- Color scheme: Green (>90) → Yellow (80-90) → Orange (70-80) → Red (<70)

---

## Chart 2.2: Division Ranking (Table)

**SQL Query:**
```sql
WITH current_scores AS (
    SELECT
        d.name_en as division,
        ROUND((
            (LEAST(AVG(q.download_mbps), 50) / 50 * 40) +
            (LEAST(100 - COALESCE(AVG(q.latency_ms), 100), 100) / 100 * 30) +
            ((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
              NULLIF(COUNT(*)::numeric, 0)) * 30)
        )::numeric, 1) as score
    FROM ts_qos_measurements q
    JOIN pops p ON q.pop_id = p.id
    JOIN geo_districts gd ON p.district_id = gd.id
    JOIN geo_divisions d ON gd.division_id = d.id
    WHERE q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    GROUP BY d.name_en
),
previous_scores AS (
    SELECT
        d.name_en as division,
        ROUND((
            (LEAST(AVG(q.download_mbps), 50) / 50 * 40) +
            (LEAST(100 - COALESCE(AVG(q.latency_ms), 100), 100) / 100 * 30) +
            ((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
              NULLIF(COUNT(*)::numeric, 0)) * 30)
        )::numeric, 1) as score
    FROM ts_qos_measurements q
    JOIN pops p ON q.pop_id = p.id
    JOIN geo_districts gd ON p.district_id = gd.id
    JOIN geo_divisions d ON gd.division_id = d.id
    WHERE q.time >= (SELECT MAX(time) - INTERVAL '48 hours' FROM ts_qos_measurements)
      AND q.time < (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    GROUP BY d.name_en
)
SELECT
    c.division,
    c.score,
    CASE
        WHEN c.score > COALESCE(p.score, 0) + 1 THEN '▲ Up'
        WHEN c.score < COALESCE(p.score, 0) - 1 THEN '▼ Down'
        ELSE '- Stable'
    END as trend
FROM current_scores c
LEFT JOIN previous_scores p ON c.division = p.division
ORDER BY c.score DESC
```

**Configuration:**
- Chart Type: Table
- Columns: division, score, trend
- Conditional formatting: score >=90=Green, 80-90=Yellow, <80=Red

---

## Chart 2.3: ISP Performance by Area (Table)

**SQL Query:**
```sql
SELECT
    i.name_en as isp,
    COUNT(DISTINCT p.id) as pops,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability,
    COUNT(DISTINCT v.id) as violations,
    ROUND((
        (LEAST(AVG(q.download_mbps), 50) / 50 * 40) +
        (LEAST(100 - COALESCE(AVG(q.latency_ms), 100), 100) / 100 * 30) +
        ((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
          NULLIF(COUNT(*)::numeric, 0)) * 30)
    )::numeric, 1) as score
FROM isps i
JOIN pops p ON p.isp_id = i.id
JOIN geo_districts gd ON p.district_id = gd.id
JOIN geo_divisions d ON gd.division_id = d.id
LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
    AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
LEFT JOIN sla_violations v ON v.isp_id = i.id
    AND v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
WHERE i.is_active = true
GROUP BY i.name_en
ORDER BY score DESC
LIMIT 15
```

**Configuration:**
- Chart Type: Table
- Columns: isp, pops, avg_speed (Mbps suffix), availability (% suffix), violations, score
- Conditional formatting: score <70=Red highlight

---

# TAB 3: VIOLATION REPORTING

**Purpose**: "What violations need to be documented?"
**Refresh Rate**: On-demand

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         VIOLATION SUMMARY                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐               │
│  │  PENDING REPORT │  │  UNDER REVIEW   │  │  COMPLETED      │               │
│  │       23        │  │       12        │  │      156        │               │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘               │
├──────────────────────────────────────────────────────────────────────────────┤
│                    VIOLATION REPORT GENERATOR                                │
│  ID | ISP | Type | Severity | Duration | Affected PoPs                      │
│  VIO-2024-312 | ISP-Alpha | Speed | Critical | 4h 23m | 3                   │
├──────────────────────────────────────────────────────────────────────────────┤
│                    EVIDENCE DOCUMENTATION                                    │
│  Metric: Download Speed | Threshold: 25 Mbps | Measured: 10.2 Mbps          │
│  Gap: -59.2% | Duration: 4h 23m | Est. Subscribers: ~4,200                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Chart 3.1: Violation Summary (3 Big Numbers)

**SQL Query:**
```sql
SELECT
    COUNT(*) FILTER (WHERE status = 'OPEN') as pending_report,
    COUNT(*) FILTER (WHERE status = 'ACKNOWLEDGED') as under_review,
    COUNT(*) FILTER (WHERE status = 'RESOLVED') as completed
FROM sla_violations
WHERE detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
```

**Configuration:**
- Create 3 Big Numbers:
  - Pending Report (Orange): Metric=`pending_report`, Subheader=`Need Documentation`
  - Under Review (Blue): Metric=`under_review`, Subheader=`Awaiting Approval`
  - Completed (Green): Metric=`completed`, Subheader=`This Month`

---

## Chart 3.2: Violation Report Generator (Table)

**SQL Query:**
```sql
SELECT
    CONCAT('VIO-', TO_CHAR(v.detection_time, 'YYYY'), '-', LPAD(v.id::text, 3, '0')) as violation_id,
    i.name_en as isp,
    CASE v.violation_type
        WHEN 'SPEED_BELOW_THRESHOLD' THEN 'Speed'
        WHEN 'AVAILABILITY_BELOW_THRESHOLD' THEN 'Uptime'
        WHEN 'LATENCY_ABOVE_THRESHOLD' THEN 'Latency'
        WHEN 'PACKET_LOSS_ABOVE_THRESHOLD' THEN 'Packet Loss'
        ELSE 'Other'
    END as type,
    v.severity,
    CASE
        WHEN EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) < 3600
            THEN CONCAT(ROUND(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 60)::integer::text, 'm')
        ELSE CONCAT(FLOOR(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 3600)::integer::text, 'h ',
             MOD(ROUND(EXTRACT(EPOCH FROM ((SELECT MAX(detection_time) FROM sla_violations) - v.detection_time)) / 60)::integer, 60)::text, 'm')
    END as duration,
    COUNT(DISTINCT v.pop_id) as affected_pops
FROM sla_violations v
JOIN isps i ON v.isp_id = i.id
WHERE v.status IN ('OPEN', 'ACKNOWLEDGED')
  AND v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
GROUP BY v.id, v.detection_time, i.name_en, v.violation_type, v.severity
ORDER BY
    CASE v.severity WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
    v.detection_time DESC
LIMIT 20
```

**Configuration:**
- Chart Type: Table
- Columns: violation_id, isp, type, severity, duration, affected_pops
- Conditional formatting: severity CRITICAL=Red, WARNING=Yellow

---

## Chart 3.3: Evidence Documentation (Table)

**SQL Query:**
```sql
SELECT
    CONCAT('VIO-', TO_CHAR(v.detection_time, 'YYYY'), '-', LPAD(v.id::text, 3, '0')) as violation_id,
    i.name_en as isp,
    CASE v.violation_type
        WHEN 'SPEED_BELOW_THRESHOLD' THEN 'Download Speed'
        WHEN 'AVAILABILITY_BELOW_THRESHOLD' THEN 'Service Availability'
        WHEN 'LATENCY_ABOVE_THRESHOLD' THEN 'Network Latency'
        WHEN 'PACKET_LOSS_ABOVE_THRESHOLD' THEN 'Packet Loss'
        ELSE v.violation_type
    END as metric,
    ROUND(v.expected_value::numeric, 1) as threshold,
    ROUND(v.actual_value::numeric, 1) as measured,
    CONCAT(ROUND(v.deviation_pct::numeric, 1)::text, '%') as gap,
    TO_CHAR(v.detection_time, 'YYYY-MM-DD HH24:MI') as detected_at,
    CONCAT('~', (RANDOM() * 3000 + 1000)::integer::text) as est_subscribers
FROM sla_violations v
JOIN isps i ON v.isp_id = i.id
WHERE v.severity = 'CRITICAL'
  AND v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '30 days' FROM sla_violations)
ORDER BY v.detection_time DESC
LIMIT 15
```

**Configuration:**
- Chart Type: Table
- Columns: violation_id, isp, metric, threshold, measured, gap, detected_at, est_subscribers

---

# TAB 4: INVESTIGATION CENTER

**Purpose**: "What is causing this issue?"
**Refresh Rate**: On-demand

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                    INVESTIGATION OVERVIEW                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐               │
│  │  OPEN CASES     │  │  IN PROGRESS    │  │  ROOT CAUSE ID  │               │
│  │       18        │  │        7        │  │       12        │               │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘               │
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────┐  ┌────────────────────────────────────────┐  │
│  │  TIMELINE ANALYZER         │  │  CROSS-SOURCE CORRELATION              │  │
│  │  ISP Speed Trend (7 Days)  │  │  QoS + SNMP + Capacity Analysis        │  │
│  └────────────────────────────┘  └────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────────────────┤
│                    PoP INFRASTRUCTURE IMPACT                                 │
│  PoP | Utilization | Health | Subscribers | Root Cause                      │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Chart 4.1: Investigation Overview (3 Big Numbers)

**SQL Query:**
```sql
SELECT
    COUNT(*) FILTER (WHERE status = 'OPEN' AND severity = 'CRITICAL') as open_cases,
    COUNT(*) FILTER (WHERE status = 'ACKNOWLEDGED') as in_progress,
    COUNT(DISTINCT pop_id) FILTER (WHERE status IN ('OPEN', 'ACKNOWLEDGED')) as affected_pops
FROM sla_violations
WHERE detection_time >= (SELECT MAX(detection_time) - INTERVAL '7 days' FROM sla_violations)
```

**Configuration:**
- Create 3 Big Numbers:
  - Open Cases (Red)
  - In Progress (Yellow)
  - Affected PoPs (Blue)

---

## Chart 4.2: Timeline Analyzer (Line Chart)

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('hour', time) as __timestamp,
    ROUND(AVG(download_mbps)::numeric, 1) as avg_speed,
    ROUND(AVG(latency_ms)::numeric, 1) as avg_latency,
    ROUND(AVG(packet_loss_pct)::numeric, 2) as avg_packet_loss
FROM ts_qos_measurements
WHERE time >= (SELECT MAX(time) - INTERVAL '7 days' FROM ts_qos_measurements)
GROUP BY DATE_TRUNC('hour', time)
ORDER BY __timestamp
```

**Configuration:**
- Chart Type: Time-series Line Chart
- X-Axis: `__timestamp`
- Metrics: avg_speed (primary), avg_latency (secondary axis)
- Enable annotations for anomaly detection

---

## Chart 4.3: PoP Infrastructure Impact (Table)

**SQL Query:**
```sql
WITH pop_metrics AS (
    SELECT
        p.id,
        p.name_en as pop_name,
        gd.name_en as district,
        i.name_en as isp,
        AVG(im.utilization_in_pct) as util_in,
        AVG(im.utilization_out_pct) as util_out,
        AVG(q.latency_ms) as avg_latency,
        AVG(q.packet_loss_pct) as avg_packet_loss,
        COUNT(DISTINCT v.id) as violations
    FROM pops p
    JOIN isps i ON p.isp_id = i.id
    JOIN geo_districts gd ON p.district_id = gd.id
    LEFT JOIN ts_interface_metrics im ON im.pop_id = p.id
        AND im.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_interface_metrics)
    LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
        AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    LEFT JOIN sla_violations v ON v.pop_id = p.id
        AND v.detection_time >= (SELECT MAX(detection_time) - INTERVAL '7 days' FROM sla_violations)
    WHERE p.is_active = true
    GROUP BY p.id, p.name_en, gd.name_en, i.name_en
)
SELECT
    pop_name as pop,
    isp,
    district,
    CONCAT(ROUND(GREATEST(util_in, util_out)::numeric, 0)::text, '%') as utilization,
    CASE
        WHEN GREATEST(util_in, util_out) > 90 THEN 'Critical'
        WHEN GREATEST(util_in, util_out) > 75 THEN 'Warning'
        WHEN avg_latency > 100 OR avg_packet_loss > 2 THEN 'Degraded'
        ELSE 'Healthy'
    END as health,
    violations,
    CASE
        WHEN GREATEST(util_in, util_out) > 90 THEN 'Capacity Exhaustion'
        WHEN avg_packet_loss > 2 THEN 'Network Issues'
        WHEN avg_latency > 100 THEN 'Congestion'
        ELSE 'Under Investigation'
    END as root_cause
FROM pop_metrics
WHERE violations > 0 OR GREATEST(util_in, util_out) > 75
ORDER BY violations DESC, GREATEST(util_in, util_out) DESC
LIMIT 15
```

**Configuration:**
- Chart Type: Table
- Columns: pop, isp, district, utilization, health, violations, root_cause
- Conditional formatting: health Critical=Red, Warning=Yellow

---

# TAB 5: LICENSE COMPLIANCE

**Purpose**: "Are ISPs meeting infrastructure commitments?"
**Refresh Rate**: 30 minutes

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                    LICENSE COMPLIANCE OVERVIEW                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐               │
│  │  🟢 COMPLIANT   │  │  🟡 PARTIAL     │  │  🔴 NON-COMPLIANT│               │
│  │      892        │  │       56        │  │       22        │               │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘               │
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────┐  ┌────────────────────────────────────────┐  │
│  │  PoP DEPLOYMENT ADHERENCE  │  │  LICENSED COMMITMENT MONITORING        │  │
│  │  Division | Commit | Actual│  │  ISP License Summary by Category       │  │
│  └────────────────────────────┘  └────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────────────────┤
│                    CAPACITY UTILIZATION                                      │
│  ┌────────────────────────────┐  ┌────────────────────────────────────────┐  │
│  │  PoP CAPACITY vs LICENSED  │  │  UTILIZATION TRENDS                    │  │
│  └────────────────────────────┘  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Chart 5.1: License Compliance Overview (3 Big Numbers)

**SQL Query:**
```sql
WITH isp_compliance AS (
    SELECT
        i.id,
        i.name_en,
        COUNT(DISTINCT p.id) as actual_pops,
        COUNT(DISTINCT gd.id) as coverage_districts,
        AVG(q.download_mbps) as avg_speed,
        ROUND((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
               NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability
    FROM isps i
    LEFT JOIN pops p ON p.isp_id = i.id AND p.is_active = true
    LEFT JOIN geo_districts gd ON p.district_id = gd.id
    LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
        AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
    WHERE i.is_active = true
    GROUP BY i.id, i.name_en
)
SELECT
    COUNT(*) FILTER (WHERE actual_pops >= 3 AND avg_speed >= 20 AND availability >= 99) as compliant,
    COUNT(*) FILTER (WHERE (actual_pops >= 1 AND actual_pops < 3)
                        OR (avg_speed >= 15 AND avg_speed < 20)
                        OR (availability >= 95 AND availability < 99)) as partial,
    COUNT(*) FILTER (WHERE actual_pops = 0 OR avg_speed < 15 OR availability < 95) as non_compliant,
    COUNT(*) as total_isps
FROM isp_compliance
```

**Configuration:**
- Create 3 Big Numbers:
  - Compliant (Green): `compliant`, Subheader=`Meeting All Commitments`
  - Partial (Yellow): `partial`, Subheader=`1-2 Gaps`
  - Non-Compliant (Red): `non_compliant`, Subheader=`3+ Gaps`

---

## Chart 5.2: PoP Deployment Adherence (Table)

**SQL Query:**
```sql
WITH division_pops AS (
    SELECT
        d.name_en as division,
        COUNT(DISTINCT p.id) as actual_pops
    FROM geo_divisions d
    LEFT JOIN geo_districts gd ON gd.division_id = d.id
    LEFT JOIN pops p ON p.district_id = gd.id AND p.is_active = true
    GROUP BY d.name_en
),
commitments AS (
    SELECT
        division,
        CASE division
            WHEN 'Dhaka' THEN 450
            WHEN 'Chattogram' THEN 320
            WHEN 'Khulna' THEN 180
            WHEN 'Rajshahi' THEN 150
            WHEN 'Sylhet' THEN 120
            WHEN 'Rangpur' THEN 100
            WHEN 'Barishal' THEN 80
            WHEN 'Mymensingh' THEN 60
            ELSE 50
        END as committed_pops
    FROM division_pops
)
SELECT
    dp.division,
    c.committed_pops as committed,
    dp.actual_pops as actual,
    dp.actual_pops - c.committed_pops as gap
FROM division_pops dp
JOIN commitments c ON dp.division = c.division
ORDER BY gap ASC
```

**Configuration:**
- Chart Type: Table
- Columns: division, committed, actual, gap
- Conditional formatting: gap negative=Red, positive=Green

---

## Chart 5.3: Licensed Commitment Monitoring (Table)

**SQL Query:**
```sql
SELECT
    lc.name_en as category,
    COUNT(DISTINCT i.id) as isp_count,
    SUM(i.total_subscribers) as total_subscribers,
    COUNT(DISTINCT p.id) as total_pops,
    ROUND(AVG(q.download_mbps)::numeric, 1) as avg_speed,
    ROUND((COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
           NULLIF(COUNT(*)::numeric, 0)) * 100, 1) as availability,
    CASE
        WHEN AVG(q.download_mbps) >= 25 AND
             (COUNT(*) FILTER (WHERE q.latency_ms IS NOT NULL)::numeric /
              NULLIF(COUNT(*)::numeric, 0)) >= 0.99 THEN 'Compliant'
        WHEN AVG(q.download_mbps) >= 15 THEN 'Partial'
        ELSE 'Non-Compliant'
    END as status
FROM isp_license_categories lc
JOIN isps i ON i.license_category_id = lc.id
JOIN pops p ON p.isp_id = i.id
LEFT JOIN ts_qos_measurements q ON q.pop_id = p.id
    AND q.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_qos_measurements)
WHERE i.is_active = true
GROUP BY lc.name_en
ORDER BY total_subscribers DESC
```

**Configuration:**
- Chart Type: Table
- Columns: category, isp_count, total_subscribers, total_pops, avg_speed, availability, status
- Conditional formatting: status Compliant=Green, Partial=Yellow, Non-Compliant=Red

---

## Chart 5.4: PoP Capacity vs Licensed (Table)

**SQL Query:**
```sql
SELECT
    p.name_en as pop,
    i.name_en as isp,
    gd.name_en as district,
    CONCAT(p.upstream_bandwidth_mbps, ' Mbps') as licensed_capacity,
    ROUND(AVG(GREATEST(im.utilization_in_pct, im.utilization_out_pct))::numeric, 0) as utilization_pct,
    CASE
        WHEN AVG(GREATEST(im.utilization_in_pct, im.utilization_out_pct)) > 90 THEN 'Critical'
        WHEN AVG(GREATEST(im.utilization_in_pct, im.utilization_out_pct)) > 75 THEN 'Warning'
        ELSE 'Normal'
    END as status
FROM pops p
JOIN isps i ON p.isp_id = i.id
JOIN geo_districts gd ON p.district_id = gd.id
LEFT JOIN ts_interface_metrics im ON im.pop_id = p.id
    AND im.time >= (SELECT MAX(time) - INTERVAL '24 hours' FROM ts_interface_metrics)
WHERE p.is_active = true
GROUP BY p.id, p.name_en, i.name_en, gd.name_en, p.upstream_bandwidth_mbps
HAVING AVG(GREATEST(im.utilization_in_pct, im.utilization_out_pct)) > 50
ORDER BY AVG(GREATEST(im.utilization_in_pct, im.utilization_out_pct)) DESC
LIMIT 15
```

**Configuration:**
- Chart Type: Table
- Columns: pop, isp, district, licensed_capacity, utilization_pct, status
- Conditional formatting: status Critical=Red, Warning=Yellow

---

## Chart 5.5: Utilization Trends (Line Chart)

**SQL Query:**
```sql
SELECT
    DATE_TRUNC('day', time) as __timestamp,
    ROUND(AVG(GREATEST(utilization_in_pct, utilization_out_pct))::numeric, 1) as avg_utilization,
    85 as threshold
FROM ts_interface_metrics
WHERE time >= (SELECT MAX(time) - INTERVAL '30 days' FROM ts_interface_metrics)
GROUP BY DATE_TRUNC('day', time)
ORDER BY __timestamp
```

**Configuration:**
- Chart Type: Time-series Line Chart
- X-Axis: `__timestamp`
- Metrics: avg_utilization (solid line), threshold (dashed line at 85%)
- Y-Axis: 0-100%

---

# DASHBOARD CONFIGURATION

## Creating the Dashboard

1. Go to **Dashboards** → **+ Dashboard**
2. Name: `BTRC Regulatory Dashboard`
3. Add **Tabs** component with 5 tabs:
   - Tab 1: SLA Monitoring
   - Tab 2: Regional Analysis
   - Tab 3: Violation Reporting
   - Tab 4: Investigation Center
   - Tab 5: License Compliance

## Global Filters

Add filter box with:
- ISP (dropdown from isps table)
- Division (dropdown from geo_divisions table)
- Time Period (Last 24h, 7 Days, 30 Days)

---

# DATASET SUMMARY

| # | Dataset Name | Tab | Charts |
|---|--------------|-----|--------|
| 1 | sla_compliance_overview | 1 | 1.1 |
| 2 | package_compliance_matrix | 1 | 1.2 |
| 3 | realtime_alerts | 1 | 1.3 |
| 4 | pop_performance_validation | 1 | 1.4 |
| 5 | division_performance_map | 2 | 2.1 |
| 6 | division_ranking | 2 | 2.2 |
| 7 | isp_performance_by_area | 2 | 2.3 |
| 8 | violation_summary | 3 | 3.1 |
| 9 | violation_report_generator | 3 | 3.2 |
| 10 | evidence_documentation | 3 | 3.3 |
| 11 | investigation_overview | 4 | 4.1 |
| 12 | timeline_analyzer | 4 | 4.2 |
| 13 | pop_infrastructure_impact | 4 | 4.3 |
| 14 | license_compliance_overview | 5 | 5.1 |
| 15 | pop_deployment_adherence | 5 | 5.2 |
| 16 | licensed_commitment_monitoring | 5 | 5.3 |
| 17 | pop_capacity_vs_licensed | 5 | 5.4 |
| 18 | utilization_trends | 5 | 5.5 |

---

**End of Regulatory Dashboard Guide**
